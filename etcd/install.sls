{% from "etcd/map.jinja" import etcd with context %}

{% from "kubernetes/vars.jinja" import
    node_role, node_host, node_ip4,
    kubernetes_ssl_cert_days_valid, kubernetes_ssl_cert_days_remaining
with context %}

{% from "etcd/vars.jinja" import
    package_dir, package_source, package_source_hash,
    etcd_peers,
    etcd_etc_dir, etcd_ssl_dir,
    etcd_ca_cert_path, etcd_ca_key_path,
    etcd_ssl_cert_path, etcd_ssl_key_path,
    etcd_bin_path, etcdctl_bin_path
with context %}

include:
  - debian/packages/ca-certificates
{% if etcd.cluster.use_ssl %}
  - debian/packages/python3-m2crypto
  - debian/packages/python3-openssl
{% endif %}
  - systemd/cmd
  - kubernetes/cmd
  - flannel/cmd
  - .dirs

{% if etcd.cluster.use_ssl %}
etcd-ca.crt:
  x509.pem_managed:
    - name: {{ etcd_ca_cert_path }}
    - mode: 644
    - user: root
    - text: |
        {{ etcd.cluster.ca_cert|indent(8) }}
    - require:
      - pkg: python3-m2crypto
      - file: etcd-ssl-dir
    - require_in:
      - x509: etcd-ca.key

etcd-ca.key:
  x509.pem_managed:
    - name: {{ etcd_ca_key_path }}
    - mode: 600
    - user: root
    - text: |
        {{ etcd.cluster.ca_key|indent(8) }}
    - require:
      - pkg: python3-m2crypto
      - file: etcd-ssl-dir
    - require_in:
      - x509: etcd.crt
    - order: first

etcd-ca.key-delete:
  file.absent:
    - name: {{ etcd_ca_key_path }}
    - order: last

etcd.crt-validate:
  tls.valid_certificate:
    - name: {{ etcd_ssl_cert_path }}
    - days: {{ kubernetes_ssl_cert_days_remaining }}
    - require:
      - pkg: python3-openssl
    - onlyif:
      - test -f {{ etcd_ssl_cert_path }}

etcd.crt:
  x509.certificate_managed:
    - name: {{ etcd_ssl_cert_path }}
    - mode: 644
    - user: root
    - signing_cert: {{ etcd_ca_cert_path }}
    - signing_private_key: {{ etcd_ca_key_path }}
    - public_key: {{ etcd_ssl_key_path }}
    - CN: {{ node_host }}
    - basicConstraints: "CA:FALSE"
  {%- if node_role == 'master' %}
    - extendedKeyUsage: "clientAuth, serverAuth"
  {%- else %}
    - extendedKeyUsage: "clientAuth"
  {%- endif %}
    - keyUsage: "nonRepudiation, digitalSignature, keyEncipherment"
  {%- if node_role == 'master' %}
    - subjectAltName: "{% for peer in etcd_peers -%}
      IP:{{ peer['ip'] }}{% if not loop.last %}, {% endif %}
    {%- endfor %}"
  {%- else %}
    - subjectAltName: "IP:{{ node_ip4 }}"
  {%- endif %}
    - days_valid: {{ kubernetes_ssl_cert_days_valid }}
    - days_remaining: {{ kubernetes_ssl_cert_days_remaining }}
    - backup: True
    - require:
      - pkg: python3-m2crypto
  {%- if salt['file.file_exists'](etcd_ssl_cert_path) %}
    - onfail:
      - tls: etcd.crt-validate
  {%- endif %}
    - watch_in:
  {%- if node_role == 'master' %}
      - module: kube-apiserver-service-restart
  {%- endif %}
      - module: flannel-service-restart

etcd.key:
  x509.private_key_managed:
    - name: {{ etcd_ssl_key_path }}
    - bits: 2048
    - verbose: False
    - mode: 600
  {%- if node_role == 'master' %}
    - user: etcd
  {%- endif %}
    - require:
      - pkg: python3-m2crypto
  {%- if node_role == 'master' %}
      - user: etcd-user
  {%- endif %}
    - require_in:
      - x509: etcd.crt
{% endif %}

etcd-download:
  archive.extracted:
    - name: /tmp
    - source: {{ package_source }}
    - source_hash: {{ package_source_hash }}
    - archive_format: tar
    - options: v
    - user: nobody
    - group: nogroup
    - keep: True
    - if_missing: {{ package_dir }}
    - require:
      - pkg: ca-certificates

etcdctl:
  file.copy:
    - name: {{ etcdctl_bin_path }}
    - mode: 755
    - user: root
    - group: root
    - source: {{ package_dir }}/etcdctl
    - force: True
{% if salt['file.file_exists'](etcdctl_bin_path) %}
    - onchanges:
{% else %}
    - require:
{% endif %}
      - archive: etcd-download

{% if node_role == 'master' %}
etcd:
  file.copy:
    - name: {{ etcd_bin_path }}
    - mode: 755
    - user: root
    - source: {{ package_dir }}/etcd
    - force: True
    - require_in:
      - file: etcd-systemd-unit-file
  {%- if salt['file.file_exists'](etcd_bin_path) %}
    - onchanges:
  {%- else %}
    - require:
  {%- endif %}
      - archive: etcd-download

etcd-user:
  group.present:
    - name: etcd
    - system: True
    - require_in:
      - user: etcd-user
  user.present:
    - name: etcd
    - system: True
    - gid: etcd
    - home: /var/local/etcd
    - shell: /bin/false

etcd-systemd-unit-file:
  file.managed:
    - name: /lib/systemd/system/etcd.service
    - source: salt://etcd/files/systemd/system/etcd.service.j2
    - template: jinja
    - require:
      - user: etcd-user
  {%- if etcd.cluster.initial_cluster %}
    - require_in:
      - service: etcd-service-enable
  {%- endif %}
    - watch_in:
      - module: systemctl-reload

etcd-service-enable:
  service.enabled:
    - name: etcd
    - require_in:
      - service: etcd-service-running

etcd-service-running:
  service.running:
    - name: etcd
    - watch:
  {%- if etcd.cluster.use_ssl %}
      - x509: etcd.crt
      - x509: etcd.key
  {%- endif %}
      - file: etcd-systemd-unit-file
      - file: etcd
{% endif %}
