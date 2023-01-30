#include "utils.cpp"

void pure_reset(uint64_t zone_cnt, uint64_t zone_cap, uint64_t zone_size,
                char *buf, DeviceTarget *target, t_spdk_nvme_qpair **qpairs) {
  zone_cnt = 20;
  fill_zones_write(0, zone_cnt, zone_cap, zone_size, buf, target, qpairs);

  // status
  bool completion = false;
  int rc = 0;

  // counters
  uint64_t *reset_ops = new uint64_t[zone_cnt];
  long int time_next;

  // Time resets
  for (uint64_t zone = 0; zone < zone_cnt; zone++) {
    completion = false;
    time_next = spdk_get_ticks();
    rc = spdk_nvme_zns_reset_zone(
        target->ns, qpairs[0],
        zone * zone_size, /* starting LBA of the zone to reset */
        false,            /* reset all zones */
        __operation_complete, &completion);
    // Busy wait for the head.
    while (!completion) {
      spdk_nvme_qpair_process_completions((qpairs[0]), 1);
    }
    reset_ops[zone] =
        (spdk_get_ticks() - time_next) * SPDK_SEC_TO_NSEC / spdk_get_ticks_hz();

#ifdef ERROR_HANDLING
    if (rc != 0) {
      std::cout << "Error appending at" << zone << "\n";
    }
#endif
  }
  // print/unload
  for (uint64_t i = 0; i < zone_cnt; i++) {
    printf("reset,%lu,%lu\n", reset_ops[i], i);
  }
  delete[] reset_ops;
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

  // Run test
  pure_reset(info.zone_cnt, info.zone_cap, info.zone_size, buf, &target,
             qpairs);
  // spdk_nvme_ctrlr_free_io_qpair(qpairs[0]);
  // spdk_nvme_ctrlr_free_io_qpair(qpairs[1]);
  // spdk_free(buf);
  // free(trid);
  // free(qpairs);
  return 0;
}

