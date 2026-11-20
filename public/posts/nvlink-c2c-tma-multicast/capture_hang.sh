#!/usr/bin/env bash
# Build the REAL-hang variant (BROKEN protocol + infinite wait) and capture the
# stuck consumer CTA with cuda-gdb. Shows the folklore "stuck" site is literally
# mbarrier.try_wait in the consumer CTA -- a protocol bug, not NVLink.
#
# Needs: Hopper GPU, cuda-gdb (apt package: nvidia-cuda-gdb), sudo.
set -uo pipefail
cd "$(dirname "$0")"

nvcc -arch=sm_90a -O3 -lcuda -lineinfo -DBROKEN_BARRIER -DINFINITE_WAIT \
     tma_multicast_barrier.cu -o demo_hang

echo "launching real-hang version (BROKEN + infinite wait) ..."
./demo_hang > /tmp/demo_hang.out 2>&1 &
PID=$!
sleep 7
echo "--- program output (no '=>' line == still hung) ---"
cat /tmp/demo_hang.out || true

echo "--- cuda-gdb: where is each CTA stuck? ---"
timeout 120 sudo cuda-gdb -p "$PID" -batch \
  -ex "set pagination off" \
  -ex "info cuda threads" \
  -ex "cuda block 1 thread 0" -ex "where" -ex 'x/i $pc' \
  -ex "detach" 2>&1 | sed -n '1,45p'

sudo kill -9 "$PID" 2>/dev/null || true
sleep 2
echo "GPU mem after kill: $(nvidia-smi --query-gpu=memory.used --format=csv,noheader)"
