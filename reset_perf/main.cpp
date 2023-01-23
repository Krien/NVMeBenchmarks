#include <iostream>

#include <spdk/env.h>
#include <spdk/likely.h>
#include <spdk/log.h>
#include <spdk/nvme.h>
#include <spdk/nvme_spec.h>
#include <spdk/nvme_zns.h>
#include <spdk/string.h>
#include <spdk/util.h>

#include <pthread.h>

#define ERROR_HANDLING

typedef struct spdk_nvme_transport_id t_spdk_nvme_transport_id;
typedef struct spdk_nvme_ctrlr t_spdk_nvme_ctrlr;
typedef struct spdk_nvme_ctrlr_opts t_spdk_nvme_ctrlr_opts;
typedef struct spdk_nvme_ns t_spdk_nvme_ns;
typedef struct spdk_nvme_qpair t_spdk_nvme_qpair;
typedef struct spdk_nvme_cpl t_spdk_nvme_cpl;
typedef struct spdk_nvme_zns_ns_data t_spdk_nvme_zns_ns_data;
typedef struct spdk_nvme_ns_data t_spdk_nvme_ns_data;
typedef struct spdk_nvme_zns_ctrlr_data t_spdk_nvme_zns_ctrlr_data;
typedef struct spdk_nvme_ctrlr_data t_spdk_nvme_ctrlr_data;

typedef struct {
  t_spdk_nvme_ctrlr *ctrlr; /**< Controller of the selected SSD*/
  t_spdk_nvme_ns *ns;       /**< Selected namespace of the selected SSD*/
  const char *traddr; /**< The transport id of the device that is targeted.*/
  const size_t traddr_len; /**< Length in bytes to check for the target id
                              (long ids).*/
  bool found;              /**< Whether the device is found or not.*/
} DeviceTarget;

bool open_probe_cb(void *cb_ctx, const struct spdk_nvme_transport_id *trid,
                   struct spdk_nvme_ctrlr_opts *opts) {
  DeviceTarget *prober = (DeviceTarget *)cb_ctx;
  if (!prober->traddr) {
    return false;
  }
  // You trying to overflow?
  if (strlen(prober->traddr) < prober->traddr_len) {
    return false;
  }
  if (strlen((const char *)trid->traddr) < prober->traddr_len) {
    return false;
  }
  if (strncmp((const char *)trid->traddr, prober->traddr, prober->traddr_len) !=
      0) {
    return false;
  }
  (void)opts;
  return true;
}

void open_attach_cb(void *cb_ctx, const struct spdk_nvme_transport_id *trid,
                    struct spdk_nvme_ctrlr *ctrlr,
                    const struct spdk_nvme_ctrlr_opts *opts) {
  DeviceTarget *prober = (DeviceTarget *)cb_ctx;
  if (prober == NULL) {
    return;
  }
  prober->ctrlr = ctrlr;
  // take any ZNS namespace, we do not care which.
  for (int nsid = spdk_nvme_ctrlr_get_first_active_ns(ctrlr); nsid != 0;
       nsid = spdk_nvme_ctrlr_get_next_active_ns(ctrlr, nsid)) {
    struct spdk_nvme_ns *ns = spdk_nvme_ctrlr_get_ns(ctrlr, nsid);
    if (ns == NULL) {
      continue;
    }
    if (spdk_nvme_ns_get_csi(ns) != SPDK_NVME_CSI_ZNS) {
      continue;
    }
    prober->ns = ns;
    prober->found = true;
    std::cout << "attaching, traddr=" << trid->traddr << " ns = " << nsid
              << "\n";
    break;
  }
  (void)trid;
  (void)opts;
  return;
}

void __operation_complete(void *arg, const struct spdk_nvme_cpl *cpl) {
  bool *completed = (bool *)arg;
  *completed = true;
#ifdef ERROR_HANDLING
  if (spdk_nvme_cpl_is_error(cpl)) {
    std::cout << "FATAL\n";
  }
#endif
}

void fill_zones_write(uint64_t z_offset, uint64_t z_count, uint64_t zone_cap,
                      uint64_t zone_size, char *buf, DeviceTarget *target,
                      t_spdk_nvme_qpair **qpairs) {
  // status
  bool completion = false;
  int rc = 0;

  // counters
  struct timespec time_now;
  long int time_next;
  uint64_t *zone_open_before = new uint64_t[z_count];
  uint64_t *write_op_before = new uint64_t[z_count * zone_cap];

  // Fill device half
  for (uint64_t zone = z_offset; zone < z_offset + z_count; zone++) {
    // open zone
    completion = false;
    clock_gettime(CLOCK_MONOTONIC, &time_now);
    time_next = time_now.tv_sec * 1000000000ULL + time_now.tv_nsec;
    rc = spdk_nvme_zns_open_zone(target->ns, qpairs[0], zone * zone_size, 0,
                                 __operation_complete, &completion);
    while (!completion) {
      spdk_nvme_qpair_process_completions((qpairs[0]), 0);
    }
    clock_gettime(CLOCK_MONOTONIC, &time_now);
    zone_open_before[zone] =
        time_now.tv_sec * 1000000000ULL + time_now.tv_nsec - time_next;
#ifdef ERROR_HANDLING
    if (rc != 0) {
      std::cout << "Error opening at" << zone << " " << zone_cap << "\n";
    }
#endif
    // printf("Test Opening %lu\n", zone);
    // fill zone
    for (uint64_t req = 0; req < zone_cap; req++) {
      completion = false;
      clock_gettime(CLOCK_MONOTONIC, &time_now);
      time_next = time_now.tv_sec * 1000000000ULL + time_now.tv_nsec;
      rc = spdk_nvme_ns_cmd_write(target->ns, qpairs[0], buf,
                                  zone * zone_size + req, /* LBA start */
                                  1,                      /* number of LBAs */
                                  __operation_complete, &completion, 0);
      // Busy wait for the head.
      while (!completion) {
        spdk_nvme_qpair_process_completions((qpairs[0]), 0);
      }
      clock_gettime(CLOCK_MONOTONIC, &time_now);
      write_op_before[zone * zone_cap + req] =
          time_now.tv_sec * 1000000000ULL + time_now.tv_nsec - time_next;
#ifdef ERROR_HANDLING
      if (rc != 0) {
        std::cout << "Error appending at" << zone << " " << req << " "
                  << zone_cap << "\n";
      }
#endif
    }
  }

  // print/unload the data
  for (size_t i = 0; i < z_count; i++) {
    printf("empty_open,%lu,%lu\n", zone_open_before[i], i);
  }
  delete[] zone_open_before;

  for (size_t i = 0; i < z_count * zone_cap; i++) {
    printf("write,%lu\n", write_op_before[i]);
  }
  delete[] write_op_before;

  return;
}

void finish_test(uint64_t zone_cnt, uint64_t zone_cap, uint64_t zone_size,
                 char *buf, DeviceTarget *target, t_spdk_nvme_qpair **qpairs,
                 uint64_t ratio) {
  uint64_t enough = zone_cnt - 1;
  // status
  bool completion = false;
  int rc = 0;

  // counters
  long int time_next;
  uint64_t *finisn_op = new uint64_t[enough];
  uint64_t *reset_op = new uint64_t[enough];

  // Explicit + write
  for (uint64_t zone = 0; zone < enough; zone++) {
    // open
    completion = false;
    rc = spdk_nvme_zns_open_zone(target->ns, qpairs[0], zone * zone_size, 0,
                                 __operation_complete, &completion);
    while (!completion) {
      spdk_nvme_qpair_process_completions((qpairs[0]), 0);
    }
    // fill zone
    for (uint64_t req = 0; req < ratio; req++) {
      completion = false;
      rc = spdk_nvme_ns_cmd_write(target->ns, qpairs[0], buf,
                                  zone * zone_size + req, /* LBA start */
                                  1,                      /* number of LBAs */
                                  __operation_complete, &completion, 0);
      // Busy wait for the head.
      while (!completion) {
        spdk_nvme_qpair_process_completions((qpairs[0]), 0);
      }
#ifdef ERROR_HANDLING
      if (rc != 0) {
        std::cout << "Error appending at" << zone << " " << req << " "
                  << zone_cap << "\n";
      }
#endif
    }
    sleep(1);
    completion = false;
    time_next = spdk_get_ticks();
    rc = spdk_nvme_zns_finish_zone(target->ns, qpairs[0], zone * zone_size,
                                   false, __operation_complete, &completion);
    // Busy wait for the head.
    while (!completion) {
      spdk_nvme_qpair_process_completions((qpairs[0]), 0);
    }
    finisn_op[zone] =
        (spdk_get_ticks() - time_next) * SPDK_SEC_TO_NSEC / spdk_get_ticks_hz();
#ifdef ERROR_HANDLING
    if (rc != 0) {
      std::cout << "Error appending at" << zone << "\n";
    }
#endif
  }

  // cleanup
  for (uint64_t zone = 0; zone < enough; zone++) {
    completion = false;
    time_next = spdk_get_ticks();
    rc = spdk_nvme_zns_reset_zone(
        target->ns, qpairs[0],
        zone * zone_size, /* starting LBA of the zone to reset */
        false,            /* reset all zones */
        __operation_complete, &completion);
    // Busy wait for the head.
    while (!completion) {
      spdk_nvme_qpair_process_completions((qpairs[0]), 0);
    }
    reset_op[zone] =
        (spdk_get_ticks() - time_next) * SPDK_SEC_TO_NSEC / spdk_get_ticks_hz();
  }

  for (size_t i = 0; i < enough; i++) {
    printf("finish,%lu\n", finisn_op[i]);
  }
  delete[] finisn_op;
  for (size_t i = 0; i < enough; i++) {
    printf("reset_finished_%lu,%lu\n", ratio, reset_op[i]);
  }
  delete[] reset_op;
  return;
}

void partial_zone_reset(uint64_t zone_cnt, uint64_t zone_cap,
                        uint64_t zone_size, char *buf, DeviceTarget *target,
                        t_spdk_nvme_qpair **qpairs, uint64_t ratio) {
  zone_cnt = 20;
  ratio = ratio > zone_cap ? zone_cap : ratio;
  // status
  bool completion = false;
  int rc = 0;

  // counters
  long int time_next;
  uint64_t *reset_op = new uint64_t[zone_cnt];

  for (uint64_t i = 0; i < zone_cnt; i++) {
    completion = false;
    rc = spdk_nvme_zns_open_zone(target->ns, qpairs[0], i * zone_size, 0,
                                 __operation_complete, &completion);
    while (rc != 0 && !completion) {
      spdk_nvme_qpair_process_completions((qpairs[0]), 0);
    }
    for (uint64_t j = 0; j < ratio; j++) {
      completion = false;
      rc = spdk_nvme_ns_cmd_write(target->ns, qpairs[0], buf,
                                  i * zone_size + j, /* LBA start */
                                  1,                 /* number of LBAs */
                                  __operation_complete, &completion, 0);
      // Busy wait for the head.
      while (!completion) {
        spdk_nvme_qpair_process_completions((qpairs[0]), 1);
      }
    }
    completion = false;
    // We need to sleep because there is still some claening sigh
    sleep(1);
    completion = false;
    time_next = spdk_get_ticks();
    rc = spdk_nvme_zns_reset_zone(
        target->ns, qpairs[0],
        i * zone_size, /* starting LBA of the zone to reset */
        false,         /* reset all zones */
        __operation_complete, &completion);
    // Busy wait for the head.
    while (!completion) {
      spdk_nvme_qpair_process_completions((qpairs[0]), 1);
    }
    reset_op[i] =
        (spdk_get_ticks() - time_next) * SPDK_SEC_TO_NSEC / spdk_get_ticks_hz();
#ifdef ERROR_HANDLING
    if (rc != 0) {
      std::cout << "Error resetting at" << i << "\n";
    }
#endif
  }
  for (size_t i = 0; i < zone_cnt; i++) {
    printf("reset_%lu,%lu\n", ratio, reset_op[i]);
  }
  delete[] reset_op;
}

int main(int argc, char **argv) {
  (void)argc;
  (void)argv;

  struct spdk_env_opts opts;
  opts.name = "reset_perf";
  t_spdk_nvme_transport_id *trid =
      (t_spdk_nvme_transport_id *)calloc(1, sizeof(t_spdk_nvme_transport_id));
  spdk_nvme_trid_populate_transport(trid, SPDK_NVME_TRANSPORT_PCIE);
  spdk_env_opts_init(&opts);
  spdk_env_init(&opts);

  const char *traddr = "0000:88:00.0";

  DeviceTarget target = {.ctrlr = NULL,
                         .ns = NULL,
                         .traddr = traddr,
                         .traddr_len = strlen(traddr),
                         .found = false};

  int rc = spdk_nvme_probe(trid, &target, (spdk_nvme_probe_cb)open_probe_cb,
                           (spdk_nvme_attach_cb)open_attach_cb, NULL);
  if (rc != 0) {
    std::cout << "Failed attaching device";
    if (target.ctrlr != NULL) {
      return spdk_nvme_detach(target.ctrlr);
    } else {
      return -1;
    }
  }

  struct spdk_nvme_io_qpair_opts qpopts;
  spdk_nvme_ctrlr_get_default_io_qpair_opts(target.ctrlr, &qpopts,
                                            sizeof(qpopts));
  qpopts.delay_cmd_submit = true;

  t_spdk_nvme_qpair **qpairs =
      (t_spdk_nvme_qpair **)calloc(2, sizeof(t_spdk_nvme_qpair *));
  qpairs[0] =
      spdk_nvme_ctrlr_alloc_io_qpair(target.ctrlr, &qpopts, sizeof(qpopts));
  qpairs[1] =
      spdk_nvme_ctrlr_alloc_io_qpair(target.ctrlr, &qpopts, sizeof(qpopts));

  uint64_t lba_size = (uint64_t)spdk_nvme_ns_get_sector_size(target.ns);
  uint64_t zone_size =
      (uint64_t)spdk_nvme_zns_ns_get_zone_size_sectors(target.ns);
  uint64_t zone_cnt = (uint64_t)spdk_nvme_zns_ns_get_num_zones(target.ns);

  size_t report_bufsize = spdk_nvme_ns_get_max_io_xfer_size(target.ns);
  uint8_t *report_buf = (uint8_t *)calloc(1, report_bufsize);
  {
    bool completion = false;
    rc = spdk_nvme_zns_report_zones(target.ns, qpairs[0], report_buf,
                                    report_bufsize, 0, SPDK_NVME_ZRA_LIST_ALL,
                                    true, __operation_complete, &completion);
    if (rc != 0) {
      free(report_buf);
      return -1;
    }
    // Busy wait for the head.
    while (!completion) {
      spdk_nvme_qpair_process_completions((qpairs[0]), 0);
    }
  }
  // Retrieve write head from zone information.
  uint32_t zd_index = sizeof(struct spdk_nvme_zns_zone_report);
  struct spdk_nvme_zns_zone_desc *desc =
      (struct spdk_nvme_zns_zone_desc *)(report_buf + zd_index);
  uint64_t zone_cap = desc->zcap;
  free(report_buf);

  std::cout << "lba_size: " << lba_size << " zone_size: " << zone_size
            << " zone_cnt: " << zone_cnt << " zone_cap: " << zone_cap << "\n";

  // Clear devic
  bool completion = false;
  spdk_nvme_zns_reset_zone(target.ns, qpairs[0],
                           0,    /* starting LBA of the zone to reset */
                           true, /* reset all zones */
                           __operation_complete, &completion);
  // Busy wait for the head.
  while (!completion) {
    spdk_nvme_qpair_process_completions((qpairs[0]), 0);
  }
  std::cout << "Reset device\n";

  // Generate pattern
  char *buf = (char *)spdk_zmalloc(lba_size, lba_size, NULL,
                                   SPDK_ENV_SOCKET_ID_ANY, SPDK_MALLOC_DMA);
  srand(42);
  static const char alphanum_char[] =
      "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz@!#$%^&*("
      ")";
  for (uint64_t i = 0; i < lba_size; i++) {
    buf[i] = alphanum_char[rand() % (sizeof(alphanum_char))];
  }
  std::cout << "DMA generated\n";

  // pure_reset(zone_cnt, zone_cap, zone_size, buf, &target, qpairs);
  partial_zone_reset(zone_cnt, zone_cap, zone_size, buf, &target, qpairs,
                     zone_cap);
  // partial_zone_reset(zone_cnt, zone_cap, zone_size, buf, &target, qpairs,
  // zone_cap/2);
  partial_zone_reset(zone_cnt, zone_cap, zone_size, buf, &target, qpairs,
                     zone_cap / 4);
  // partial_zone_reset(zone_cnt, zone_cap, zone_size, buf, &target, qpairs,
  // zone_cap/8); partial_zone_reset(zone_cnt, zone_cap, zone_size, buf,
  // &target, qpairs, zone_cap/16);
  partial_zone_reset(zone_cnt, zone_cap, zone_size, buf, &target, qpairs, 1);
  // partial_zone_reset(zone_cnt, zone_cap, zone_size, buf, &target, qpairs, 0);
  // finish_test(zone_cnt, zone_cap, zone_size, buf, &target, qpairs,
  // zone_cap-1); finish_test(zone_cnt, zone_cap, zone_size, buf, &target,
  // qpairs, zone_cap/2); finish_test(zone_cnt, zone_cap, zone_size, buf,
  // &target, qpairs, zone_cap/4); finish_test(zone_cnt, zone_cap, zone_size,
  // buf, &target, qpairs, zone_cap/8); finish_test(zone_cnt, zone_cap,
  // zone_size, buf, &target, qpairs, zone_cap/16); finish_test(zone_cnt,
  // zone_cap, zone_size, buf, &target, qpairs, 1); finish_test(zone_cnt,
  // zone_cap, zone_size, buf, &target, qpairs, 0);
  // close_test(zone_cnt, zone_cap, zone_size, buf, &target, qpairs);
  // spdk_nvme_ctrlr_free_io_qpair(qpairs[0]);
  // spdk_nvme_ctrlr_free_io_qpair(qpairs[1]);
  // spdk_free(buf);
  // free(trid);
  // free(qpairs);
  return 0;
}
