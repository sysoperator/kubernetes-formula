{% from "kubernetes/map.jinja" import kubernetes with context %}

include:
  - debian/packages/haproxy

/etc/haproxy/haproxy.cfg:
  file.managed:
    - source: salt://kubernetes/files/haproxy/haproxy.cfg.j2
    - template: jinja
    - require:
      - pkg: haproxy

haproxy.service-running:
  service.running:
    - name: haproxy
    - watch:
      - file: /etc/haproxy/haproxy.cfg
