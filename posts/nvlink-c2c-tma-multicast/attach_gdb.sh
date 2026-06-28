#!/usr/bin/env bash
# Attach cuda-gdb to the hung BROKEN-barrier multicast kernel and dump where each CTA is stuck.
set -uo pipefail
cd ~/tma_exp
echo "=== launching BROKEN-barrier multicast (peer src) — will hang ==="
./p_broken_gdb 1 1 > /tmp/broken.out 2>&1 &
PID=$!
echo "PID=$PID ; waiting 8s for hang..."
sleep 8
echo "--- program stdout so far (no [result] line == still hung) ---"
cat /tmp/broken.out || true
echo
echo "=== cuda-gdb attach (batch): where are CTA0 (issuer) and CTA1 (consumer) stuck? ==="
timeout 150 sudo /usr/bin/cuda-gdb -p "$PID" -batch \
  -ex "set pagination off" \
  -ex "info cuda kernels" \
  -ex "cuda block 1 thread 0" \
  -ex "where" \
  -ex 'x/i $pc' \
  -ex "cuda block 0 thread 0" \
  -ex "where" \
  -ex 'x/i $pc' \
  -ex "info cuda threads" \
  -ex "detach" 2>&1 | head -130
echo "(cuda-gdb finished)"
echo "=== cleanup ==="
sudo kill -9 "$PID" 2>/dev/null || true
sleep 2
echo "GPU after kill:"
nvidia-smi --query-gpu=index,utilization.gpu,memory.used --format=csv
nvidia-smi --query-compute-apps=pid,used_memory --format=csv 2>&1 | head -3
