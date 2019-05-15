FROM ubuntu:latest

COPY --from=dceoy/rsem:latest /usr/local /usr/local
COPY --from=dceoy/prinseq:latest /usr/local/src/prinseq /usr/local/src/prinseq
COPY --from=dceoy/fastqc:latest /usr/local/src/FastQC /usr/local/src/FastQC

ENV DEBIAN_FRONTEND noninteractive

RUN set -e \
      && apt-get -y update \
      && apt-get -y dist-upgrade \
      && apt-get -y install --no-install-recommends --no-install-suggests \
        ca-certificates curl libgomp1 openjdk-8-jre perl perl-doc pigz python \
      && apt-get -y autoremove \
      && apt-get clean \
      && rm -rf /var/lib/apt/lists/*

RUN set -e \
      && ln -s /usr/local/src/FastQC/fastqc /usr/local/bin/fastqc \
      && find /usr/local/src/prinseq -maxdepth 1 -type f -executable \
        -exec ln -s {} /usr/local/bin \;

ENTRYPOINT ["/usr/local/bin/rsem-calculate-expression"]
