
# CPU burst

TLDR: there is no way to properly configure CPU limits for bursty workloads in k8s.

The only possibility is to run modified `runc` or `containerd`.

# The problem definition

K8s CPU management is NOT at all suited for bursty workloads.
This especially applies to light workloads.
When using CPU limits, container will often be throttled.

Even if container needs `1m` CPU on average, it most likely needs it in big chunks.
For example, it works for `5m`, then sleeps for `5s`.

Imagine you set CPU limit to `10m` to that process.
This will result in **_heavy_** throttling.

CPU management is split in `cpu.cfs_period_us` chunks, which is `100ms` by default.
In the first `100ms` it will get `10 / 1000 * 100ms == 1ms`.
Then it will wait for `99ms`. Then it will get another `1ms`.
This will repeat until the process goes to sleep on its own.
Work that would usually take `5ms`, will take `~500ms` because of CPU limit.

So, to allow the process to burst to `5m`, you need to set limit at least at `50m`.
Realistically, you probably need `100m`, to account for `10m` bursts, or even more.

Remember, this is for workload with `1m` CPU load on average.
If something goes wrong, you will get `100m+` load on average,
and you can't do anything to protect yourself from such workloads.

In k8s `v1.32` there is absolutely no way to properly handle such workloads.

# Existing options

1. Remove CPU limits

This is the recommended approach.
It sucks.
Any container in your cluster can consume all CPU.
If you properly define CPU requests on all containers,
CPU scheduler will make sure that every container get proportionally big chunk
of CPU time, so you may still be fine, except for overall node starvation.

2. Change `cpuCFSQuotaPeriod` kubelet config parameter

This doesn't generally solve the issue.

Sometimes it's recommended to lower from the default `100ms` to `10ms` or even `1ms`.
This way, if the container consumes all of its quota,
it doesn't need to wait `100ms - quota_ms`. It will only need to wait `10ms - quota_ms`, for example.

But `quota_ms` will also get proportionally smaller!

Example 1:
`cpu.limit=50m`, CPU load burst `6ms`, idle CPU:

- `100ms  period`: `run 5ms`, `wait 95ms`, `run 1ms`, total latency `101ms`
- `10ms   period`: `run 0.5ms`, `wait 9.5ms`, repeat 11 times, `run 0.5ms`, total latency `110.5ms`
- `1000ms period`: `run 6ms`, total latency `6ms`

Example 2:
`cpu.limit=50m`, CPU load burst `6ms`, high overall CPU load:

- `100ms  period`: `wait [on average] 50ms` for free CPU time, `run 5ms`, `wait 95ms`, `run 1ms`, total latency `151ms`
- `10ms   period`: `wait [on average] 5ms` for free CPU time, `run 0.5ms`, `wait 9.5ms`, repeat 11 times, `run 0.5ms`, total latency `115.5ms`
- `1000ms period`: `wait [on average] 500ms` for free CPU time, `run 6ms`, total latency `506ms`

Example 3:
`cpu.limit=50m`, CPU load burst `60ms`, idle CPU:

- `100ms  period`: `run 5ms`, `wait 95ms`, repeat 11 times, `run 5ms`, total latency `1105ms`
- `10ms   period`: `run 0.5ms`, `wait 9.5ms`, repeat 119 times, `run 0.5ms`, total latency `1190.5ms`
- `1000ms period`: `run 50ms`, `wait 950ms`, `run 10ms`, total latency `1010ms`

Under low CPU load, increasing `cpuCFSQuotaPeriod` can help lower latencies,
but only for very short workloads.

Under high CPU load, process will likely wait `cpuCFSQuotaPeriod / 2` time for a free CPU slot,
so you will get much higher latencies.

# CPU burst setting

There is a solution. But k8s doesn't support it yet.

In 2021 linux got support for `cpu.cfs_burst_us` option:
- https://lwn.net/Articles/844976/

Example:
`cpu.cfs_burst_us == 50ms`, `cpu.limit=50m`, CPU load burst `6ms`, idle CPU:

- `100ms  period`: `sleep 500ms` (gain `25ms` allowed burst), `run 6ms`, total latency `6ms`
- `10ms   period`: `sleep 500ms` (gain `25ms` allowed burst), `run 6ms`, total latency `6ms`

In 2023 `runc` got support for `--cpu-burst` option:
- https://github.com/opencontainers/runc/pull/3749
- https://github.com/opencontainers/runc/blob/610aa88ab201f289c05c2e262912d0630f46eb35/libcontainer/cgroups/fs/cpu.go#L88C38-L88C55

In 2023 `containerd` got support for `cpu-burst` param:
- https://github.com/containerd/containerd/issues/9078

In 2025 k8s started _considering_ to add some support,
_maybe_, _some time in the future_, _if someone wants to work on this_:
- https://github.com/kubernetes/kubernetes/issues/104516

# Alt solutions

There is a project from a chinese developer that can adjust `cfs_burst_us` externally to k8s:

- https://medium.com/@christian.cadieux/support-for-cfs-burst-in-kubernetes-ac7fae302c99
- https://www.alibabacloud.com/blog/kill-the-annoying-cpu-throttling-and-make-containers-run-faster_598738
- https://github.com/christiancadieux/kubernetes-cfs-burst

Unfortunately, it's only for cgroup v1, so it will not work with most modern k8s deployments.

# Containerd config

References:
- https://github.com/containerd/containerd/blob/main/docs/cri/config.md

Unfortunately, it doesn't seem like there is a way to configure containerd
to add cpu burst config to runc commands.

Also, it doesn't seem like there is a way to make kubelet
add extra params to containerd commands.
