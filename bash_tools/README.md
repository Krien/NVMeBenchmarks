# Hardoded tests

This directory contains various tests that are not transitioned to Python and contain device-specific behaviour.
They should be altered to run properly. The results they give are valid, and are part of the data directory.
Currently all scripts are for inteference effects, but only `mix_rate_inteference.sh` gives an accurate result and is used in the paper.
Inteference with "flow" rate limit "reads", and inteference with "randwrite" does not limit write flow properly. They are kept as warnings of what no to do.
