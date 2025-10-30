{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import etcd with context -%}
{%- from tplroot ~ "/vars.jinja" import
    package_dir, package_source, package_source_hash,
    etcd_ssl_dir,
    etcd_data_dir,
    etcd_ca_cert_path,
    etcd_ssl_cert_path, etcd_ssl_key_path,
    etcd_peer_ca_cert_path,
    etcd_peer_ssl_cert_path, etcd_peer_ssl_key_path,
    etcd_bin_path, etcdctl_bin_path
with context -%}
{%- from "kubernetes/vars.jinja" import
    k8s,
    node_role,
    kubernetes_ssl_cert_days_valid, kubernetes_ssl_cert_days_remaining
-%}
{%- from "common/vars.jinja" import
    node_host, node_ip4,
    nobody_groupname
-%}
{%- set etcd_user = 'etcd' if node_role == 'master' else '' -%}
{%- set etcd_ssl_key_usage = 'clientAuth, serverAuth' if node_role == 'master' else 'clientAuth' -%}
{%- set etcd_ssl_subject_CN = 'kube-etcd' -%}
{%- set etcd_peer_ssl_subject_CN = 'kube-etcd-peer' -%}
{%- set etcd_ssl_subject_O = None -%}
{%- set etcd_ssl_subject_SAN = 'DNS:localhost, IP:127.0.0.1, DNS:' + node_host + ', IP:' + node_ip4 -%}
{%- from "ca/vars.jinja" import
    ca_server, ca_pki_dir
-%}
{%- from "ca/macros.jinja" import
    valid_certificate, certificate_private_key, certificate
-%}

include:
  - debian/packages/ca-certificates
  - systemd/cmd
  - kubernetes/cmd
{%- if k8s.single_node_cluster != true %}
  - flannel/cmd
{%- endif %}
  - .dirs

etcd/ca.crt:
  x509.pem_managed:
    - name: {{ etcd_ca_cert_path }}
    - text: {{ salt['mine.get'](ca_server, 'etcdCA.crt')[ca_server][ca_pki_dir + '/etcdCA.crt']|replace('\n', '') }}
    - require:
      - file: {{ etcd_ssl_dir }}

etcd/peerca.crt:
  x509.pem_managed:
    - name: {{ etcd_peer_ca_cert_path }}
    - text: {{ salt['mine.get'](ca_server, 'etcdpeerCA.crt')[ca_server][ca_pki_dir + '/etcdpeerCA.crt']|replace('\n', '') }}
    - require:
      - file: {{ etcd_ssl_dir }}

{{ valid_certificate('etcd', etcd_ssl_cert_path, kubernetes_ssl_cert_days_remaining) }}

{{ certificate_private_key('etcd', etcd_ssl_key_path, 'ec', 256, etcd_user) }}

{% set watch_in_modules = [] %}
{%- if node_role == 'master' -%}
    {%- set _ = watch_in_modules.append('kube-apiserver.service-restart') -%}
{%- endif -%}
{%- if k8s.single_node_cluster != true %}
    {%- set _ = watch_in_modules.append('flannel.service-restart') -%}
{%- endif -%}

{{ certificate('etcd', etcd_ssl_cert_path, etcd_ssl_key_path, 'etcd_ca', 'sha384', etcd_ssl_key_usage, kubernetes_ssl_cert_days_valid, kubernetes_ssl_cert_days_remaining, etcd_ssl_subject_CN, etcd_ssl_subject_O, etcd_ssl_subject_SAN) }}

{{ valid_certificate('etcd-peer', etcd_peer_ssl_cert_path, kubernetes_ssl_cert_days_remaining) }}

{{ certificate_private_key('etcd-peer', etcd_peer_ssl_key_path, 'ec', 256, etcd_user) }}

{% set watch_in_modules = [] %}
{{ certificate('etcd-peer', etcd_peer_ssl_cert_path, etcd_peer_ssl_key_path, 'etcd_peer_ca', 'sha384', etcd_ssl_key_usage, kubernetes_ssl_cert_days_valid, kubernetes_ssl_cert_days_remaining, etcd_peer_ssl_subject_CN, etcd_ssl_subject_O, etcd_ssl_subject_SAN) }}

etcd-download:
  archive.extracted:
    - name: /tmp
    - source: {{ package_source }}
    - source_hash: {{ package_source_hash }}
    - archive_format: tar
    - options: v
    - user: nobody
    - group: {{ nobody_groupname }}
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
{%- if salt['file.file_exists'](etcdctl_bin_path) %}
    - onchanges:
{%- else %}
    - require:
{%- endif %}
      - archive: etcd-download

{%- if node_role == 'master' %}
etcd:
  file.copy:
    - name: {{ etcd_bin_path }}
    - mode: 755
    - user: root
    - source: {{ package_dir }}/etcd
    - force: True
    - require_in:
      - file: etcd.service
  {%- if salt['file.file_exists'](etcd_bin_path) %}
    - onchanges:
  {%- else %}
    - require:
  {%- endif %}
      - archive: etcd-download
  group.present:
    - name: etcd
    - system: True
    - require_in:
      - user: etcd
  user.present:
    - name: etcd
    - system: True
    - gid: etcd
    - home: {{ etcd_data_dir }}
    - shell: /bin/false

etcd.service:
  file.managed:
    - name: /lib/systemd/system/etcd.service
    - source: salt://{{ tplroot }}/files/systemd/system/etcd.service.j2
    - template: jinja
    - context:
        tpldir: {{ tpldir }}
        tplroot: {{ tplroot }}
    - require:
      - user: etcd
  {%- if etcd.cluster.initial_cluster %}
    - require_in:
      - service: etcd.service-enabled
  {%- endif %}
    - watch_in:
      - module: systemctl-reload

etcd.service-enabled:
  service.enabled:
    - name: etcd
    - require_in:
      - service: etcd.service-running

etcd.service-running:
  service.running:
    - name: etcd
    - watch:
      - x509: etcd.crt
      - x509: etcd.key
      - file: etcd.service
      - file: etcd
{%- endif %}
