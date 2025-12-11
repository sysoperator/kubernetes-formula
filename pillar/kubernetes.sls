#!yaml|gpg
kubernetes:
  lookup:
    source_url: https://storage.googleapis.com/kubernetes-release/release
    source_version: v1.34.3
    install_dir: /usr/local/bin
    k8s:
      etc_dir: /etc/kubernetes
      ssl_dir: /pki
      # Default: 365
      ssl_cert_days_valid:
      # Default: 30
      ssl_cert_days_remaining:
      manifests_dir: /manifests
      single_node_cluster: False
      apiserver:
        external_domain: kubernetes.internal
        cluster_ip: 172.16.0.1
        default_address: 127.0.0.1
        default_secure_port: 6443
        log_debug_rbac: False
        # Default: 30000-32767
        service_node_port_range:
      kubelet:
        # Use the container runtime default if empty
        # Possible values are: 'cgroupfs', 'systemd' (default: cgroupfs)
        cgroup_driver: systemd
        # Default: unix:///run/containerd/containerd.sock
        container_runtime_endpoint:
      cluster_dns:
        override_host_resolvconf: False
        nameservers:
          # Default kube-dns svc IP
          - 172.16.0.53
        local_domain: internal
        # Do not use .local TLD as cluster domain: https://datatracker.ietf.org/doc/html/rfc6762
        #   This document specifies that the DNS top-level domain ".local." is a
        #   special domain with special semantics, namely that any fully
        #   qualified name ending in ".local." is link-local, and names within
        #   this domain are meaningful only on the link where they originate.
        cluster_domain: cluster.local
        include_cluster_domain: False
        search_suffixes:
          # Search suffixes as list, e.g.:
          #- foo
          #- bar
        options:
          # Additional options as list, e.g.:
          #- ndots:1
          #- timeout:10
      networks:
        # Multi node:
        pod_network_cidr: 172.16.128.0/17
        # Single node:
        #pod_network_cidr: 172.16.227.0/24
        svc_network_cidr: 172.16.0.0/20
      authorization_mode:
        - Node
        - RBAC
      authentication_token_webhook:
        enabled: False
        flags:
          - --authentication-token-webhook-cache-ttl=1m0s
          - --authentication-token-webhook-version=v1
      security:
        - allow_privileged
      runtime_config:
        # Enable/Disable specific resources:
        #- api/all=false
        #- api/v1=true
        #- ...
      feature_gates:
      admission_controllers:
        # Enable additional Admission Plugins:
        #- PodPreset
        #- ...
      log_debug: False
      service_account_signing_key:
      service_account_key:
