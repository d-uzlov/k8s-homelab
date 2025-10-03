
# gateway api implementation comparison

References:
- https://github.com/howardjohn/gateway-api-bench
- https://www.reddit.com/r/kubernetes/comments/1l7dna0/evaluating_realworld_performance_of_gateway_api/

tldr:
- istio, kgateway — good
- cilium, envoy, kong, traefik, nginx — bad

APISIX, haproxy, contour weren't tested (yet).

Out of 2 verified good gateways istio has relatively good and flexible configuration,
while kgateway doesn't even support external auth.
