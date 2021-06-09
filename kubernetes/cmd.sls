{% from "kubernetes/map.jinja" import kubernetes with context %}

kube-apiserver-service-restart:
  module.wait:
    - name: service.restart
    - m_name: kube-apiserver
    - onlyif:
      - systemctl is-active --quiet kube-apiserver.service
