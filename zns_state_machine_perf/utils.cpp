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
#include <random>

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
  size_t traddr_len;  /**< Length in bytes to check for the target id
                                (long ids).*/
  bool found;         /**< Whether the device is found or not.*/
} DeviceTarget;

typedef struct {
  uint64_t lba_size;
  uint64_t zone_size;
  uint64_t zone_cnt;
  uint64_t zone_cap;
} ZoneInfo;

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
#ifdef ERROR_HANDLING
    std::cout << "attaching, traddr=" << trid->traddr << " ns = " << nsid
              << "\n";
#endif
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

void fill_zones_append(uint64_t z_offset, uint64_t z_count, uint64_t zone_cap,
                       uint64_t zone_size, char *buf, DeviceTarget *target,
                       t_spdk_nvme_qpair **qpairs, bool output = true) {
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

    // fill zone
    for (uint64_t req = 0; req < zone_cap; req++) {
      completion = false;
      clock_gettime(CLOCK_MONOTONIC, &time_now);
      time_next = time_now.tv_sec * 1000000000ULL + time_now.tv_nsec;
      rc = spdk_nvme_zns_zone_append(target->ns, qpairs[0], buf,
                                     zone * zone_size, /* LBA start */
                                     1,                /* number of LBAs */
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
  for (size_t i = 0; output && i < z_count; i++) {
    printf("empty_open,%lu,%lu\n", zone_open_before[i], i);
  }
  delete[] zone_open_before;

  for (size_t i = 0; output && i < z_count * zone_cap; i++) {
    printf("append,%lu\n", write_op_before[i]);
  }
  delete[] write_op_before;

  return;
}

void fill_zones_write(uint64_t z_offset, uint64_t z_count, uint64_t zone_cap,
                      uint64_t zone_size, char *buf, DeviceTarget *target,
                      t_spdk_nvme_qpair **qpairs, bool output = true) {
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
  for (size_t i = 0; output && i < z_count; i++) {
    printf("empty_open,%lu,%lu\n", zone_open_before[i], i);
  }
  delete[] zone_open_before;

  for (size_t i = 0; output && i < z_count * zone_cap; i++) {
    printf("write,%lu\n", write_op_before[i]);
  }
  delete[] write_op_before;

  return;
}

t_spdk_nvme_qpair **setup_qpairs(t_spdk_nvme_ctrlr *ctrlr, size_t cnt) {
  struct spdk_nvme_io_qpair_opts qpopts;
  spdk_nvme_ctrlr_get_default_io_qpair_opts(ctrlr, &qpopts, sizeof(qpopts));
  qpopts.delay_cmd_submit = true;

  t_spdk_nvme_qpair **qpairs =
      (t_spdk_nvme_qpair **)calloc(cnt, sizeof(t_spdk_nvme_qpair *));
  for (size_t i = 0; i < cnt; i++) {
    qpairs[i] = spdk_nvme_ctrlr_alloc_io_qpair(ctrlr, &qpopts, sizeof(qpopts));
  }
  return qpairs;
}

void init_spdk(t_spdk_nvme_transport_id **trid, DeviceTarget *target,
               const char *traddr) {
  struct spdk_env_opts opts;
  opts.name = "reset_perf";
  *trid =
      (t_spdk_nvme_transport_id *)calloc(1, sizeof(t_spdk_nvme_transport_id));
  spdk_nvme_trid_populate_transport(*trid, SPDK_NVME_TRANSPORT_PCIE);
  spdk_env_opts_init(&opts);
  spdk_env_init(&opts);

  target->ctrlr = NULL;
  target->ns = NULL;
  target->traddr = traddr;
  target->traddr_len = strlen(traddr);
  target->found = false;
}

int zns_get_info(t_spdk_nvme_ns *ns, t_spdk_nvme_qpair *qpair, ZoneInfo *info) {
  info->lba_size = (uint64_t)spdk_nvme_ns_get_sector_size(ns);
  info->zone_size = (uint64_t)spdk_nvme_zns_ns_get_zone_size_sectors(ns);
  info->zone_cnt = (uint64_t)spdk_nvme_zns_ns_get_num_zones(ns);

  size_t report_bufsize = spdk_nvme_ns_get_max_io_xfer_size(ns);
  uint8_t *report_buf = (uint8_t *)calloc(1, report_bufsize);
  {
    bool completion = false;
    int rc = spdk_nvme_zns_report_zones(ns, qpair, report_buf, report_bufsize,
                                        0, SPDK_NVME_ZRA_LIST_ALL, true,
                                        __operation_complete, &completion);
    if (rc != 0) {
      free(report_buf);
      return -1;
    }
    // Busy wait for the head.
    while (!completion) {
      spdk_nvme_qpair_process_completions(qpair, 0);
    }
  }
  // Retrieve write head from zone information.
  uint32_t zd_index = sizeof(struct spdk_nvme_zns_zone_report);
  struct spdk_nvme_zns_zone_desc *desc =
      (struct spdk_nvme_zns_zone_desc *)(report_buf + zd_index);
  info->zone_cap = desc->zcap;
  free(report_buf);

  std::cout << "lba_size: " << info->lba_size
            << " zone_size: " << info->zone_size
            << " zone_cnt: " << info->zone_cnt
            << " zone_cap: " << info->zone_cap << "\n";
  return 0;
}

void clear_device(t_spdk_nvme_ns *ns, t_spdk_nvme_qpair *qpair) {
  // Clear device
  bool completion = false;
  spdk_nvme_zns_reset_zone(ns, qpair, 0, /* starting LBA of the zone to reset */
                           true,         /* reset all zones */
                           __operation_complete, &completion);
  // Busy wait for the head.
  while (!completion) {
    spdk_nvme_qpair_process_completions(qpair, 0);
  }
  std::cout << "Reset device\n";
}

char *generate_dma(uint64_t lba_size) {
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
  return buf;
}
