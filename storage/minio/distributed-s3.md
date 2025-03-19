
# Distributed S3

This is just a reference to a discussion on reddit.

THe general consensus is that the best solution for distributed S3 storage is CEPH.
However, it has significant drawbacks:
- Heavy on resources
- Slow (apparently, it will only run well on 4+ nodes)
- S3 is Slow (apparently, S3 write speed is much worse than other CEPH APIs)
- Hard to maintain (you need 24/7 team to support it)

There are upsides:
- It is reliable and self-healing
- It scales incredibly well

Other solutions either unreliable, or do not scale as well, or both.

## Comparison by rawh@reddit

Link: https://www.reddit.com/r/selfhosted/comments/1hqdzxd/comment/m4pdub3/

i've been through the following fs'es:

- gluster
- minio
- garagefs
- seaweedfs
- ceph

Setting aside gluster since it doesn't natively expose an S3 API.

As others have mentioned, minio doesn't scale well if you're not "in the cloud" - to add drives requires a lot more operational work than simply "plug in and add to pool", which is what turned me off, since I'm constantly bolting on more prosumer storage (one day, 45drives, one day).

Garagefs has a super simple binary/setup/config and will "work well enough" but i ran into some issues at scale. the distributed metadata design meant that a fs spread across disparate drives (bad design, i know) would cause excessive churn across the cluster for relatively small operations. additionally, the topology configuration model was a bit clunky IMO.

Seaweedfs was an improvement on garage and did scale better in my experience, due in part to the microservice design which enabled me to more granularly schedule components on more "compatible" hardware. It was decently performant at scale, however I ran into some scaling/perfomance issues over time and ultimately some data corruption due to power losses that turned me off.

I've sinced moved to ceph with the rook orchestrator, and it's exactly what I was looking for. the initial set up is admittedly more complex than the more "plug and play" approach of others, but you benefit in the long run. ngl, i have faced some issues with parity degradation (due to power outages/crashes), and had to do some manually tweaking of the OSD weights and PG placements, but admittedly that is due in part to my impatience in overloading the cluster too soon, and it does an amazing job of "self healing" if you just leave it alone and let it do its thing.

tl;dr if you can, go with ceph. you'll need to RTFM a bit, but it's worth it.
