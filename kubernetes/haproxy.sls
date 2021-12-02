{%- set tplroot = tpldir.split('/')[0] -%}
{%- from tplroot ~ "/map.jinja" import kubernetes with context -%}

include:
  - debian/packages/haproxy

/etc/haproxy/haproxy.cfg:
  file.managed:
    - source: salt://{{ tplroot }}/files/haproxy/haproxy.cfg.j2
    - template: jinja
    - context:
        tpldir: {{ tpldir }}
        tplroot: {{ tplroot }}
    - require:
      - pkg: haproxy

haproxy.service-running:
  service.running:
    - name: haproxy
    - watch:
      - file: /etc/haproxy/haproxy.cfg
