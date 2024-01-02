{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import flannel with context -%}
{%- from tplroot ~ "/vars.jinja" import
    package_source, package_source_hash,
    flanneld_bin_path
with context -%}
{%- from "kubernetes/vars.jinja" import
    kubernetes_version
-%}
{%- from "common/vars.jinja" import
    node_roles
-%}

include:
  - systemd/cmd

flanneld:
  file.managed:
    - name: {{ flanneld_bin_path }}
    - mode: 755
    - user: root
    - source: {{ package_source }}
    - source_hash: {{ package_source_hash }}
    - require_in:
      - file: flannel.service

flannel.service:
  file.managed:
    - name: /lib/systemd/system/flannel.service
    - source: salt://{{ tplroot }}/files/systemd/system/flannel.service.j2
    - template: jinja
    - context:
        tpldir: {{ tpldir }}
        tplroot: {{ tplroot }}
    - require_in:
      - service: flannel.service-enabled
{%- if salt['pkg.version_cmp'](kubernetes_version, 'v1.24.0') < 0 %}
  {%- if 'kube-node-proxier' not in node_roles %}
      - file: docker-systemd-drop-in
  {%- endif %}
{%- endif %}
    - watch_in:
      - module: systemctl-reload

flannel.service-enabled:
  service.enabled:
    - name: flannel
    - require_in:
      - service: flannel.service-running

flannel.service-running:
  service.running:
    - name: flannel
    - watch:
      - file: flannel.service
      - file: flanneld
{%- if salt['pkg.version_cmp'](kubernetes_version, 'v1.24.0') < 0 %}
  {%- if 'kube-node-proxier' not in node_roles %}
    - watch_in:
      - service: docker.service-running
  {%- endif %}
{%- endif %}
