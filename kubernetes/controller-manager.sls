{% from "kubernetes/map.jinja" import kubernetes with context %}
{% from "kubernetes/macros.jinja" import kubecomponentbinary with context %}

{% set component = 'kube-controller-manager' %}
{% set component_bin_path = kubernetes.install_dir + '/controller-manager' %}

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
{% set component_ssl_subject_O  = 'system:' + component %}

include:
  - systemd/cmd

{{ kubecomponentbinary(component, component_source, component_source_hash, component_bin_path) }}

{{ component }}-systemd-unit-file:
  file.managed:
    - name: /lib/systemd/system/{{ component }}.service
    - source: salt://kubernetes/files/systemd/system/{{ component }}.service.j2
    - template: jinja
    - require:
      - x509: sa.key
{% if kubernetes.k8s.use_ssl %}
      - x509: kubernetes-ca.crt
      - x509: {{ component }}.crt
{% endif %}
    - require_in:
      - service: {{ component }}-service-enable
    - watch_in:
      - module: systemctl-reload

{{ component }}-service-enable:
  service.enabled:
    - name: {{ component }}
    - require_in:
      - service: {{ component }}-service-running

{% if kubernetes.k8s.use_ssl %}
{{ component }}-kubeconfig:
  file.managed:
    - name: {{ kubernetes_etc_dir }}/controller-manager.kubeconfig
    - source: salt://kubernetes/files/kubeconfig.j2
    - template: jinja
    - context:
        component: {{ component }}
{% endif %}

{{ component }}-service-running:
  service.running:
    - name: {{ component }}
    - watch:
      - x509: sa.key
{% if kubernetes.k8s.use_ssl %}
      - x509: kubernetes-ca.crt
  {%- if kubernetes.k8s.enable_cert_issuer %}
      - x509: kubernetes-ca.key
  {%- endif %}
      - x509: {{ component }}.crt
      - x509: {{ component }}.key
      - file: {{ component }}-kubeconfig
{% endif %}
      - file: {{ component }}-systemd-unit-file
      - file: {{ component }}

{# Certs #}
{%- if kubernetes.k8s.use_ssl %}
{{ component }}.crt-validate:
  tls.valid_certificate:
    - name: {{ component_ssl_cert_path }}
    - days: {{ kubernetes_ssl_cert_days_remaining }}
    - require:
      - pkg: python3-openssl
    - onlyif:
      - test -f {{ component_ssl_cert_path }}

{{ component }}.crt:
  x509.certificate_managed:
    - name: {{ component_ssl_cert_path }}
    - mode: 644
    - user: root
    - signing_cert: {{ kubernetes_ca_cert_path }}
    - signing_private_key: {{ kubernetes_ca_key_path }}
    - public_key: {{ component_ssl_key_path }}
    - CN: {{ component_ssl_subject_CN }}
    - O: {{ component_ssl_subject_O }}
    - basicConstraints: "CA:FALSE"
    - extendedKeyUsage: "clientAuth"
    - keyUsage: "nonRepudiation, digitalSignature, keyEncipherment"
    - days_valid: {{ kubernetes_ssl_cert_days_valid }}
    - days_remaining: {{ kubernetes_ssl_cert_days_remaining }}
    - backup: True
    - require:
      - pkg: python3-m2crypto
  {%- if salt['file.file_exists'](component_ssl_cert_path) %}
    - onfail:
      - tls: {{ component }}.crt-validate
  {%- endif %}

{{ component }}.key:
  x509.private_key_managed:
    - name: {{ component_ssl_key_path }}
    - bits: 2048
    - verbose: False
    - mode: 600
    - require:
      - pkg: python3-m2crypto
    - require_in:
      - x509: {{ component }}.crt
{%- endif %}
{# EOF #}
