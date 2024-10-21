FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN \
	apt-get update \
	&& apt-get install -y --no-install-recommends \
		ca-certificates \
		curl \
		mono-complete \
		unzip \
		wget

COPY ./install-nitrox.sh /install-nitrox.sh
RUN /install-nitrox.sh

COPY ./run.sh /run.sh

USER nitrox

RUN mkdir -p /home/nitrox/.config/Nitrox/saves/docker-save

CMD [ "/bin/bash" , "/run.sh", "/home/nitrox/.config/Nitrox/saves/docker-save" ]
# CMD [ "sleep" , "infinity" ]
