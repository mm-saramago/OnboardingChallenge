#!/bin/bash
for i in {1..6}; do
  /usr/local/bin/system-metrics.sh
  sleep 10
done
