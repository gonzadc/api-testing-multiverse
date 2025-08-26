#!/bin/bash

docker run --rm \
  -v "$PWD/openapi:/openapi:ro" \
  apiaryio/dredd:latest \
  dredd /openapi/swapi.yaml http://localhost:4010 --color