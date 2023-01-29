#include "utils.cpp"

void implicit_versus_explicit(uint64_t zone_cnt, uint64_t zone_cap,
                              uint64_t zone_size, char *buf,
                              DeviceTarget *target,
                              t_spdk_nvme_qpair **qpairs) {

  uint64_t enough = zone_cnt / 2;

  // status
  bool completion = false;
  int rc = 0;

  // counters
  long int time_next;
  uint64_t *zone_open = new uint64_t[enough];
  uint64_t *write_op_implicit = new uint64_t[enough * zone_cap];
  uint64_t *write_op_explicit = new uint64_t[enough * zone_cap];
  uint64_t *append_op_implicit = new uint64_t[enough * zone_cap];
  uint64_t *append_op_explicit = new uint64_t[enough * zone_cap];

  // Implicit + write
  for (uint64_t zone = 0; zone < enough; zone++) {
    // open zone
    completion = false;
    time_next = spdk_get_ticks();
    rc = spdk_nvme_zns_open_zone(target->ns, qpairs[0], zone * zone_size, 0,
                                 __operation_complete, &completion);
    while (!completion) {
      spdk_nvme_qpair_process_completions((qpairs[0]), 0);
    }
    zone_open[zone] =
        (spdk_get_ticks() - time_next) * SPDK_SEC_TO_NSEC / spdk_get_ticks_hz();
#ifdef ERROR_HANDLING
    if (rc != 0) {
      std::cout << "Error opening at" << zone << " " << zone_cap << "\n";
    }
#endif

    // fill zone
    for (uint64_t req = 0; req < zone_cap; req++) {
      completion = false;
      time_next = spdk_get_ticks();
      rc = spdk_nvme_ns_cmd_write(target->ns, qpairs[0], buf,
                                  zone * zone_size + req, /* LBA start */
                                  1,                      /* number of LBAs */
                                  __operation_complete, &completion, 0);
      // Busy wait for the head.
      while (!completion) {
        spdk_nvme_qpair_process_completions((qpairs[0]), 0);
      }
      write_op_explicit[zone * zone_cap + req] =
          (spdk_get_ticks() - time_next) * SPDK_SEC_TO_NSEC /
          spdk_get_ticks_hz();
#ifdef ERROR_HANDLING
      if (rc != 0) {
        std::cout << "Error appending at" << zone << " " << req << " "
                  << zone_cap << "\n";
      }
#endif
    }
  }

  // cleanup
  for (uint64_t zone = 0; zone < enough; zone++) {
    completion = false;
    rc = spdk_nvme_zns_reset_zone(
        target->ns, qpairs[0],
        zone * zone_size, /* starting LBA of the zone to reset */
        false,            /* reset all zones */
        __operation_complete, &completion);
    // Busy wait for the head.
    while (!completion) {
      spdk_nvme_qpair_process_completions((qpairs[0]), 0);
    }
  }

  // Explicit + write
  for (uint64_t zone = 0; zone < enough; zone++) {
    // fill zone
    for (uint64_t req = 0; req < zone_cap; req++) {
      completion = false;
      time_next = spdk_get_ticks();
      rc = spdk_nvme_ns_cmd_write(target->ns, qpairs[0], buf,
                                  zone * zone_size + req, /* LBA start */
                                  1,                      /* number of LBAs */
                                  __operation_complete, &completion, 0);
      // Busy wait for the head.
      while (!completion) {
        spdk_nvme_qpair_process_completions((qpairs[0]), 0);
      }
      write_op_implicit[zone * zone_cap + req] =
          (spdk_get_ticks() - time_next) * SPDK_SEC_TO_NSEC /
          spdk_get_ticks_hz();
#ifdef ERROR_HANDLING
      if (rc != 0) {
        std::cout << "Error appending at" << zone << " " << req << " "
                  << zone_cap << "\n";
      }
#endif
    }
  }

  // cleanup
  for (uint64_t zone = 0; zone < enough; zone++) {
    completion = false;
    rc = spdk_nvme_zns_reset_zone(
        target->ns, qpairs[0],
        zone * zone_size, /* starting LBA of the zone to reset */
        false,            /* reset all zones */
        __operation_complete, &completion);
    // Busy wait for the head.
    while (!completion) {
      spdk_nvme_qpair_process_completions((qpairs[0]), 0);
    }
  }

  // Implicit + append
  for (uint64_t zone = 0; zone < enough; zone++) {
    // open zone
    completion = false;
    time_next = spdk_get_ticks();
    rc = spdk_nvme_zns_open_zone(target->ns, qpairs[0], zone * zone_size, 0,
                                 __operation_complete, &completion);
    while (!completion) {
      spdk_nvme_qpair_process_completions((qpairs[0]), 0);
    }
    zone_open[zone] =
        (spdk_get_ticks() - time_next) * SPDK_SEC_TO_NSEC / spdk_get_ticks_hz();
#ifdef ERROR_HANDLING
    if (rc != 0) {
      std::cout << "Error opening at" << zone << " " << zone_cap << "\n";
    }
#endif

    // fill zone
    for (uint64_t req = 0; req < zone_cap; req++) {
      completion = false;
      time_next = spdk_get_ticks();
      rc = spdk_nvme_zns_zone_append(target->ns, qpairs[0], buf,
                                     zone * zone_size, /* LBA start */
                                     1,                /* number of LBAs */
                                     __operation_complete, &completion, 0);
      // Busy wait for the head.
      while (!completion) {
        spdk_nvme_qpair_process_completions((qpairs[0]), 0);
      }
      append_op_explicit[zone * zone_cap + req] =
          (spdk_get_ticks() - time_next) * SPDK_SEC_TO_NSEC /
          spdk_get_ticks_hz();
#ifdef ERROR_HANDLING
      if (rc != 0) {
        std::cout << "Error appending at" << zone << " " << req << " "
                  << zone_cap << "\n";
      }
#endif
    }
  }

  // cleanup
  for (uint64_t zone = 0; zone < enough; zone++) {
    completion = false;
    rc = spdk_nvme_zns_reset_zone(
        target->ns, qpairs[0],
        zone * zone_size, /* starting LBA of the zone to reset */
        false,            /* reset all zones */
        __operation_complete, &completion);
    // Busy wait for the head.
    while (!completion) {
      spdk_nvme_qpair_process_completions((qpairs[0]), 0);
    }
  }

  // Explicit + append
  for (uint64_t zone = 0; zone < enough; zone++) {
    // fill zone
    for (uint64_t req = 0; req < zone_cap; req++) {
      completion = false;
      time_next = spdk_get_ticks();
      rc = spdk_nvme_zns_zone_append(target->ns, qpairs[0], buf,
                                     zone * zone_size, /* LBA start */
                                     1,                /* number of LBAs */
                                     __operation_complete, &completion, 0);
      // Busy wait for the head.
      while (!completion) {
        spdk_nvme_qpair_process_completions((qpairs[0]), 0);
      }
      append_op_implicit[zone * zone_cap + req] =
          (spdk_get_ticks() - time_next) * SPDK_SEC_TO_NSEC /
          spdk_get_ticks_hz();
#ifdef ERROR_HANDLING
      if (rc != 0) {
        std::cout << "Error appending at" << zone << " " << req << " "
                  << zone_cap << "\n";
      }
#endif
    }
  }

  delete[] zone_open;
  for (size_t i = 0; i < enough * zone_cap; i++) {
    printf("write_explicit,%lu\n", write_op_explicit[i]);
  }
  delete[] write_op_explicit;
  for (size_t i = 0; i < enough * zone_cap; i++) {
    if (i % zone_cap == 0) {
      printf("write_implicit_opened,%lu\n", write_op_implicit[i]);
    } else {
      printf("write_implicit,%lu\n", write_op_implicit[i]);
    }
  }
  delete[] write_op_implicit;
  for (size_t i = 0; i < enough * zone_cap; i++) {
    printf("append_explicit,%lu\n", append_op_explicit[i]);
  }
  delete[] append_op_explicit;
  for (size_t i = 0; i < enough * zone_cap; i++) {
    if (i % zone_cap == 0) {
      printf("append_implicit_opened,%lu\n", append_op_implicit[i]);
    } else {
      printf("append_implicit,%lu\n", append_op_implicit[i]);
    }
  }
  delete[] append_op_implicit;
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
  implicit_versus_explicit(info.zone_cnt, info.zone_cap, info.zone_size, buf,
                           &target, qpairs);
  // spdk_nvme_ctrlr_free_io_qpair(qpairs[0]);
  // spdk_nvme_ctrlr_free_io_qpair(qpairs[1]);
  // spdk_free(buf);
  // free(trid);
  // free(qpairs);
  return 0;
}

