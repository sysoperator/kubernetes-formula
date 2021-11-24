{% from "kubernetes/map.jinja" import kubernetes with context %}
{% from "kubernetes/macros.jinja" import kubecomponentbinary with context %}

{% set component = 'kube-apiserver' %}
{% set component_bin_path = kubernetes.install_dir + '/apiserver' %}

{% from "kubernetes/vars.jinja" import
    cluster_domain, cluster_ip4,
    node_role, node_fqdn, node_host, node_ip4,
    package_flavor,
    kubernetes_etc_dir, kubernetes_security_dir, kubernetes_state_dir,
    kubernetes_ssl_cert_days_valid, kubernetes_ssl_cert_days_remaining,
    kubernetes_ca_cert_path, kubernetes_ca_key_path,
    kubernetes_sa_path,
    component_ssl_cert_path, component_ssl_key_path,
    component_source, component_source_hash
with context %}

{% set component_ssl_subject_CN = component %}
{% set component_ssl_subject_O  = component %}

include:
  - systemd/cmd

{{ kubecomponentbinary(component, component_source, component_source_hash, component_bin_path) }}

{{ component }}-systemd-unit-file:
  file.managed:
    - name: /lib/systemd/system/{{ component }}.service
    - source: salt://kubernetes/files/systemd/system/{{ component }}.service.j2
    - template: jinja
    - require:
      - file: {{ component }}-service-account.key
    - require_in:
      - service: {{ component }}-service-enable
    - watch_in:
      - module: systemctl-reload

{{ component }}-service-account.key:
  file.symlink:
    - name: {{ kubernetes_state_dir }}/kube-service-account.key
    - target: {{ kubernetes_sa_path }}
    - require:
      - file: kubernetes-state-dir
      - x509: sa.key

{{ component }}-service-enable:
  service.enabled:
    - name: {{ component }}
    - require_in:
      - service: {{ component }}-service-running

{{ component }}-service-running:
  service.running:
    - name: {{ component }}
    - watch:
{%- if kubernetes.k8s.use_ssl %}
      - x509: {{ component }}.crt
      - x509: {{ component }}.key
      - x509: kubelet-client.crt
      - x509: kubelet-client.key
      - x509: proxy-client.crt
      - x509: proxy-client.key
{%- endif %}
      - x509: sa.key
      - file: {{ component }}-systemd-unit-file
      - file: {{ component }}
    - require_in:
      - service: kube-controller-manager-service-running
      - service: kube-scheduler-service-running
      - service: kubelet-service-running
      - service: kube-proxy-service-running

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
    - basicConstraints: "CA:FALSE"
    - extendedKeyUsage: "serverAuth"
    - keyUsage: "nonRepudiation, digitalSignature, keyEncipherment"
    - subjectAltName: "DNS:localhost, IP:127.0.0.1, DNS:kubernetes, DNS:kubernetes.default, DNS:kubernetes.default.svc, DNS:kubernetes.default.svc.{{ cluster_domain }}, IP:{{ cluster_ip4 }}, DNS:{{ node_fqdn }}, DNS:{{ node_host }}, IP:{{ node_ip4 }}"
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
