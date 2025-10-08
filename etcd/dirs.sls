{%- set tplroot = tpldir.split('/')[0] %}
{%- from tplroot ~ "/map.jinja" import etcd with context -%}
{%- from tplroot ~ "/vars.jinja" import
    etcd_ssl_dir
with context -%}

{%- if etcd.cluster.ca_cert != '' %}
include:
  - kubernetes/dirs
{%- endif %}

{{ etcd_ssl_dir }}:
  file.directory:
    - dir_mode: 755
    - user: root
    - makedirs: True
