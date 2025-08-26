#!/bin/bash

docker compose --profile tests-stepci up \
  --abort-on-container-exit \
  --exit-code-from stepci-job \
  stepci-job