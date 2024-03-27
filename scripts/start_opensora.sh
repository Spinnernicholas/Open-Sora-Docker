#!/usr/bin/env bash
export PYTHONUNBUFFERED=1
echo "Starting Open Sora Inference Demo"
cd /workspace/Open-Sora
nohup python scripts/demo.py -f > /workspace/logs/opensora.log 2>&1 &
echo "Open Sora Inference Demo started"
echo "Log file: /workspace/logs/opensora.log"