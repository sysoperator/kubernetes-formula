{% from "kubernetes/map.jinja" import kubernetes with context %}
{% from "kubernetes/macros.jinja" import kubecomponentbinary with context %}

{% set component = 'kubelet' %}
{% set component_bin_path = kubernetes.install_dir + '/kubelet' %}

{% from "kubernetes/vars.jinja" import
    node_role, node_host,
    package_flavor,
    kubernetes_etc_dir, kubernetes_ssl_dir,
    kubernetes_ssl_cert_days_valid, kubernetes_ssl_cert_days_remaining,
    kubernetes_ca_cert_path, kubernetes_ca_key_path,
    component_ssl_cert_path, component_ssl_key_path,
    component_source, component_source_hash
with context %}

{% set component_ssl_subject_CN = 'system:node:' + node_host %}
{% set component_ssl_subject_O  = 'system:nodes' %}

include:
  - systemd/cmd
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

{{ component }}-systemd-cgroups-drop-in-file:
  file.managed:
    - name: /etc/systemd/systemd/{{ component }}.service.d/10-cgroups.conf
    - source: salt://kubernetes/files/systemd/system/{{ component }}.service.d/10-cgroups.conf
    - makedirs: True
    - dir_mode: 755
    - require:
      - file: {{ component }}-systemd-unit-file
    - require_in:
      - service: {{ component }}-service-enable
    - watch_in:
      - module: systemctl-reload

{{ component }}-service-enable:
  service.enabled:
    - name: {{ component }}
    - require_in:
      - service: {{ component }}-service-running

{% if salt['pkg.version_cmp'](kubernetes.source_version, 'v1.8.0') >= 0 %}
{{ component }}-kubeconfig:
  file.managed:
    - name: {{ kubernetes_etc_dir }}/{{ component }}.kubeconfig
    - source: salt://kubernetes/files/kubeconfig.j2
    - template: jinja
    - context:
        component: {{ component }}
{% endif %}

{{ component }}-service-running:
  service.running:
    - name: {{ component }}
    - watch:
      - x509: {{ component }}.crt
      - x509: {{ component }}.key
      - file: {{ component }}-systemd-unit-file
      - file: {{ component }}
{% if salt['pkg.version_cmp'](kubernetes.source_version, 'v1.8.0') >= 0 %}
      - file: {{ component }}-kubeconfig
{% endif %}
    - require:
{% if node_role == 'node' %}
      - file: haproxy.cfg
{% endif %}
      - service: kube-proxy-service-running

{# Certs #}
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
{# EOF #}
