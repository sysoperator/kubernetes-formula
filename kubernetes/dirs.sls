{% from "kubernetes/map.jinja" import kubernetes with context %}

{% from "kubernetes/vars.jinja" import
    kubernetes_etc_dir, kubernetes_state_dir, kubernetes_ssl_dir, kubernetes_security_dir
with context %}

kubernetes-etc-dir:
  file.directory:
    - name: {{ kubernetes_etc_dir }}
    - dir_mode: 755
    - user: root
    - makedirs: True
    - require_in:
{% if kubernetes.k8s.use_ssl %}
      - file: kubernetes-ssl-dir
{% endif %}
      - file: kubernetes-security-dir

{% if kubernetes.k8s.use_ssl %}
kubernetes-ssl-dir:
  file.directory:
    - name: {{ kubernetes_ssl_dir }}
    - dir_mode: 755
    - user: root
    - makedirs: True
{% endif %}

kubernetes-state-dir:
  file.directory:
    - name: {{ kubernetes_state_dir }}
    - dir_mode: 755
    - user: root
    - makedirs: True

{# Cleanup #}
kubernetes-security-dir:
  file.absent:
    - name: {{ kubernetes_security_dir }}
    - require:
      - file: kubernetes-etc-dir
{# EOF #}
