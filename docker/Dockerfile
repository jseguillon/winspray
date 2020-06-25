FROM  quay.io/kubespray/kubespray:v2.13.1
RUN mkdir -p /winspray/playbooks && mkdir -p /winspray/config
COPY playbooks /winspray/playbooks/
COPY config /winspray/config
COPY Vagrantfile /winspray
COPY ansible.cfg /winspray
RUN curl -SsL https://github.com/derailed/k9s/releases/download/v0.20.5/k9s_Linux_x86_64.tar.gz -o /tmp/k9s.tar.gz &&  tar xf /tmp/k9s.tar.gz && mv k9s /usr/bin/
