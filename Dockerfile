# BUILD INSTRUCTIONS & README
#   1) docker build --build-arg apikey=<RECON API KEY> -t collector_img .
#   2) docker run --name collector -p 2222:22 -d collector_img

FROM ubuntu:22.04

ENV TZ=America/New_York

# Dockerfile metadata
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezoneLABEL version="1.0"

LABEL desription="Collector Docker Image"

# Setup initial environment
ENV DEBIAN_FRONTEND noninteractive
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
WORKDIR /tmp

RUN apt update
RUN apt install -y sudo git
RUN git clone https://github.com/securifera/reverge_collector.git /tmp/
RUN chmod +x /tmp/install.sh
RUN /tmp/install.sh

# Install SSH
RUN apt install -y openssh-server
RUN mkdir -p /var/run/sshd \
  && mkdir /root/.ssh \
  && chmod 700 /root/.ssh \
  && touch /root/.ssh/authorized_keys
COPY docker_ssh_key.pub /root/.ssh/authorized_keys
RUN chmod 600 /root/.ssh/authorized_keys

# Setup scan service
ARG apikey
RUN echo $apikey > /root/.collector_api_key

RUN cp /tmp/supervisor_sshd.conf /etc/supervisor/conf.d/sshd.conf
RUN cp /tmp/supervisor_collector.conf /etc/supervisor/conf.d/collector.conf
CMD  /usr/bin/supervisord
