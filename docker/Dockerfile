FROM  quay.io/kubespray/kubespray:v2.13.1
RUN mkdir -p /winspray/playbooks && mkdir -p /winspray/config
COPY playbooks /winspray/playbooks/
COPY config /winspray/config
COPY Vagrantfile /winspray
COPY ansible.cfg /winspray