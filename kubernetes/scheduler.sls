{%- set tplroot = tpldir.split('/')[0] -%}
{%- from tplroot ~ "/map.jinja" import kubernetes with context -%}
{%- set component = 'kube-scheduler' -%}
{%- set component_bin_path = kubernetes.install_dir + '/scheduler' -%}
{%- from tplroot ~ "/vars.jinja" import
    node_role,
    package_flavor,
    apiserver_url,
    kubernetes_ssl_cert_days_valid, kubernetes_ssl_cert_days_remaining,
    kubernetes_ca_cert_path,
    component_ssl_cert_path, component_ssl_key_path,
    component_source, component_source_hash,
    component_kubeconfig
with context -%}
{%- set component_ssl_subject_CN = 'system:' + component -%}
{%- set component_ssl_subject_O  = 'system:' + component -%}
{%- from tplroot ~ "/macros.jinja" import
    kubeconfig,
    kubecomponentbinary
with context -%}
{%- from "ca/macros.jinja" import
    valid_certificate, certificate_private_key, certificate
-%}

include:
  - systemd/cmd

{{ kubecomponentbinary(component, component_source, component_source_hash, component_bin_path) }}

{{ component }}.service:
  file.managed:
    - name: /lib/systemd/system/{{ component }}.service
    - source: salt://{{ tplroot }}/files/systemd/system/{{ component }}.service.j2
    - template: jinja
    - context:
        tpldir: {{ tpldir }}
        tplroot: {{ tplroot }}
    - require:
      - x509: {{ kubernetes_ca_cert_path }}
      - x509: {{ component }}.crt
    - require_in:
      - service: {{ component }}.service-enabled
    - watch_in:
      - module: systemctl-reload

{{ component }}.service-enabled:
  service.enabled:
    - name: {{ component }}
    - require_in:
      - service: {{ component }}.service-running

{{ component_kubeconfig }}:
  file.managed:
    - contents: |
        {{ kubeconfig(component, apiserver_url, kubernetes_ca_cert_path, component_ssl_cert_path, component_ssl_key_path)|indent(8) }}

{{ component }}.service-running:
  service.running:
    - name: {{ component }}
    - watch:
      - x509: {{ component }}.crt
      - x509: {{ component }}.key
      - file: {{ component_kubeconfig }}
      - file: {{ component }}.service
      - file: {{ component }}

{{ valid_certificate(component, component_ssl_cert_path, kubernetes_ssl_cert_days_remaining) }}

{{ certificate_private_key(component, component_ssl_key_path, 'ec', 256) }}

{{ certificate(component, component_ssl_cert_path, component_ssl_key_path, 'kubernetes_ca', 'sha384', 'clientAuth', kubernetes_ssl_cert_days_valid, kubernetes_ssl_cert_days_remaining, component_ssl_subject_CN, component_ssl_subject_O) }}
