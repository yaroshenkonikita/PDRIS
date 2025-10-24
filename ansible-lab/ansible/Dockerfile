FROM python:3.11-slim

ENV PIP_NO_CACHE_DIR=1

RUN pip install --no-cache-dir \
    ansible==9.5.1 \
    jmespath \
    docker \
    requests-unixsocket

COPY requirements.yml /tmp/requirements.yml
RUN ansible-galaxy collection install -r /tmp/requirements.yml && rm -f /tmp/requirements.yml

WORKDIR /ansible

COPY ansible.cfg /ansible/ansible.cfg

CMD ["bash", "-lc", "ansible --version && ls -la /ansible && bash"]
