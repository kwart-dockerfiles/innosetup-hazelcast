FROM maven:3.6.3-openjdk-8-slim as maven

COPY service-starter /opt/service-starter

RUN mvn -f /opt/service-starter clean install

FROM ubuntu:20.04

ENV WINEDEBUG=-all,err+all \
    DISPLAY=:99

COPY bin/* /usr/bin/
COPY resources /opt/resources
COPY --from=maven /opt/service-starter/target/service-starter.jar /opt/resources/

RUN apt-get update \
    && apt-get install -y curl wget unzip procps xvfb openjdk-8-jre-headless \
    && dpkg --add-architecture i386 \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y -o APT::Immediate-Configure=false wine wine32 \
    && echo "Downloading Apache Commons Daemon" \
    && wget -q -O /tmp/commons-daemon.zip https://downloads.apache.org/commons/daemon/binaries/windows/commons-daemon-1.2.3-bin-windows.zip \
    && unzip /tmp/commons-daemon.zip -d /opt/resources/commons-daemon \
    && echo "Downloading Windows JREs" \
    && set -e \
    && for xbits in 32 64; do \
         wget -q -O /tmp/jre${xbits}.zip "https://api.adoptopenjdk.net/v2/binary/releases/openjdk8?openjdk_impl=hotspot&os=windows&arch=x${xbits}&release=latest&type=jre"; \
         unzip -d /opt /tmp/jre${xbits}.zip; \
         mv /opt/jdk8* /opt/jre${xbits}; \
         rm /tmp/jre${xbits}.zip; \
       done \
    && set +e \
    && echo "Installing Launch4j" \
    && curl -s -SL https://sourceforge.net/projects/launch4j/files/launch4j-3/3.12/launch4j-3.12-linux-x64.tgz | tar xzf - -C /opt \
    && echo alias launch4j=/opt/launch4j/launch4j >> /root/.bashrc \
    && echo "Installing Inno Setup binaries" \
    && wget -q -O is.exe "http://files.jrsoftware.org/is/6/innosetup-6.0.5.exe" \
    && wine-x11-run wine is.exe /SP- /VERYSILENT /ALLUSERS /SUPPRESSMSGBOXES \
    && rm -rf is.exe /tmp/commons-daemon.zip /var/lib/apt/lists/*
