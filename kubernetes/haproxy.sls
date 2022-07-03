{%- set tplroot = tpldir.split('/')[0] -%}
{%- from tplroot ~ "/map.jinja" import kubernetes with context -%}

include:
  - debian/packages/haproxy

{% if salt['grains.get']('os_family') == 'RedHat' %}
extend:
  haproxy:
    pkg.installed:
    - require_in:
      - selinux: haproxy_connect_any

haproxy_connect_any:
  selinux.boolean:
    - value: True
    - persist: True
{% endif %}

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
