{%- set tplroot = tpldir.split('/')[0] -%}
{%- from tplroot ~ "/map.jinja" import cni with context -%}
{%- from tplroot ~ "/vars.jinja" import
    package_source, package_source_hash,
    cni_etc_dir, cni_plugins_dir
with context -%}

{% set cni_installed_version = salt['cmd.shell']('test -d /opt/cni/bin && /opt/cni/bin/dummy 2>&1 | grep -m 1 -o '"'"'[^ ]*$'"'"'') %}

include:
  - debian/packages/ca-certificates
  - debian/packages/bridge-utils
  - .dirs

{{ cni_etc_dir }}/10-bridge.conf:
  file.managed:
    - source: salt://{{ tplroot }}/files/cni/net.d/10-bridge.conf.j2
    - template: jinja
    - context:
        tpldir: {{ tpldir }}
        tplroot: {{ tplroot }}
    - require:
      - file: {{ cni_etc_dir }}

cni-plugins-install:
  archive.extracted:
    - name: {{ cni_plugins_dir }}
    - source: {{ package_source }}
    - source_hash: {{ package_source_hash }}
    - archive_format: tar
    - options: v
    - user: root
    - group: root
    - keep: True
{% if salt['pkg.version_cmp'](cni.source_version, cni_installed_version|default(cni.source_version, true)) > 0 %}
    - overwrite: True
{% endif %}
    - require:
      - pkg: ca-certificates
      - pkg: bridge-utils
      - file: {{ cni_plugins_dir }}
