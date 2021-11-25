{% from "cni/map.jinja" import cni with context %}

{% from "cni/vars.jinja" import
    cni_etc_dir, cni_plugins_dir
with context %}

{{ cni_etc_dir }}:
  file.directory:
    - dir_mode: 755
    - user: root
    - makedirs: True

{{ cni_plugins_dir }}:
  file.directory:
    - name: {{ cni_plugins_dir }}
    - dir_mode: 755
    - user: root
    - makedirs: True
