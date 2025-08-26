#!/bin/bash

docker compose --profile tests-karate up karate-job --abort-on-container-exit --exit-code-from karate-job