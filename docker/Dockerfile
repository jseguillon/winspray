FROM  quay.io/kubespray/kubespray:v2.13.1
RUN mkdir -p /winspray/playbooks && mkdir -p /winspray/config
COPY playbooks /winspray/playbooks/
COPY config /winspray/config
RUN mkdir -p /root/.ssh && chmod 0600 /root/.ssh
# This will ensure key from mount point is copied into /root/.ssh when going into docker interractive
RUN echo 'cp -f /opt/winspray/current/id_rsa /root/.ssh 2> /dev/null && chmod -R 0600 /root/.ssh' >> /root/.bashrc
COPY Vagrantfile /winspray
COPY ansible.cfg /winspray
RUN curl -SsL https://github.com/derailed/k9s/releases/download/v0.20.5/k9s_Linux_x86_64.tar.gz -o /tmp/k9s.tar.gz &&  tar xf /tmp/k9s.tar.gz && mv k9s /usr/bin/

# Expose for proxy
EXPOSE 8001
