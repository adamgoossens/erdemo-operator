# buildah bud -f Dockerfile -t quay.io/emergencyresponsedemo/erdemo-operator:$VERSION .

FROM quay.io/operator-framework/ansible-operator:v1.0.1

COPY requirements.yml ${HOME}/requirements.yml
RUN ansible-galaxy collection install -r ${HOME}/requirements.yml \
 && chmod -R ug+rwx ${HOME}/.ansible
USER root
RUN dnf install -y openssl && curl http://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/linux/oc.tar.gz -o /root/oc.tar.gz && \
    tar xvzf /root/oc.tar.gz -C /usr/local/bin
USER ansible
COPY watches.yaml ${HOME}/watches.yaml
COPY roles/ ${HOME}/roles/
COPY playbooks/ ${HOME}/playbooks/
COPY resources/ ${HOME}/resources/
