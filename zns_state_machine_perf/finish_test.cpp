#include "utils.cpp"

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
    printf("finish_%lu,%lu\n", ratio, finisn_op[i]);
  }
  delete[] finisn_op;
  for (size_t i = 0; i < enough; i++) {
    printf("reset_finished_%lu,%lu\n", ratio, reset_op[i]);
  }
  delete[] reset_op;
  return;
}

int main(int argc, char **argv) {
  int opt;
  char traddr[256];
  bool set = false;
  while ((opt = getopt(argc, argv, "t:")) != -1) {
    switch (opt) {
    case 't':
      snprintf(traddr, sizeof(traddr)-1, "%s", optarg);
      set = true;
      break;
    }
  }
  if (!set) {
      printf("Please use a traddr with: -t <traddr>\n");
      return -1;
  }

  int rc = 0;
  t_spdk_nvme_transport_id *trid;
  DeviceTarget target;
  ZoneInfo info;
  t_spdk_nvme_qpair **qpairs;

  // Open device
  init_spdk(&trid, &target, traddr);
  if ((rc = spdk_nvme_probe(trid, &target, (spdk_nvme_probe_cb)open_probe_cb,
                            (spdk_nvme_attach_cb)open_attach_cb, NULL)) != 0) {
    std::cout << "Failed attaching device";
    if (target.ctrlr != NULL) {
      spdk_nvme_detach(target.ctrlr);
    }
    return rc;
  }
  // Qpairs
  qpairs = setup_qpairs(target.ctrlr, 2);
  // Get info
  if ((rc = zns_get_info(target.ns, qpairs[0], &info)) != 0) {
    return rc;
  }
  // DMA
  char *buf = generate_dma(info.lba_size);

  // clear
  clear_device(target.ns, qpairs[0]);

  // run test
  finish_test(info.zone_cnt, info.zone_cap, info.zone_size, buf, &target,
              qpairs, info.zone_cap - 1);
  finish_test(info.zone_cnt, info.zone_cap, info.zone_size, buf, &target,
              qpairs, info.zone_cap / 2);
  finish_test(info.zone_cnt, info.zone_cap, info.zone_size, buf, &target,
              qpairs, info.zone_cap / 4);
  finish_test(info.zone_cnt, info.zone_cap, info.zone_size, buf, &target,
              qpairs, info.zone_cap / 8);
  finish_test(info.zone_cnt, info.zone_cap, info.zone_size, buf, &target,
              qpairs, info.zone_cap / 16);
  finish_test(info.zone_cnt, info.zone_cap, info.zone_size, buf, &target,
              qpairs, 1);
  finish_test(info.zone_cnt, info.zone_cap, info.zone_size, buf, &target,
              qpairs, 0);
  // spdk_nvme_ctrlr_free_io_qpair(qpairs[0]);
  // spdk_nvme_ctrlr_free_io_qpair(qpairs[1]);
  // spdk_free(buf);
  // free(trid);
  // free(qpairs);
  return 0;
}

