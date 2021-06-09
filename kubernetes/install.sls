{% from "kubernetes/map.jinja" import kubernetes with context %}
{% from "kubernetes/macros.jinja" import kubepackagedownload with context %}

{% from "kubernetes/vars.jinja" import
    cluster_nameservers, cluster_domain,
    node_role,
    package_flavor, package_dir, package_source, package_source_hash,
    kubernetes_ssl_cert_days_valid, kubernetes_ssl_cert_days_remaining,
    kubernetes_ca_cert_path, kubernetes_ca_key_path,
    kubernetes_sa_path, kubernetes_sa_pub_path,
    kubelet_client_ssl_cert_path, kubelet_client_ssl_key_path,
    kubelet_client_ssl_subject_CN, kubelet_client_ssl_subject_O,
    proxy_ca_cert_path, proxy_ca_key_path,
    proxy_client_ssl_cert_path, proxy_client_ssl_key_path,
    proxy_client_ssl_subject_CN, proxy_client_ssl_subject_O
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
sa.key:
  x509.pem_managed:
    - name: {{ kubernetes_sa_path }}
    - mode: 600
    - user: root
    - group: root
    - text: |
        {{ kubernetes.k8s.service_account_signing_key|indent(8) }}
    - require:
      - pkg: python3-m2crypto
      - file: kubernetes-etc-dir
    - order: first

sa.pub:
  file.managed:
    - name: {{ kubernetes_sa_pub_path }}
    - mode: 644
    - user: root
    - group: root
    - contents: |
        {{ kubernetes.k8s.service_account_key|indent(8) }}
    - require:
      - x509: sa.key
{% endif %}

{% if kubernetes.k8s.use_ssl %}
kubernetes-ca.crt:
  x509.pem_managed:
    - name: {{ kubernetes_ca_cert_path }}
    - mode: 644
    - user: root
    - group: root
    - text: |
        {{ kubernetes.k8s.ca_cert|indent(8) }}
    - require:
      - pkg: python3-m2crypto
      - file: kubernetes-ssl-dir
    - require_in:
      - x509: kubernetes-ca.key

kubernetes-ca.key:
  x509.pem_managed:
    - name: {{ kubernetes_ca_key_path }}
    - mode: 600
    - user: root
    - group: root
    - text: |
        {{ kubernetes.k8s.ca_key|indent(8) }}
    - require:
      - pkg: python3-m2crypto
      - file: kubernetes-ssl-dir
    - require_in:
  {%- if node_role == 'master' %}
      - x509: kube-apiserver.crt
      - x509: kube-controller-manager.crt
      - x509: kube-scheduler.crt
  {%- endif %}
      - x509: kubelet.crt
      - x509: kube-proxy.crt
    - order: first

  {%- if kubernetes.k8s.enable_cert_issuer == False %}
kubernetes-ca.key-delete:
  file.absent:
    - name: {{ kubernetes_ca_key_path }}
    - order: last
  {%- endif %}

  {%- if node_role == 'master' %}
kubelet-client.crt-validate:
  tls.valid_certificate:
    - name: {{ kubelet_client_ssl_cert_path }}
    - days: {{ kubernetes_ssl_cert_days_remaining }}
    - require:
      - pkg: python3-openssl
    - onlyif:
      - test -f {{ kubelet_client_ssl_cert_path }}

kubelet-client.crt:
  x509.certificate_managed:
    - name: {{ kubelet_client_ssl_cert_path }}
    - mode: 644
    - user: root
    - signing_cert: {{ kubernetes_ca_cert_path }}
    - signing_private_key: {{ kubernetes_ca_key_path }}
    - public_key: {{ kubelet_client_ssl_key_path }}
    - CN: {{ kubelet_client_ssl_subject_CN }}
    - O: {{ kubelet_client_ssl_subject_O }}
    - basicConstraints: "CA:FALSE"
    - extendedKeyUsage: "clientAuth"
    - keyUsage: "nonRepudiation, digitalSignature, keyEncipherment"
    - days_valid: {{ kubernetes_ssl_cert_days_valid }}
    - days_remaining: {{ kubernetes_ssl_cert_days_remaining }}
    - backup: True
    - require:
      - pkg: python3-m2crypto
    {%- if salt['file.file_exists'](kubelet_client_ssl_cert_path) %}
    - onfail:
      - tls: kubelet-client.crt-validate
    {%- endif %}

kubelet-client.key:
  x509.private_key_managed:
    - name: {{ kubelet_client_ssl_key_path }}
    - bits: 2048
    - verbose: False
    - mode: 600
    - require:
      - pkg: python3-m2crypto
    - require_in:
      - x509: kubelet-client.crt

    {%- if salt['pkg.version_cmp'](kubernetes.source_version, 'v1.13.0') >= 0 %}
proxy-ca.crt:
  x509.pem_managed:
    - name: {{ proxy_ca_cert_path }}
    - mode: 644
    - user: root
    - group: root
    - text: |
        {{ kubernetes.k8s.proxy_ca_cert|indent(8) }}
    - require:
      - pkg: python3-m2crypto
      - file: kubernetes-ssl-dir
    - require_in:
      - x509: proxy-ca.key

proxy-ca.key:
  x509.pem_managed:
    - name: {{ proxy_ca_key_path }}
    - mode: 600
    - user: root
    - group: root
    - text: |
        {{ kubernetes.k8s.proxy_ca_key|indent(8) }}
    - require:
      - pkg: python3-m2crypto
      - file: kubernetes-ssl-dir
    - require_in:
      - x509: proxy-client.crt

proxy-ca.key-delete:
  file.absent:
    - name: {{ proxy_ca_key_path }}
    - order: last

proxy-client.crt-validate:
  tls.valid_certificate:
    - name: {{ proxy_client_ssl_cert_path }}
    - days: {{ kubernetes_ssl_cert_days_remaining }}
    - require:
      - pkg: python3-openssl
    - onlyif:
      - test -f {{ proxy_client_ssl_cert_path }}

proxy-client.crt:
  x509.certificate_managed:
    - name: {{ proxy_client_ssl_cert_path }}
    - mode: 644
    - user: root
    - signing_cert: {{ proxy_ca_cert_path }}
    - signing_private_key: {{ proxy_ca_key_path }}
    - public_key: {{ proxy_client_ssl_key_path }}
    - CN: {{ proxy_client_ssl_subject_CN }}
    - basicConstraints: "CA:FALSE"
    - extendedKeyUsage: "clientAuth"
    - keyUsage: "nonRepudiation, digitalSignature, keyEncipherment"
    - days_valid: {{ kubernetes_ssl_cert_days_valid }}
    - days_remaining: {{ kubernetes_ssl_cert_days_remaining }}
    - backup: True
    - require:
      - pkg: python3-m2crypto
      {%- if salt['file.file_exists'](proxy_client_ssl_cert_path) %}
    - onfail:
      - tls: proxy-client.crt-validate
      {%- endif %}

proxy-client.key:
  x509.private_key_managed:
    - name: {{ proxy_client_ssl_key_path }}
    - bits: 2048
    - verbose: False
    - mode: 600
    - require:
      - pkg: python3-m2crypto
    - require_in:
      - x509: proxy-client.crt
    {%- endif %}
  {%- endif %}
{% endif %}

{{ kubepackagedownload(package_dir, package_source, package_source_hash, package_flavor) }}

{% if kubernetes.k8s.cluster_dns.override_resolvconf %}
kubernetes-resolv.conf:
  file.managed:
    - name: /etc/resolv.conf
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
