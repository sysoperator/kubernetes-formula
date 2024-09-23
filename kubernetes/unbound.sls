{%- set tplroot = tpldir.split('/')[0] -%}
{%- from tplroot ~ "/map.jinja" import kubernetes with context -%}
{%- from tplroot ~ "/vars.jinja" import
    unbound_log_file
with context -%}
include:
  - debian/packages/unbound

{%- for conffile in ['access-control.conf', 'forward-zone.conf', 'listen-address.conf', 'logging.conf'] %}
/etc/unbound/unbound.conf.d/{{ conffile }}:
  file.managed:
    - source: salt://{{ tplroot }}/files/unbound.conf.d/{{ conffile }}.j2
    - template: jinja
    - context:
        tplroot: {{ tplroot }}
        tpldir: {{ tpldir }}
    - require:
      - pkg: unbound
    - watch_in:
      - service: unbound.service-running
{%- endfor %}

/etc/unbound/unbound.conf.d/root-auto-trust-anchor-file.conf:
  file.replace:
    - pattern: '^(\s+)(auto-trust-anchor-file):'
    - repl: '\1#\2:'

{{ unbound_log_file }}:
  file.managed:
    - user: unbound
    - group: adm
    - mode: 640
    - makedirs: True
    - watch_in:
      - service: unbound.service-running

unbound.service-running:
  service.running:
    - name: unbound
