{% from "kubernetes/map.jinja" import kubernetes with context %}

{% from "kubernetes/vars.jinja" import
    kubernetes_etc_dir, kubernetes_ssl_dir
with context %}

kubernetes-etc-dir:
  file.directory:
    - name: {{ kubernetes_etc_dir }}
    - dir_mode: 755
    - user: root
    - makedirs: True
{% if kubernetes.k8s.use_ssl %}
    - require_in:
      - file: kubernetes-ssl-dir

kubernetes-ssl-dir:
  file.directory:
    - name: {{ kubernetes_ssl_dir }}
    - dir_mode: 755
    - user: root
    - makedirs: True
{% endif %}
