{%- set tplroot = tpldir.split('/')[0] -%}
{%- from tplroot ~ "/map.jinja" import kubernetes with context -%}
{%- set component = 'kube-apiserver' -%}
{%- set component_bin_path = kubernetes.install_dir + '/apiserver' -%}
{%- from tplroot ~ "/vars.jinja" import
    cluster_dns_cluster_domain,
    cluster_ip4,
    node_role,
    package_flavor,
    apiserver_external_domain,
    apiserver_healthz_url,
    kubernetes_etc_dir,
    kubernetes_ssl_cert_days_valid, kubernetes_ssl_cert_days_remaining,
    kubernetes_ca_cert_path, kubernetes_ca_key_path,
    kubernetes_sa_key_path, kubernetes_sa_pub_path,
    kube_admin_kubeconfig,
    component_ssl_cert_path, component_ssl_key_path,
    component_source, component_source_hash,
    clusterrolebinding_system_kubelet_api_admin, clusterrolebinding_system_kubelet_api_admin_path
with context -%}
{%- from "common/vars.jinja" import
    node_fqdn, node_host, node_ip4
-%}
{%- set component_ssl_subject_CN = component -%}
{%- set component_ssl_subject_O  = None -%}
{%- set component_ssl_subject_SAN = 'DNS:localhost, IP:127.0.0.1, DNS:kubernetes, DNS:kubernetes.default, DNS:kubernetes.default.svc, DNS:kubernetes.default.svc.' + cluster_dns_cluster_domain + ', IP:' + cluster_ip4 + ', DNS:' + node_fqdn + ', DNS:' + node_host + ', IP:' + node_ip4 + apiserver_external_domain -%}
{%- from tplroot ~ "/macros.jinja" import
    kubecomponentbinary,
    kubepkicertvalid, kubepkicert, kubepkikey
with context -%}

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

{{ component }}-is-ready:
  http.wait_for_successful_query:
    - name: {{ apiserver_healthz_url }}
    - wait_for: 30
    - request_interval: 1
    - status: 200
    - ca_bundle: {{ kubernetes_ca_cert_path }}
    - onchanges:
      - service: {{ component }}.service-running
    - require_in:
      - cmd: {{ clusterrolebinding_system_kubelet_api_admin }}

{{ clusterrolebinding_system_kubelet_api_admin_path}}:
  file.managed:
    - source: salt://{{ tplroot }}/files/kubernetes/manifests/{{ clusterrolebinding_system_kubelet_api_admin }}.yaml

{{ clusterrolebinding_system_kubelet_api_admin }}:
  cmd.run:
    - name: kubectl create -f {{ clusterrolebinding_system_kubelet_api_admin_path}}
    - onlyif:
      - sh -c '[ x$(kubectl get clusterrolebindings -o json | jq -e '"'"'.items[] | select(.metadata.name == "{{ clusterrolebinding_system_kubelet_api_admin }}") | has("kind")'"'"') = x'"'"''"'"' ]'
    - require:
      - pkg: jq
      - file: kubectl
      - file: {{ kube_admin_kubeconfig }}
      - file: {{ clusterrolebinding_system_kubelet_api_admin_path }}

{{ kubepkicertvalid(component, component_ssl_cert_path, kubernetes_ssl_cert_days_remaining) }}

{{ kubepkicert(component, component_ssl_cert_path, component_ssl_key_path, kubernetes_ca_cert_path, kubernetes_ca_key_path, 'serverAuth', kubernetes_ssl_cert_days_valid, kubernetes_ssl_cert_days_remaining, component_ssl_subject_CN, component_ssl_subject_O, component_ssl_subject_SAN) }}

{{ kubepkikey(component, component_ssl_key_path) }}
