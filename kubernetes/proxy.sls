{%- set tplroot = tpldir.split('/')[0] -%}
{%- from tplroot ~ "/map.jinja" import kubernetes with context -%}
{%- set component = 'kube-proxy' -%}
{%- set component_bin_path = kubernetes.install_dir + '/proxy' -%}
{%- from tplroot ~ "/vars.jinja" import
    node_role,
    package_flavor,
    apiserver_url,
    kubernetes_ssl_cert_days_valid, kubernetes_ssl_cert_days_remaining,
    kubernetes_ca_cert_path, kubernetes_ca_key_path,
    component_ssl_cert_path, component_ssl_key_path,
    component_source, component_source_hash,
    component_kubeconfig
with context -%}
{%- set component_ssl_subject_CN = 'system:' + component -%}
{%- set component_ssl_subject_O  = 'system:node-proxier' -%}
{%- from tplroot ~ "/macros.jinja" import
    kubeconfig,
    kubecomponentbinary,
    kubepkicertvalid, kubepkicert, kubepkikey
with context -%}
{%- from "common/vars.jinja" import
    node_roles
-%}

include:
  - systemd/cmd
  - debian/packages/iptables
  - debian/packages/conntrack
  - debian/packages/ipset
  - sysctl/ip-forward
{% if node_role == 'node' or 'kube-node-proxier' in node_roles %}
  - .haproxy
{% endif %}

{{ kubecomponentbinary(component, component_source, component_source_hash, component_bin_path, package_flavor) }}

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

xt_conntrack.module-load:
  file.managed:
    - name: /etc/modules-load.d/conntrack.conf
    - contents: |
        xt_conntrack
    - watch_in:
      - module: systemd-modules-load

{{ component }}.service-running:
  service.running:
    - name: {{ component }}
    - watch:
      - x509: {{ component }}.crt
      - x509: {{ component }}.key
      - file: {{ component_kubeconfig }}
      - file: {{ component }}.service
      - file: {{ component }}
    - require:
      - sysctl: net.ipv4.ip_forward
      - file: xt_conntrack.module-load
{% if node_role == 'node' %}
      - file: /etc/haproxy/haproxy.cfg
{% endif %}
      - pkg: iptables
      - pkg: conntrack
      - pkg: ipset

{{ kubepkicertvalid(component, component_ssl_cert_path, kubernetes_ssl_cert_days_remaining) }}

{{ kubepkicert(component, component_ssl_cert_path, component_ssl_key_path, kubernetes_ca_cert_path, kubernetes_ca_key_path, 'clientAuth', kubernetes_ssl_cert_days_valid, kubernetes_ssl_cert_days_remaining, component_ssl_subject_CN, component_ssl_subject_O) }}

{{ kubepkikey(component, component_ssl_key_path) }}
