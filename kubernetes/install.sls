{%- set tplroot = tpldir.split('/')[0] -%}
{%- from tplroot ~ "/vars.jinja" import
    k8s,
    cluster_dns,
    node_role,
    package_flavor, package_dir, package_source, package_source_hash,
    apiserver_url,
    kubernetes_ssl_dir,
    kubernetes_ssl_cert_days_valid, kubernetes_ssl_cert_days_remaining,
    kubernetes_fullchain_ca_cert_path,
    kubernetes_ca_cert_path, kubernetes_ca_key_path,
    kubernetes_sa_key_path, kubernetes_sa_pub_path,
    kubelet_client_ssl_cert_path, kubelet_client_ssl_key_path,
    kubelet_client_ssl_subject_CN, kubelet_client_ssl_subject_O,
    kube_admin_kubeconfig_dir, kube_admin_kubeconfig,
    kube_admin_ssl_cert_path, kube_admin_ssl_key_path,
    kube_admin_ssl_subject_CN, kube_admin_ssl_subject_O,
    front_proxy_ca_cert_path, front_proxy_ca_key_path,
    front_proxy_client_ssl_cert_path, front_proxy_client_ssl_key_path,
    front_proxy_client_ssl_subject_CN, front_proxy_client_ssl_subject_O
with context -%}
{%- from tplroot ~ "/macros.jinja" import
    kubeconfig,
    kubepackagedownload,
    kubepkicertvalid, kubepkicert, kubepkikey
with context -%}
{%- from "debian/packages/macros.jinja" import
    Python3_M2Crypto
-%}

include:
{% if cluster_dns.override_resolvconf %}
  - debian/dhclient/nodnsupdate
{% endif %}
  - debian/packages/ca-certificates
  - debian/packages/python3-m2crypto
  - debian/packages/python3-openssl
  - systemd/cmd
  - .dirs
{% if node_role == 'master' %}
  - .apiserver
  - .controller-manager
  - .scheduler
  - .kubectl
{% endif %}
{% if node_role in ['master', 'node'] %}
  - .kubelet
{% endif %}
  - .proxy

{% if node_role == 'master' %}
{{ kubernetes_sa_key_path }}:
  x509.pem_managed:
    - mode: 600
    - user: root
    - group: root
    - text: |
        {{ k8s.service_account_signing_key|indent(8) }}
    - require:
{{ Python3_M2Crypto() }}
      - file: {{ kubernetes_ssl_dir }}
    - order: first

{{ kubernetes_sa_pub_path }}:
  file.managed:
    - mode: 644
    - user: root
    - group: root
    - contents: |
        {{ k8s.service_account_key|indent(8) }}
    - require:
      - x509: {{ kubernetes_sa_key_path }}
{% endif %}

{%- if k8s.root_ca_cert %}
/usr/local/share/ca-certificates/root.crt:
  x509.pem_managed:
    - mode: 644
    - user: root
    - group: root
    - text: |
        {{ k8s.root_ca_cert|indent(8) }}
    - require:
{{ Python3_M2Crypto() }}
      - pkg: ca-certificates
    - watch_in:
      - cmd: update-ca-certificates

  {%- if node_role == 'master' %}
{{ kubernetes_fullchain_ca_cert_path }}:
  file.managed:
    - mode: 644
    - user: root
    - group: root
    - contents: |
        {{ k8s.ca_cert|indent(8) }}
        {{ k8s.root_ca_cert|indent(8) }}
    - require:
      - file: {{ kubernetes_ssl_dir }}
  {%- endif %}
{%- endif %}

{{ kubernetes_ca_cert_path }}:
  x509.pem_managed:
    - mode: 644
    - user: root
    - group: root
    - text: |
        {{ k8s.ca_cert|indent(8) }}
    - require:
{{ Python3_M2Crypto() }}
      - file: {{ kubernetes_ssl_dir }}
    - require_in:
      - x509: {{ kubernetes_ca_key_path }}

{{ kubernetes_ca_key_path }}:
  x509.pem_managed:
    - mode: 600
    - user: root
    - group: root
    - text: |
        {{ k8s.ca_key|indent(8) }}
    - require:
{{ Python3_M2Crypto() }}
      - file: {{ kubernetes_ssl_dir }}
    - require_in:
{%- if node_role == 'master' %}
      - x509: kube-apiserver.crt
      - x509: kube-controller-manager.crt
      - x509: kube-scheduler.crt
      - x509: apiserver-kubelet-client.crt
      - x509: kube-admin.crt
      - x509: kubelet.crt
  {%- if not k8s.front_proxy_ca_cert %}
      - x509: front-proxy-client.crt
  {%- endif %}
{%- elif node_role == 'node' %}
      - x509: kubelet.crt
{%- endif %}
      - x509: kube-proxy.crt
    - order: first

{%- if node_role == 'node' or k8s.x509_signers_enabled == False %}
{{ kubernetes_ca_key_path }}-deleted:
  file.absent:
    - name: {{ kubernetes_ca_key_path }}
    - order: last
{%- endif %}

{%- if node_role == 'master' %}
{{ kubepkicertvalid('apiserver-kubelet-client', kubelet_client_ssl_cert_path, kubernetes_ssl_cert_days_remaining) }}

{{ kubepkicert('apiserver-kubelet-client', kubelet_client_ssl_cert_path, kubelet_client_ssl_key_path, kubernetes_ca_cert_path, kubernetes_ca_key_path, 'clientAuth', kubernetes_ssl_cert_days_valid, kubernetes_ssl_cert_days_remaining, kubelet_client_ssl_subject_CN, kubelet_client_ssl_subject_O) }}

{{ kubepkikey('apiserver-kubelet-client', kubelet_client_ssl_key_path) }}

{{ kube_admin_kubeconfig }}:
  file.managed:
    - mode: 600
    - user: root
    - group: root
    - contents: |
        {{ kubeconfig('kube-admin', apiserver_url, kubernetes_ca_cert_path, kube_admin_ssl_cert_path, kube_admin_ssl_key_path)|indent(8) }}
    - require:
      - file: {{ kube_admin_kubeconfig_dir }}
      - x509: kube-admin.crt

{{ kubepkicertvalid('kube-admin', kube_admin_ssl_cert_path, kubernetes_ssl_cert_days_remaining) }}

{{ kubepkicert('kube-admin', kube_admin_ssl_cert_path, kube_admin_ssl_key_path, kubernetes_ca_cert_path, kubernetes_ca_key_path, 'clientAuth', kubernetes_ssl_cert_days_valid, kubernetes_ssl_cert_days_remaining, kube_admin_ssl_subject_CN, kube_admin_ssl_subject_O) }}

{{ kubepkikey('kube-admin', kube_admin_ssl_key_path) }}

{%- if k8s.front_proxy_ca_cert %}
{{ front_proxy_ca_cert_path }}:
  x509.pem_managed:
    - mode: 644
    - user: root
    - group: root
    - text: |
        {{ k8s.front_proxy_ca_cert|indent(8) }}
    - require:
{{ Python3_M2Crypto() }}
      - file: {{ kubernetes_ssl_dir }}
    - require_in:
      - x509: {{ front_proxy_ca_key_path }}

{{ front_proxy_ca_key_path }}:
  x509.pem_managed:
    - mode: 600
    - user: root
    - group: root
    - text: |
        {{ k8s.front_proxy_ca_key|indent(8) }}
    - require:
{{ Python3_M2Crypto() }}
      - file: {{ kubernetes_ssl_dir }}
    - require_in:
      - x509: front-proxy-client.crt

{{ front_proxy_ca_key_path }}-deleted:
  file.absent:
    - name: {{ front_proxy_ca_key_path }}
    - order: last
{%- endif %}

{{ kubepkicertvalid('front-proxy-client', front_proxy_client_ssl_cert_path, kubernetes_ssl_cert_days_remaining) }}

{{ kubepkicert('front-proxy-client', front_proxy_client_ssl_cert_path, front_proxy_client_ssl_key_path, front_proxy_ca_cert_path, front_proxy_ca_key_path, 'clientAuth', kubernetes_ssl_cert_days_valid, kubernetes_ssl_cert_days_remaining, front_proxy_client_ssl_subject_CN) }}

{{ kubepkikey('front-proxy-client', front_proxy_client_ssl_key_path) }}
{%- endif %}

{{ kubepackagedownload(package_dir, package_source, package_source_hash, package_flavor) }}

{% if cluster_dns.override_resolvconf %}
/etc/resolv.conf:
  file.managed:
    - source: salt://{{ tplroot }}//files/resolv.conf.j2
    - template: jinja
    - context:
        tplroot: {{ tplroot }}
    - require:
      - file: dhclient-nodnsupdate
  {%- if node_role in ['master', 'node'] %}
    - require_in:
      - file: kubelet
  {%- endif %}
{% endif %}
