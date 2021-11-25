{% from "kubernetes/map.jinja" import kubernetes with context %}
{% from "kubernetes/macros.jinja" import
    kubecomponentbinary,
    kubepkicertvalid, kubepkicert, kubepkikey
with context %}

{% set component = 'kube-proxy' %}
{% set component_bin_path = kubernetes.install_dir + '/proxy' %}

{% from "kubernetes/vars.jinja" import
    node_role,
    package_flavor,
    kubernetes_etc_dir,
    kubernetes_ssl_cert_days_valid, kubernetes_ssl_cert_days_remaining,
    kubernetes_ca_cert_path, kubernetes_ca_key_path,
    component_ssl_cert_path, component_ssl_key_path,
    component_source, component_source_hash
with context %}

{% set component_ssl_subject_CN = 'system:' + component %}
{% set component_ssl_subject_O  = 'system:node-proxier' %}

include:
  - systemd/cmd
  - debian/packages/conntrack
  - debian/sysctl/ip-forward
{% if node_role == 'node' %}
  - .haproxy
{% endif %}

{{ kubecomponentbinary(component, component_source, component_source_hash, component_bin_path, package_flavor) }}

{{ component }}-systemd-unit-file:
  file.managed:
    - name: /lib/systemd/system/{{ component }}.service
    - source: salt://kubernetes/files/systemd/system/{{ component }}.service.j2
    - template: jinja
    - require:
      - x509: kubernetes-ca.crt
      - x509: {{ component }}.crt
    - require_in:
      - service: {{ component }}-service-enable
    - watch_in:
      - module: systemctl-reload

{{ component }}-service-enable:
  service.enabled:
    - name: {{ component }}
    - require_in:
      - service: {{ component }}-service-running

{{ component }}-kubeconfig:
  file.managed:
    - name: {{ kubernetes_etc_dir }}/proxy.kubeconfig
    - source: salt://kubernetes/files/kubeconfig.j2
    - template: jinja
    - context:
        component: {{ component }}

{{ component }}-service-running:
  service.running:
    - name: {{ component }}
    - watch:
      - x509: {{ component }}.crt
      - x509: {{ component }}.key
      - file: {{ component }}-systemd-unit-file
      - file: {{ component }}
      - file: {{ component }}-kubeconfig
    - require:
      - sysctl: net.ipv4.ip_forward
{% if node_role == 'node' %}
      - file: haproxy.cfg
{% endif %}
      - pkg: conntrack

{{ kubepkicertvalid(component, component_ssl_cert_path, kubernetes_ssl_cert_days_remaining) }}

{{ kubepkicert(component, component_ssl_cert_path, component_ssl_key_path, kubernetes_ca_cert_path, kubernetes_ca_key_path, 'clientAuth', kubernetes_ssl_cert_days_valid, kubernetes_ssl_cert_days_remaining, component_ssl_subject_CN, component_ssl_subject_O) }}

{{ kubepkikey(component, component_ssl_key_path) }}
