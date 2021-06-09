{% from "kubernetes/map.jinja" import kubernetes with context %}

include:
  - debian/packages/haproxy

haproxy.cfg:
  file.managed:
    - name: /etc/haproxy/haproxy.cfg
    - source: salt://kubernetes/files/haproxy/haproxy.cfg.j2
    - template: jinja
    - require:
      - pkg: haproxy

haproxy-service-running:
  service.running:
    - name: haproxy
    - watch:
      - file: haproxy.cfg
