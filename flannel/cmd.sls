{% from "flannel/map.jinja" import flannel with context %}

flannel-service-restart:
  module.wait:
    - name: service.restart
    - m_name: flannel
    - onlyif:
      - systemctl is-active --quiet flannel.service
