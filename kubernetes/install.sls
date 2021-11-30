{% from "kubernetes/map.jinja" import kubernetes with context %}
{% from "kubernetes/macros.jinja" import
    kubepackagedownload,
    kubepkicertvalid, kubepkicert, kubepkikey
with context %}

{% from "kubernetes/vars.jinja" import
    cluster_nameservers, cluster_domain,
    node_role,
    package_flavor, package_dir, package_source, package_source_hash,
    kubernetes_ssl_dir,
    kubernetes_ssl_cert_days_valid, kubernetes_ssl_cert_days_remaining,
    kubernetes_ca_cert_path, kubernetes_ca_key_path,
    kubernetes_sa_key_path, kubernetes_sa_pub_path,
    kubelet_client_ssl_cert_path, kubelet_client_ssl_key_path,
    kubelet_client_ssl_subject_CN, kubelet_client_ssl_subject_O,
    front_proxy_ca_cert_path, front_proxy_ca_key_path,
    front_proxy_client_ssl_cert_path, front_proxy_client_ssl_key_path,
    front_proxy_client_ssl_subject_CN, front_proxy_client_ssl_subject_O
with context %}

include:
{% if kubernetes.k8s.cluster_dns.override_resolvconf %}
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
  - .kubelet
  - .proxy

{% if node_role == 'master' %}
{{ kubernetes_sa_key_path }}:
  x509.pem_managed:
    - mode: 600
    - user: root
    - group: root
    - text: |
        {{ kubernetes.k8s.service_account_signing_key|indent(8) }}
    - require:
      - pkg: python3-m2crypto
      - file: {{ kubernetes_ssl_dir }}
    - order: first

{{ kubernetes_sa_pub_path }}:
  file.managed:
    - mode: 644
    - user: root
    - group: root
    - contents: |
        {{ kubernetes.k8s.service_account_key|indent(8) }}
    - require:
      - x509: {{ kubernetes_sa_key_path }}
{% endif %}

{{ kubernetes_ca_cert_path }}:
  x509.pem_managed:
    - mode: 644
    - user: root
    - group: root
    - text: |
        {{ kubernetes.k8s.ca_cert|indent(8) }}
    - require:
      - pkg: python3-m2crypto
      - file: {{ kubernetes_ssl_dir }}
    - require_in:
      - x509: {{ kubernetes_ca_key_path }}

{{ kubernetes_ca_key_path }}:
  x509.pem_managed:
    - mode: 600
    - user: root
    - group: root
    - text: |
        {{ kubernetes.k8s.ca_key|indent(8) }}
    - require:
      - pkg: python3-m2crypto
      - file: {{ kubernetes_ssl_dir }}
    - require_in:
{%- if node_role == 'master' %}
      - x509: kube-apiserver.crt
      - x509: kube-controller-manager.crt
      - x509: kube-scheduler.crt
{%- endif %}
      - x509: kubelet.crt
      - x509: kube-proxy.crt
    - order: first

{%- if node_role == 'node' or kubernetes.k8s.enable_cert_issuer == False %}
{{ kubernetes_ca_key_path }}-deleted:
  file.absent:
    - name: {{ kubernetes_ca_key_path }}
    - order: last
{%- endif %}

{%- if node_role == 'master' %}
{{ kubepkicertvalid('apiserver-kubelet-client', kubelet_client_ssl_cert_path, kubernetes_ssl_cert_days_remaining) }}

{{ kubepkicert('apiserver-kubelet-client', kubelet_client_ssl_cert_path, kubelet_client_ssl_key_path, kubernetes_ca_cert_path, kubernetes_ca_key_path, 'clientAuth', kubernetes_ssl_cert_days_valid, kubernetes_ssl_cert_days_remaining, kubelet_client_ssl_subject_CN, kubelet_client_ssl_subject_O) }}

{{ kubepkikey('apiserver-kubelet-client', kubelet_client_ssl_key_path) }}

{{ front_proxy_ca_cert_path }}:
  x509.pem_managed:
    - mode: 644
    - user: root
    - group: root
    - text: |
        {{ kubernetes.k8s.front_proxy_ca_cert|indent(8) }}
    - require:
      - pkg: python3-m2crypto
      - file: {{ kubernetes_ssl_dir }}
    - require_in:
      - x509: {{ front_proxy_ca_key_path }}

{{ front_proxy_ca_key_path }}:
  x509.pem_managed:
    - mode: 600
    - user: root
    - group: root
    - text: |
        {{ kubernetes.k8s.front_proxy_ca_key|indent(8) }}
    - require:
      - pkg: python3-m2crypto
      - file: {{ kubernetes_ssl_dir }}
    - require_in:
      - x509: front-proxy-client.crt

{{ front_proxy_ca_key_path }}-deleted:
  file.absent:
    - name: {{ front_proxy_ca_key_path }}
    - order: last

{{ kubepkicertvalid('front-proxy-client', front_proxy_client_ssl_cert_path, kubernetes_ssl_cert_days_remaining) }}

{{ kubepkicert('front-proxy-client', front_proxy_client_ssl_cert_path, front_proxy_client_ssl_key_path, front_proxy_ca_cert_path, front_proxy_ca_key_path, 'clientAuth', kubernetes_ssl_cert_days_valid, kubernetes_ssl_cert_days_remaining, front_proxy_client_ssl_subject_CN) }}

{{ kubepkikey('front-proxy-client', front_proxy_client_ssl_key_path) }}
{%- endif %}

{{ kubepackagedownload(package_dir, package_source, package_source_hash, package_flavor) }}

{% if kubernetes.k8s.cluster_dns.override_resolvconf %}
/etc/resolv.conf:
  file.managed:
    - source: salt://kubernetes/files/resolv.conf.j2
    - template: jinja
    - context:
        cluster_nameservers: {{ cluster_nameservers }}
        cluster_domain: {{ cluster_domain }}
    - require:
      - file: dhclient-nodnsupdate
    - require_in:
      - file: kubelet
{% endif %}
