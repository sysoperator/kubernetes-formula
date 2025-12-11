{%- set tplroot = tpldir.split('/')[0] -%}
{%- from tplroot ~ "/map.jinja" import kubernetes with context -%}
{%- set component = 'kubelet' -%}
{%- set component_bin_path = kubernetes.install_dir + '/kubelet' -%}
{%- from tplroot ~ "/vars.jinja" import
    k8s,
    node_role,
    package_flavor,
    apiserver_url, apiserver_healthz_url,
    kubelet_healthz_url, kubelet_container_runtime,
    kubernetes_ssl_cert_days_valid, kubernetes_ssl_cert_days_remaining,
    kubernetes_ca_cert_path,
    kube_admin_kubeconfig,
    component_ssl_cert_path, component_ssl_key_path,
    component_source, component_source_hash,
    component_kubeconfig
with context -%}
{%- from "common/vars.jinja" import
    node_fqdn, node_host, node_ip4
-%}
{%- set component_ssl_subject_CN = 'system:node:' + node_host -%}
{%- set component_ssl_subject_O  = 'system:nodes' -%}
{%- set component_ssl_subject_SAN = 'DNS:' + node_fqdn + ', DNS:' + node_host + ', IP:' + node_ip4 -%}
{%- from tplroot ~ "/macros.jinja" import
    kubeconfig,
    kubecomponentbinary
with context -%}
{%- from "ca/macros.jinja" import
    valid_certificate, certificate_private_key, certificate
-%}
{%- from "cni/vars.jinja" import
    cni_etc_dir, cni_network_name
-%}

include:
  - debian/packages/curl
  - debian/packages/jq
  - systemd/cmd
  - cni
{%- if salt['pkg.version_cmp'](kubernetes.source_version, 'v1.24.0') >= 0 %}
  - crictl.install
  - {{ kubelet_container_runtime[0] }}
{%- endif %}
  - .cmd
{% if node_role == 'node' %}
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
      - file: {{ cni_etc_dir }}/10-{{ cni_network_name }}.conf
    - require_in:
      - service: {{ component }}.service-enabled
    - watch_in:
      - module: systemctl-reload

{{ component }}-systemd-cgroups-drop-in-file:
  file.managed:
    - name: /etc/systemd/system/{{ component }}.service.d/10-cgroups.conf
    - source: salt://{{ tplroot }}/files/systemd/system/{{ component }}.service.d/10-cgroups.conf
    - makedirs: True
    - dir_mode: 755
    - require:
      - file: {{ component }}.service
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
    - require:
{% if node_role == 'node' %}
      - file: /etc/haproxy/haproxy.cfg
{% endif %}
      - service: kube-proxy.service-running

{% if node_role == 'master' %}
  {%- set label_node_role = 'master' if k8s.single_node_cluster != true else 'worker' %}
{{ component }}-is-ready:
  http.wait_for_successful_query:
    - name: {{ kubelet_healthz_url }}
    - wait_for: 30
    - request_interval: 1
    - status: 200
    - onchanges:
      - service: {{ component }}.service-running
    - require_in:
      - cmd: {{ component }}-label-node

{{ component }}-label-node:
  cmd.run:
    - name: kubectl label node {{ node_host }} node-role.kubernetes.io/control-plane= node-role.kubernetes.io/{{ label_node_role }}= --overwrite=true
    - onlyif:
      - curl --silent --output /dev/null {{ apiserver_healthz_url }}
      - kubectl get node {{ node_host }} -o json | jq -e '.metadata.labels | [has("node-role.kubernetes.io/control-plane"), has("node-role.kubernetes.io/{{ label_node_role }}")] | all | not'
    - require:
      - pkg: curl
      - pkg: jq
      - file: kubectl
      - file: {{ kube_admin_kubeconfig }}
{% endif %}

{{ valid_certificate(component, component_ssl_cert_path, kubernetes_ssl_cert_days_remaining) }}

{{ certificate_private_key(component, component_ssl_key_path, 'ec', 256) }}

{{ certificate(component, component_ssl_cert_path, component_ssl_key_path, 'kubernetes_ca', 'sha384', 'serverAuth, clientAuth', kubernetes_ssl_cert_days_valid, kubernetes_ssl_cert_days_remaining, component_ssl_subject_CN, component_ssl_subject_O, component_ssl_subject_SAN) }}
