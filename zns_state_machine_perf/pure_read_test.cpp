#include "utils.cpp"

void pure_read_test(uint64_t zone_cnt, uint64_t zone_cap, uint64_t zone_size,
                    char *buf, DeviceTarget *target,
                    t_spdk_nvme_qpair **qpairs) {
  // Half is enough
  zone_cnt = zone_cnt / 2;
  fill_zones_write(0, zone_cnt, zone_cap, zone_size, buf, target, qpairs);

  // status
  bool completion = false;
  int rc = 0;

  // counters
  struct timespec time_now;
  long int time_next;
  uint64_t *read_ops = new uint64_t[zone_cnt * zone_cap];

  char *read_buf = (char *)spdk_zmalloc(
      4096, 4096, NULL, SPDK_ENV_SOCKET_ID_ANY, SPDK_MALLOC_DMA);

  std::mt19937_64 gen64;
  uint64_t *rand_x = new uint64_t[64000];
  uint64_t *rand_y = new uint64_t[64000];
  for (size_t i = 0; i < 64000; i++) {
    rand_x[i] = gen64();
    rand_y[i] = gen64();
  }
  size_t rand_next = 0;

  for (uint64_t zone = 0; zone < zone_cnt; zone++) {
    // Read zone
    for (uint64_t req = 0; req < zone_cap; req++) {
      completion = false;
      rand_next = rand_next == 64000 ? 0 : rand_next + 1;
      uint64_t addr = ((rand_x[rand_next] % zone_cnt) * zone_size) +
                      (rand_y[rand_next] % zone_cap);
      clock_gettime(CLOCK_MONOTONIC, &time_now);
      time_next = time_now.tv_sec * 1000000000ULL + time_now.tv_nsec;
      rc = spdk_nvme_ns_cmd_read(target->ns, qpairs[0], read_buf,
                                 addr, /* LBA start */
                                 1,    /* number of LBAs */
                                 __operation_complete, &completion, 0);
      // Busy wait for the head.
      while (!completion) {
        spdk_nvme_qpair_process_completions((qpairs[0]), 0);
      }
      clock_gettime(CLOCK_MONOTONIC, &time_now);
      read_ops[zone * zone_cap + req] =
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
  for (size_t i = 0; i < zone_cnt * zone_cap; i++) {
    printf("read,%lu\n", read_ops[i]);
  }
  delete[] read_ops;
  spdk_free(read_buf);
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
  pure_read_test(info.zone_cnt, info.zone_cap, info.zone_size, buf, &target,
                 qpairs);
  // spdk_nvme_ctrlr_free_io_qpair(qpairs[0]);
  // spdk_nvme_ctrlr_free_io_qpair(qpairs[1]);
  // spdk_free(buf);
  // free(trid);
  // free(qpairs);
  return 0;
}

