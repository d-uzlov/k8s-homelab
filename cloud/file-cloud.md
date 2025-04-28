
# Nextcloud and alternatives

Nextcloud is de-facto standard.
And everybody hates it.

It's a pain to setup.
The official docker image is a mess, and I almost rewrote it from scratch by using entrypoint replacements.

It's a big pain to run and configure. It's PHP app from year 2000.
It may be packed into the docker container, but it still feels like 2000 when you try to do any configuration.
It uses a lot of RAM, CPU and disk bandwidth to run even the lightest of workloads.

It can run fine on fast hardware though.
It will just use much more resources than needed.
And run slower that you would like to. But Faster than you could expect from 2000-like app on PHP.

There are severe limitations on file sizes.
Yes, you can upload big files via the webUI. It will be very slow, though, to the point where k8s may decide to kill unresponsive app.
You will have issues uploading big files via the desktop app, though. The desktop app is not really maintained, so it does not support chunked uploads.
You will not be able to upload big files via public links. They just decided not to.

The brute-force protection is a joke.
It will ban your IP after a single invalid attempt.
It will not tell you that you are being throttled.
If you try to log in again (it didn't even tell you to way, what else will you do?), you will just get a timeout error.
You will still get the timeout even if your credentials are correct. They just like to throttle IPs.
Curiously, even this timeout error will count towards the count of failed logins.
So, you can fail the login once, than try with correct credentials, it will fail,
you try a few more times, and then you realize your IP has been blocked for like 24 hours.
The only way to mitigate this is to disable the brute force protection. Because giving user control over its config would be too insecure!

Office integration is bad.
There is no proper WOPI support.
There are specialized plugins for OnlyOffice and Collabora. With varying degree of shittiness.

There is no proper OIDC support.
There are several plugins that try to add it. With varying degree of shittiness.

The only issue is: there are no alternatives.
Or, rather, all alternatives are shit.

# Owncloud

It's PHP software from year 2000 running on PHP, just like nextcloud. Only, nextcloud was improving, all these years, and Owncloud has not.

# OCIS / Owncloud Infinite Scale

The official helm chart is like 5 years old, and is in a shit state.

The official documentation is shit. It's fragmented, it's on several different domains, it's incomplete.

The release schedule is shit.

The support is shit.

Apparently, it can't even shutdown properly, without just breaking all the connections.
Infinite scale my ass.

Some users tell that it works better than nextcloud. In my experience it works as shit.
The webUI is shit. The mobile app is shit. The desktop app seems non-existent.

# OpenCloud

Fork of OCIS that decided not to use the database.

Apparently, Europe decided to create a Europe-based cloud solution, and OpenCloud is an attempt at doing think.

This will eat tons of money and achieve nothing.

Let's see how this turns out in a few years.

# Seafile

Works OK.

Needs money to work.
Without money does not support: search, scaling, S3.

Does support OIDC in the community edition.

Does not support postgres.

Seafile is probably the best alternative for nextcloud.
But it's still shit.
