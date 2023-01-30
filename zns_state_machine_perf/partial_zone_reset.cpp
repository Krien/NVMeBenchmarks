#include "utils.cpp"

void partial_zone_reset(uint64_t zone_cnt, uint64_t zone_cap,
                        uint64_t zone_size, char *buf, DeviceTarget *target,
                        t_spdk_nvme_qpair **qpairs, uint64_t ratio) {
  zone_cnt = zone_cnt - 1;
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
    while (!completion) {
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
    printf("next zone");
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
  partial_zone_reset(info.zone_cnt, info.zone_cap, info.zone_size, buf, &target,
                     qpairs, info.zone_cap);
  partial_zone_reset(info.zone_cnt, info.zone_cap, info.zone_size, buf, &target,
                     qpairs, info.zone_cap / 2);
  partial_zone_reset(info.zone_cnt, info.zone_cap, info.zone_size, buf, &target,
                     qpairs, info.zone_cap / 4);
  partial_zone_reset(info.zone_cnt, info.zone_cap, info.zone_size, buf, &target,
                     qpairs, info.zone_cap / 8);
  partial_zone_reset(info.zone_cnt, info.zone_cap, info.zone_size, buf, &target,
                     qpairs, info.zone_cap / 16);
  partial_zone_reset(info.zone_cnt, info.zone_cap, info.zone_size, buf, &target,
                     qpairs, 1);
  partial_zone_reset(info.zone_cnt, info.zone_cap, info.zone_size, buf, &target,
                     qpairs, 0);
  // spdk_nvme_ctrlr_free_io_qpair(qpairs[0]);
  // spdk_nvme_ctrlr_free_io_qpair(qpairs[1]);
  // spdk_free(buf);
  // free(trid);
  // free(qpairs);
  return 0;
}

