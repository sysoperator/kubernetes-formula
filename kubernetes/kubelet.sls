{% from "kubernetes/map.jinja" import kubernetes with context %}
{% from "kubernetes/macros.jinja" import
    kubecomponentbinary,
    kubepkicertvalid, kubepkicert, kubepkikey
with context %}

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

{% from "cni/vars.jinja" import
    cni_etc_dir
with context %}

include:
  - systemd/cmd
  - cni
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
      - file: {{ cni_etc_dir }}/10-bridge.conf
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

{{ component }}-kubeconfig:
  file.managed:
    - name: {{ kubernetes_etc_dir }}/{{ component }}.kubeconfig
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
{% if node_role == 'node' %}
      - file: haproxy.cfg
{% endif %}
      - service: kube-proxy-service-running

{{ kubepkicertvalid(component, component_ssl_cert_path, kubernetes_ssl_cert_days_remaining) }}

{{ kubepkicert(component, component_ssl_cert_path, component_ssl_key_path, kubernetes_ca_cert_path, kubernetes_ca_key_path, 'clientAuth', kubernetes_ssl_cert_days_valid, kubernetes_ssl_cert_days_remaining, component_ssl_subject_CN, component_ssl_subject_O) }}

{{ kubepkikey(component, component_ssl_key_path) }}
