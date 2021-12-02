{%- set tplroot = tpldir.split('/')[0] -%}
{%- from tplroot ~ "/map.jinja" import kubernetes with context -%}
{%- set component = 'kubectl' -%}
{%- set component_bin_path = kubernetes.install_dir + '/kubectl' -%}
{%- from tplroot ~ "/vars.jinja" import
    package_flavor,
    component_source, component_source_hash
with context -%}
{%- from tplroot ~ "/macros.jinja" import kubecomponentbinary with context -%}

{{ kubecomponentbinary(component, component_source, component_source_hash, component_bin_path, package_flavor, False) }}
