FROM jenkins/jenkins:lts-jdk17

ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

USER root

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    git \
    openssh-client \
    sshpass \
    maven \
    python3 \
    python3-pip \
    ansible \
    curl \
    unzip \
    ca-certificates \
  && rm -rf /var/lib/apt/lists/*

COPY docker/plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli -f /usr/share/jenkins/ref/plugins.txt

COPY docker/init.groovy.d/ /usr/share/jenkins/ref/init.groovy.d/
COPY pipelines/ /usr/share/jenkins/ref/pipelines/

USER jenkins
