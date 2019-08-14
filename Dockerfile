FROM erlang:21 AS build-env

WORKDIR /vernemq-build

ARG VERNEMQ_GIT_REF=1.9.1
ARG TARGET=rel
ARG VERNEMQ_REPO=https://github.com/vernemq/vernemq.git

# Defaults
ENV DOCKER_VERNEMQ_KUBERNETES_LABEL_SELECTOR="app=vernemq" \
    DOCKER_VERNEMQ_LOG__CONSOLE=console

RUN apt-get update && \
    apt-get -y install build-essential git libssl-dev && \
    git clone -b $VERNEMQ_GIT_REF $VERNEMQ_REPO .

COPY bin/build.sh build.sh

RUN ./build.sh $TARGET


FROM debian:stretch-slim

RUN apt-get update && \
    apt-get -y install procps openssl iproute2 curl jq && \
    rm -rf /var/lib/apt/lists/* && \
    addgroup --gid 10000 vernemq && \
    adduser --uid 10000 --system --ingroup vernemq --home /vernemq --disabled-password vernemq

WORKDIR /vernemq

# Defaults
ENV DOCKER_VERNEMQ_KUBERNETES_LABEL_SELECTOR="app=vernemq" \
    DOCKER_VERNEMQ_LOG__CONSOLE=console \
    PATH="/vernemq/bin:$PATH"

COPY --chown=10000:10000 bin/vernemq.sh /usr/sbin/start_vernemq
COPY --chown=10000:10000 files/vm.args /vernemq/etc/vm.args
COPY --chown=10000:10000 --from=build-env /vernemq-build/release /vernemq

RUN ln -s /vernemq/etc /etc/vernemq && \
    ln -s /vernemq/data /var/lib/vernemq && \
    ln -s /vernemq/log /var/log/vernemq

# Ports
# 1883  MQTT
# 8883  MQTT/SSL
# 8080  MQTT WebSockets
# 44053 VerneMQ Message Distribution
# 4369  EPMD - Erlang Port Mapper Daemon
# 8888  Prometheus Metrics
# 9100 9101 9102 9103 9104 9105 9106 9107 9108 9109  Specific Distributed Erlang Port Range

EXPOSE 1883 8883 8080 44053 4369 8888 \
       9100 9101 9102 9103 9104 9105 9106 9107 9108 9109


VOLUME ["/vernemq/log", "/vernemq/data"]

HEALTHCHECK CMD vernemq ping | grep -q pong

# Openshift Compatibility
COPY --chown=10000:10000 bin/uid_entrypoint /usr/sbin/uid_entrypoint

USER root

RUN chgrp -R 0 /vernemq && \
    chmod -R g=u /vernemq && \
    chgrp -R 0 /usr/sbin/uid_entrypoint && \
    chmod -R g=u /usr/sbin/uid_entrypoint

RUN chmod g=u /etc/passwd
USER vernemq
ENTRYPOINT [ "uid_entrypoint" ]
CMD ["start_vernemq"]

