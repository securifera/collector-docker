# BUILD INSTRUCTIONS & README
#   1) docker build --build-arg sshkey=<local public key file> --build-arg apikey=<RECON API KEY> --build-arg gituser=<git username> --build-arg gitpwd=<git token> -t collector:test1 .
#   2) docker run -d collector_test

# Start from base ubuntu 20.04 image
FROM ubuntu:20.04

ENV TZ=America/New_York

# Dockerfile metadata
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezoneLABEL version="1.0"

LABEL desription="Collector Docker Image"

# Setup initial environment
ENV DEBIAN_FRONTEND noninteractive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
WORKDIR /root
ARG gitpwd
ARG gituser

ARG cafile
ADD $cafile /usr/local/share/ca-certificates/

RUN apt update
RUN apt install -y ca-certificates
RUN apt install -y sudo wget curl net-tools git screen
RUN update-ca-certificates

ADD collector_install.sh /tmp/collector_install.sh
RUN sudo /tmp/collector_install.sh -p $gituser:$gitpwd

# Install SSH
RUN apt install -y openssh-server
RUN mkdir -p /var/run/sshd \
  && mkdir /root/.ssh \
  && chmod 700 /root/.ssh \
  && touch /root/.ssh/authorized_keys
ARG sshkey
ADD $sshkey /root/.ssh/authorized_keys

# Setup scan service
ARG apikey
RUN echo $apikey > /root/.collector_api_key
ADD scan-poller /etc/init.d/scan-poller
RUN chmod 755 /etc/init.d/scan-poller

RUN echo "#!/bin/bash" > /root/start.sh
RUN echo "service scan-poller start" >> /root/start.sh
RUN echo "/usr/sbin/sshd -D -o ListenAddress=0.0.0.0" >> /root/start.sh
RUN chmod +x /root/start.sh

# Setup default command and/or parameters.
EXPOSE 22
CMD ["/root/start.sh"]
