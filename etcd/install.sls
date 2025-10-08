{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import etcd with context -%}
{%- from tplroot ~ "/vars.jinja" import
    package_dir, package_source, package_source_hash,
    etcd_ssl_dir,
    etcd_data_dir,
    etcd_ca_cert_path, etcd_ca_key_path,
    etcd_ssl_cert_path, etcd_ssl_key_path,
    etcd_bin_path, etcdctl_bin_path
with context -%}
{%- from "kubernetes/vars.jinja" import
    k8s,
    node_role,
    kubernetes_ssl_dir,
    kubernetes_ca_cert_path, kubernetes_ca_key_path,
    kubernetes_ssl_cert_days_valid, kubernetes_ssl_cert_days_remaining
-%}
{%- from "common/vars.jinja" import
    node_host, node_ip4,
    nobody_groupname
-%}
{%- set etcd_user = 'etcd' if node_role == 'master' else '' -%}
{%- set etcd_ssl_key_usage = 'clientAuth, serverAuth' if node_role == 'master' else 'clientAuth' -%}
{%- set etcd_ssl_subject_CN = node_host -%}
{%- set etcd_ssl_subject_O = None -%}
{%- set etcd_ssl_subject_SAN = 'DNS:localhost, IP:127.0.0.1, DNS:' + node_host + ', IP:' + node_ip4 -%}
{%- from "kubernetes/macros.jinja" import
    kubepkicertvalid, kubepkicert, kubepkikey
-%}

include:
  - debian/packages/ca-certificates
  - systemd/cmd
  - kubernetes/cmd
{%- if k8s.single_node_cluster != true %}
  - flannel/cmd
{%- endif %}
  - .dirs

etcd.ca-cert:
  x509.pem_managed:
    - name: {{ etcd_ca_cert_path }}
    - mode: 644
    - user: root
    - text: |
{%- if etcd.cluster.ca_cert %}
        {{ etcd.cluster.ca_cert|indent(8) }}
{%- else %}
        {{ k8s.ca_cert|indent(8) }}
{%- endif %}
    - require:
{%- if etcd.cluster.ca_cert != '' %}
      - file: {{ kubernetes_ssl_dir }}
{%- endif %}
      - file: {{ etcd_ssl_dir }}
    - require_in:
      - x509: etcd.ca-key

etcd.ca-key:
  x509.pem_managed:
    - name: {{ etcd_ca_key_path }}
    - mode: 600
    - user: root
    - text: |
{%- if etcd.cluster.ca_key %}
        {{ etcd.cluster.ca_key|indent(8) }}
{%- else %}
        {{ k8s.ca_key|indent(8) }}
{%- endif %}
    - require:
{%- if etcd.cluster.ca_cert != '' %}
      - file: {{ kubernetes_ssl_dir }}
{%- endif %}
      - file: {{ etcd_ssl_dir }}
    - require_in:
      - x509: etcd.crt
    - order: first

{%- if node_role in ['node', 'node-proxier'] %}
{{ etcd_ca_key_path }}-delete:
  file.absent:
    - name: {{ etcd_ca_key_path }}
    - order: last
{%- endif %}

{{ kubepkicertvalid('etcd', etcd_ssl_cert_path, kubernetes_ssl_cert_days_remaining) }}

{{ kubepkicert('etcd', etcd_ssl_cert_path, etcd_ssl_key_path, etcd_ca_cert_path, etcd_ca_key_path, etcd_ssl_key_usage, kubernetes_ssl_cert_days_valid, kubernetes_ssl_cert_days_remaining, etcd_ssl_subject_CN, etcd_ssl_subject_O, etcd_ssl_subject_SAN) }}

{{ kubepkikey('etcd', etcd_ssl_key_path, etcd_user) }}

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
      - user: etcd-user
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
