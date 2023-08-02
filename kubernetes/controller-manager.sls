{%- set tplroot = tpldir.split('/')[0] -%}
{%- from tplroot ~ "/map.jinja" import kubernetes with context -%}
{%- set component = 'kube-controller-manager' -%}
{%- set component_bin_path = kubernetes.install_dir + '/controller-manager' -%}
{%- from tplroot ~ "/vars.jinja" import
    k8s,
    node_role,
    package_flavor,
    apiserver_url,
    kubernetes_ssl_cert_days_valid, kubernetes_ssl_cert_days_remaining,
    kubernetes_ca_cert_path, kubernetes_ca_key_path,
    kubernetes_sa_key_path, kubernetes_sa_pub_path,
    kubernetes_ssl_dir,
    kubernetes_x509_signers,
    component_ssl_cert_path, component_ssl_key_path,
    component_source, component_source_hash,
    component_kubeconfig
with context -%}
{%- set component_ssl_subject_CN = 'system:' + component -%}
{%- set component_ssl_subject_O  = 'system:' + component -%}
{%- from tplroot ~ "/macros.jinja" import
    kubeconfig,
    kubecomponentbinary,
    kubepkicertvalid, kubepkicert, kubepkikey
with context -%}
{%- from "debian/packages/macros.jinja" import
    Python3_M2Crypto
-%}

include:
  - debian/packages/python3-m2crypto
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
      - x509: {{ kubernetes_sa_key_path }}
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
      - x509: {{ kubernetes_sa_key_path }}
      - x509: {{ kubernetes_ca_cert_path }}
{%- if k8s.x509_signers_enabled %}
      - x509: {{ kubernetes_ca_key_path }}
  {%- for signer in kubernetes_x509_signers %}
      - x509: {{ kubernetes_ssl_dir }}/{{ signer['name'] }}-ca.crt
      - x509: {{ kubernetes_ssl_dir }}/{{ signer['name'] }}-ca.key
  {%- endfor %}
{%- endif %}
      - x509: {{ component }}.crt
      - x509: {{ component }}.key
      - file: {{ component_kubeconfig }}
      - file: {{ component }}.service
      - file: {{ component }}

{{ kubepkicertvalid(component, component_ssl_cert_path, kubernetes_ssl_cert_days_remaining) }}

{{ kubepkicert(component, component_ssl_cert_path, component_ssl_key_path, kubernetes_ca_cert_path, kubernetes_ca_key_path, 'clientAuth', kubernetes_ssl_cert_days_valid, kubernetes_ssl_cert_days_remaining, component_ssl_subject_CN, component_ssl_subject_O) }}

{{ kubepkikey(component, component_ssl_key_path) }}

{%- for signer in kubernetes_x509_signers %}
{{ kubernetes_ssl_dir }}/{{ signer['name'] }}-ca.crt:
  x509.pem_managed:
    - mode: 644
    - user: root
    - group: root
    - text: |
        {{ signer['cert']|indent(8) }}
    - require:
{{ Python3_M2Crypto() }}
      - file: {{ kubernetes_ssl_dir }}
    - require_in:
      - x509: {{ kubernetes_ssl_dir }}/{{ signer['name'] }}-ca.key

{{ kubernetes_ssl_dir }}/{{ signer['name'] }}-ca.key:
  x509.pem_managed:
    - mode: 600
    - user: root
    - group: root
    - text: |
        {{ signer['key']|indent(8) }}
    - require:
{{ Python3_M2Crypto() }}
      - file: {{ kubernetes_ssl_dir }}
{%- endfor %}
