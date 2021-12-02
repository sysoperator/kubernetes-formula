{%- set tplroot = tpldir.split('/')[0] -%}
{%- from tplroot ~ "/map.jinja" import kubernetes with context -%}
{%- from tplroot ~ "/vars.jinja" import
    node_role,
    kubernetes_etc_dir, kubernetes_ssl_dir, kubernetes_manifests_dir,
    kube_admin_kubeconfig_dir
with context -%}

{{ kubernetes_etc_dir }}:
  file.directory:
    - dir_mode: 755
    - user: root
    - makedirs: True
    - require_in:
      - file: {{ kubernetes_ssl_dir }}
{% if node_role == 'master' %}
      - file: {{ kubernetes_manifests_dir }}
{% endif %}

{{ kubernetes_ssl_dir }}:
  file.directory:
    - dir_mode: 755
    - user: root
    - makedirs: True

{% if node_role == 'master' %}
{{ kubernetes_manifests_dir }}:
  file.directory:
    - dir_mode: 755
    - user: root
    - makedirs: True

{{ kube_admin_kubeconfig_dir }}:
  file.directory:
    - dir_mode: 750
    - user: root
    - makedirs: True
{% endif %}
