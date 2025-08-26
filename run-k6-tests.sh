#!/bin/bash

docker compose --profile tests-k6 up \
  --abort-on-container-exit \
  --exit-code-from k6 \
  k6