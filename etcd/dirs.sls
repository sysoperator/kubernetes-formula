{% from "etcd/map.jinja" import etcd with context %}

{% from "etcd/vars.jinja" import
    etcd_etc_dir, etcd_ssl_dir
with context %}

etcd-etc-dir:
  file.directory:
    - name: {{ etcd_etc_dir }}
    - dir_mode: 755
    - user: root
    - makedirs: True
{% if etcd.cluster.use_ssl%}
    - require_in:
      - file: etcd-ssl-dir
{% endif %}

{% if etcd.cluster.use_ssl %}
etcd-ssl-dir:
  file.directory:
    - name: {{ etcd_ssl_dir }}
    - dir_mode: 755
    - user: root
    - makedirs: True
{% endif %}
