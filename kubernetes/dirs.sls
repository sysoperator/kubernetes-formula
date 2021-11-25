{% from "kubernetes/map.jinja" import kubernetes with context %}

{% from "kubernetes/vars.jinja" import
    kubernetes_etc_dir, kubernetes_ssl_dir
with context %}

{{ kubernetes_etc_dir }}:
  file.directory:
    - dir_mode: 755
    - user: root
    - makedirs: True
    - require_in:
      - file: {{ kubernetes_ssl_dir }}

{{ kubernetes_ssl_dir }}:
  file.directory:
    - dir_mode: 755
    - user: root
    - makedirs: True
