{%- set tplroot = tpldir.split('/')[0] -%}
{%- from tplroot ~ "/vars.jinja" import
    k8s,
    cluster_dns,
    node_role,
    package_flavor, package_dir, package_source, package_source_hash,
    apiserver_url,
    kubernetes_ssl_dir,
    kubernetes_ssl_cert_days_valid, kubernetes_ssl_cert_days_remaining,
    kubernetes_ca_cert_path,
    kubernetes_sa_key_path, kubernetes_sa_pub_path,
    kubernetes_root_ca_file,
    apiserver_etcd_client_ssl_cert_path, apiserver_etcd_client_ssl_key_path,
    apiserver_etcd_client_ssl_subject_CN,
    kubelet_client_ssl_cert_path, kubelet_client_ssl_key_path,
    kubelet_client_ssl_subject_CN, kubelet_client_ssl_subject_O,
    kube_admin_kubeconfig_dir, kube_admin_kubeconfig,
    kube_admin_ssl_cert_path, kube_admin_ssl_key_path,
    kube_admin_ssl_subject_CN, kube_admin_ssl_subject_O,
    front_proxy_ca_cert_path,
    front_proxy_client_ssl_cert_path, front_proxy_client_ssl_key_path,
    front_proxy_client_ssl_subject_CN, front_proxy_client_ssl_subject_O
with context -%}
{%- from tplroot ~ "/macros.jinja" import
    kubeconfig,
    kubepackagedownload
with context -%}
{%- from "ca/vars.jinja" import
    ca_server, ca_pki_dir
-%}
{%- from "ca/macros.jinja" import
    valid_certificate, certificate_private_key, certificate
-%}

include:
{% if cluster_dns.override_host_resolvconf %}
  - debian/dhclient/nodnsupdate
{% endif %}
  - debian/packages/ca-certificates
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

/usr/local/share/ca-certificates/internal-root-ca.crt:
  x509.pem_managed:
    - text: {{ salt['mine.get'](ca_server, 'CA.crt')[ca_server][ca_pki_dir + '/CA.crt']|replace('\n', '') }}
    - require:
      - pkg: ca-certificates
    - watch_in:
      - cmd: update-ca-certificates

{{ kubernetes_ca_cert_path }}:
  x509.pem_managed:
    - text: {{ salt['mine.get'](ca_server, 'KubernetesCA.crt')[ca_server][ca_pki_dir + '/KubernetesCA.crt']|replace('\n', '') }}
    - require:
      - file: {{ kubernetes_ssl_dir }}

{{ kubernetes_root_ca_file }}:
  file.managed:
    - contents: |
        {{ salt['mine.get'](ca_server, 'KubernetesCA.crt')[ca_server][ca_pki_dir + '/KubernetesCA.crt']|indent(8) }}

        {{ salt['mine.get'](ca_server, 'CA.crt')[ca_server][ca_pki_dir + '/CA.crt']|indent(8) }}
    - require:
      - file: {{ kubernetes_ssl_dir }}

{%- if node_role == 'master' %}
{{ valid_certificate('apiserver-etcd-client', apiserver_etcd_client_ssl_cert_path, kubernetes_ssl_cert_days_remaining) }}

{{ certificate_private_key('apiserver-etcd-client', apiserver_etcd_client_ssl_key_path, 'ec', 256) }}

{{ certificate('apiserver-etcd-client', apiserver_etcd_client_ssl_cert_path, apiserver_etcd_client_ssl_key_path, 'etcd_ca', 'sha384', 'clientAuth', kubernetes_ssl_cert_days_valid, kubernetes_ssl_cert_days_remaining, apiserver_etcd_client_ssl_subject_CN) }}

{{ valid_certificate('apiserver-kubelet-client', kubelet_client_ssl_cert_path, kubernetes_ssl_cert_days_remaining) }}

{{ certificate_private_key('apiserver-kubelet-client', kubelet_client_ssl_key_path, 'ec', 256) }}

{{ certificate('apiserver-kubelet-client', kubelet_client_ssl_cert_path, kubelet_client_ssl_key_path, 'kubernetes_ca', 'sha384', 'clientAuth', kubernetes_ssl_cert_days_valid, kubernetes_ssl_cert_days_remaining, kubelet_client_ssl_subject_CN, kubelet_client_ssl_subject_O) }}

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

{{ valid_certificate('kube-admin', kube_admin_ssl_cert_path, kubernetes_ssl_cert_days_remaining) }}

{{ certificate_private_key('kube-admin', kube_admin_ssl_key_path, 'ec', 256) }}

{{ certificate('kube-admin', kube_admin_ssl_cert_path, kube_admin_ssl_key_path, 'kubernetes_ca', 'sha384', 'clientAuth', kubernetes_ssl_cert_days_valid, kubernetes_ssl_cert_days_remaining, kube_admin_ssl_subject_CN, kube_admin_ssl_subject_O) }}

{{ front_proxy_ca_cert_path }}:
  x509.pem_managed:
    - text: {{ salt['mine.get'](ca_server, 'KubernetesProxyCA.crt')[ca_server][ca_pki_dir + '/KubernetesProxyCA.crt']|replace('\n', '') }}
    - require:
      - file: {{ kubernetes_ssl_dir }}

{{ valid_certificate('front-proxy-client', front_proxy_client_ssl_cert_path, kubernetes_ssl_cert_days_remaining) }}

{{ certificate_private_key('front-proxy-client', front_proxy_client_ssl_key_path, 'ec', 256) }}

{{ certificate('front-proxy-client', front_proxy_client_ssl_cert_path, front_proxy_client_ssl_key_path, 'kubernetes_front_proxy_ca', 'sha384', 'clientAuth', kubernetes_ssl_cert_days_valid, kubernetes_ssl_cert_days_remaining, front_proxy_client_ssl_subject_CN) }}
{%- endif %}

{{ kubepackagedownload(package_dir, package_source, package_source_hash, package_flavor) }}

{% if cluster_dns.override_host_resolvconf %}
/etc/resolv.conf:
  file.managed:
    - source: salt://{{ tplroot }}//files/resolv.conf.j2
    - template: jinja
    - context:
        tpldir: {{ tpldir }}
        tplroot: {{ tplroot }}
    - require:
      - file: dhclient-nodnsupdate
  {%- if node_role in ['master', 'node'] %}
    - require_in:
      - file: kubelet
  {%- endif %}
{% endif %}
