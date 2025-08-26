#!/bin/bash

 docker compose --profile security up --abort-on-container-exit --exit-code-from zap-automation zap-automation
