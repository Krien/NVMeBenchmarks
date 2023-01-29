#include "utils.cpp"

typedef struct {
  pthread_mutex_t mut;
  pthread_cond_t cv;
  uint64_t cur_zone;
  uint64_t queue_zone;
  uint64_t zone_size;
  uint64_t zone_cnt;
  bool done;
  bool ready;
  DeviceTarget *target;
  t_spdk_nvme_qpair **qpairs;
} reset_thread_dat;

void *reset_thread(void *arg) {
  reset_thread_dat *rt = (reset_thread_dat *)arg;
  pthread_mutex_lock(&rt->mut);
  rt->ready = true;
  pthread_mutex_unlock(&rt->mut);
  long int time_next;
  struct timespec time_now;

  uint64_t *reset_ops = new uint64_t[rt->zone_cnt];

  while (true) {
    pthread_mutex_lock(&rt->mut);
    uint64_t curzone = rt->cur_zone;
    uint64_t zones_to_reset = rt->queue_zone - rt->cur_zone;
    while (zones_to_reset == 0 && !rt->done) {
      // pthread_cond_wait(&rt->cv, &rt->mut);
      pthread_mutex_unlock(&rt->mut);
      pthread_mutex_lock(&rt->mut);
      zones_to_reset = rt->queue_zone - rt->cur_zone;
    }
    pthread_mutex_unlock(&rt->mut);

    for (uint64_t tz = 0; tz < zones_to_reset; tz++) {
      bool completion = false;
      clock_gettime(CLOCK_MONOTONIC, &time_now);
      time_next = time_now.tv_sec * 1000000000ULL + time_now.tv_nsec;
      spdk_nvme_zns_reset_zone(
          rt->target->ns, rt->qpairs[1],
          (curzone + tz) *
              rt->zone_size, /* starting LBA of the zone to reset */
          false,             /* reset all zones */
          __operation_complete, &completion);
      // Busy wait for the head.
      while (!completion) {
        spdk_nvme_qpair_process_completions((rt->qpairs[1]), 1);
      }
      clock_gettime(CLOCK_MONOTONIC, &time_now);
      reset_ops[curzone + tz] =
          time_now.tv_sec * 1000000000ULL + time_now.tv_nsec - time_next;
    }
    pthread_mutex_lock(&rt->mut);
    rt->cur_zone = curzone + zones_to_reset;
    if (rt->done) {
      pthread_mutex_unlock(&rt->mut);
      break;
    }
    pthread_mutex_unlock(&rt->mut);
  }
  pthread_mutex_lock(&rt->mut);
  rt->ready = false;
  pthread_mutex_unlock(&rt->mut);
  for (uint64_t i = 0; i < rt->zone_cnt / 2; i++) {
    printf("reset_inteference,%lu,%lu\n", reset_ops[i], i);
  }
  delete[] reset_ops;
  pthread_exit(NULL);
}

void interleaved_reset_write_test(uint64_t zone_cnt, uint64_t zone_cap,
                                  uint64_t zone_size, char *buf,
                                  DeviceTarget *target,
                                  t_spdk_nvme_qpair **qpairs) {
  uint64_t zones_to_reset = zone_cnt / 2;
  fill_zones_write(0, zones_to_reset, zone_cap, zone_size, buf, target, qpairs);

  // status
  bool completion = false;
  int rc = 0;

  // counters
  struct timespec time_now;
  long int time_next;
  uint64_t *zones_open = new uint64_t[zone_cnt - zones_to_reset];
  uint64_t *write_ops = new uint64_t[(zone_cnt - zones_to_reset) * zone_cap];

  pthread_t thread1;
  reset_thread_dat dat;
  pthread_mutex_init(&dat.mut, NULL);
  pthread_cond_init(&dat.cv, NULL);
  dat.cur_zone = 0;
  dat.queue_zone = 0;
  dat.zone_size = zone_size;
  dat.zone_cnt = zone_cnt;
  dat.ready = false;
  dat.done = false;
  dat.target = target;
  dat.qpairs = qpairs;
  pthread_create(&thread1, NULL, &reset_thread, (void *)&dat);

  pthread_mutex_lock(&dat.mut);
  while (!dat.ready) {
    pthread_mutex_unlock(&dat.mut);
    sleep(1);
    pthread_mutex_lock(&dat.mut);
  }
  pthread_mutex_unlock(&dat.mut);

  int reset_tresh = 1;
  uint64_t till_zone = 0;
  uint64_t till_lba = 0;

  bool done = false;
  for (uint64_t zone = zones_to_reset; zone < zone_cnt; zone++) {
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
    zones_open[zone - zones_to_reset] =
        time_now.tv_sec * 1000000000ULL + time_now.tv_nsec - time_next;
#ifdef ERROR_HANDLING
    if (rc != 0) {
      std::cout << "Error opening at" << zone << " " << zone_cap << "\n";
    }
#endif

    // Fill zone
    for (uint64_t req = 0; req < zone_cap; req++) {
      completion = false;
      clock_gettime(CLOCK_MONOTONIC, &time_now);
      time_next = time_now.tv_sec * 1000000000ULL + time_now.tv_nsec;
      rc = spdk_nvme_ns_cmd_write(target->ns, qpairs[0], buf,
                                  zone * zone_size + req, /* LBA start */
                                  1,                      /* number of LBAs */
                                  __operation_complete, &completion, 0);
      if (reset_tresh-- == 0) {
        pthread_mutex_lock(&dat.mut);
        if (dat.done) {
          if (!dat.ready) {
            done = true;
            pthread_mutex_unlock(&dat.mut);
            break;
          } else {
            pthread_mutex_unlock(&dat.mut);
            reset_tresh = 395;
          }
        } else {
          dat.queue_zone++;
          if (dat.queue_zone == zones_to_reset) {
            dat.done = true;
          }
          // pthread_cond_signal(&dat.cv);
          pthread_mutex_unlock(&dat.mut);
          reset_tresh = 395;
        }
      }

      // Busy wait for the head.
      while (!completion) {
        spdk_nvme_qpair_process_completions((qpairs[0]), 0);
      }
      clock_gettime(CLOCK_MONOTONIC, &time_now);
      write_ops[(zone - zones_to_reset) * zone_cap + req] =
          time_now.tv_sec * 1000000000ULL + time_now.tv_nsec - time_next;
#ifdef ERROR_HANDLING
      if (rc != 0) {
        std::cout << "Error appending at" << zone << " " << req << " "
                  << zone_cap << "\n";
      }
#endif
      till_lba++;
    }
    if (done) {
      break;
    }
    till_zone++;
  }
  pthread_join(thread1, NULL);

  // print/unload the data
  for (size_t i = 0; i < zone_cnt - zones_to_reset && i < till_zone; i++) {
    printf("open_inteference,%lu,%lu\n", zones_open[i], i);
  }
  delete[] zones_open;

  for (size_t i = 0; i < (zone_cnt - zones_to_reset) * zone_cap && i < till_lba;
       i++) {
    printf("write_inteference,%lu\n", write_ops[i]);
  }
  delete[] write_ops;
  return;
}

int main(int argc, char **argv) {
  int opt;
  char traddr[256];
  bool set = false;
  while ((opt = getopt(argc, argv, "t:")) != -1) {
    switch (opt) {
    case 't':
      snprintf(traddr, sizeof(traddr) - 1, "%s", optarg);
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

  // run
  interleaved_reset_write_test(info.zone_cnt, info.zone_cap, info.zone_size,
                               buf, &target, qpairs);
  // spdk_nvme_ctrlr_free_io_qpair(qpairs[0]);
  // spdk_nvme_ctrlr_free_io_qpair(qpairs[1]);
  // spdk_free(buf);
  // free(trid);
  // free(qpairs);
  return 0;
}
