{% from "kubernetes/map.jinja" import kubernetes with context %}
{% from "kubernetes/macros.jinja" import
    kubecomponentbinary,
    kubepkicertvalid, kubepkicert, kubepkikey
with context %}

{% set component = 'kube-apiserver' %}
{% set component_bin_path = kubernetes.install_dir + '/apiserver' %}

{% from "kubernetes/vars.jinja" import
    cluster_domain, cluster_ip4,
    node_role, node_fqdn, node_host, node_ip4,
    package_flavor,
    kubernetes_etc_dir,
    kubernetes_ssl_cert_days_valid, kubernetes_ssl_cert_days_remaining,
    kubernetes_ca_cert_path, kubernetes_ca_key_path,
    kubernetes_sa_key_path, kubernetes_sa_pub_path,
    component_ssl_cert_path, component_ssl_key_path,
    component_source, component_source_hash
with context %}

{% set component_ssl_subject_CN = component %}
{% set component_ssl_subject_O  = None %}
{% set component_ssl_subject_SAN = 'DNS:localhost, IP:127.0.0.1, DNS:kubernetes, DNS:kubernetes.default, DNS:kubernetes.default.svc, DNS:kubernetes.default.svc.' + cluster_domain + ', IP:' + cluster_ip4 + ', DNS:' + node_fqdn + ', DNS:' + node_host + ', IP:' + node_ip4 %}

include:
  - systemd/cmd

{{ kubecomponentbinary(component, component_source, component_source_hash, component_bin_path) }}

{{ component }}.service:
  file.managed:
    - name: /lib/systemd/system/{{ component }}.service
    - source: salt://kubernetes/files/systemd/system/{{ component }}.service.j2
    - template: jinja
    - require:
      - x509: {{ kubernetes_sa_key_path }}
{%- if salt['pkg.version_cmp'](kubernetes.source_version, 'v1.20.0') >= 0 %}
      - file: {{ kubernetes_sa_pub_path }}
{%- endif %}
    - require_in:
      - service: {{ component }}.service-enabled
    - watch_in:
      - module: systemctl-reload

{{ component }}.service-enabled:
  service.enabled:
    - name: {{ component }}
    - require_in:
      - service: {{ component }}.service-running

{{ component }}.service-running:
  service.running:
    - name: {{ component }}
    - watch:
      - x509: {{ component }}.crt
      - x509: {{ component }}.key
      - x509: apiserver-kubelet-client.crt
      - x509: apiserver-kubelet-client.key
      - x509: front-proxy-client.crt
      - x509: front-proxy-client.key
      - x509: {{ kubernetes_sa_key_path }}
      - file: {{ component }}.service
      - file: {{ component }}
    - require_in:
      - service: kube-controller-manager.service-running
      - service: kube-scheduler.service-running
      - service: kubelet.service-running
      - service: kube-proxy.service-running

{{ kubepkicertvalid(component, component_ssl_cert_path, kubernetes_ssl_cert_days_remaining) }}

{{ kubepkicert(component, component_ssl_cert_path, component_ssl_key_path, kubernetes_ca_cert_path, kubernetes_ca_key_path, 'serverAuth', kubernetes_ssl_cert_days_valid, kubernetes_ssl_cert_days_remaining, component_ssl_subject_CN, component_ssl_subject_O, component_ssl_subject_SAN) }}

{{ kubepkikey(component, component_ssl_key_path) }}
