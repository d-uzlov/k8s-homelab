#!/usr/bin/env bash
docker events --filter 'event=start' --format '{{.ID}}' | while read CID; do
  PID=$(docker inspect -f '{{.State.Pid}}' "$CID")
  CGPATH=$(cut -d: -f3 /proc/$PID/cgroup)
  if [ -n "$CGPATH" ]; then
    sudo bash -c "echo 1 > /sys/fs/cgroup${CGPATH}/memory.oom.group" || \
      echo "failed to set oom.group for $CID"
  fi
done
