{% from "kubernetes/map.jinja" import kubernetes with context %}
{% from "kubernetes/macros.jinja" import kubecomponentbinary with context %}

{% set component = 'kubectl' %}
{% set component_bin_path = kubernetes.install_dir + '/kubectl' %}

{% from "kubernetes/vars.jinja" import
    node_role,
    package_flavor,
    component_source, component_source_hash
with context %}

{{ kubecomponentbinary(component, component_source, component_source_hash, component_bin_path, package_flavor, False) }}
