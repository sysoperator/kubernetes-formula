#!yaml|gpg
kubernetes:
  lookup:
    source_url: https://storage.googleapis.com/kubernetes-release/release
    source_version: v1.25.3
    install_dir: /usr/local/bin
    k8s:
      etc_dir: /etc/kubernetes
      ssl_dir: /pki
      manifests_dir: /manifests
      apiserver:
        cluster_ip: 172.16.0.1
        default_address: 127.0.0.1
        default_secure_port: 6443
        log_debug_rbac: False
      kubelet:
        # Use the container runtime default if empty
        # Possible values are: 'cgroupfs', 'systemd' (default: cgroupfs)
        cgroup_driver: systemd
      cluster_dns:
        override_resolvconf: False
        domain: internal
        cluster_domain: cluster.local
        search:
          # Search suffixes as list, e.g.:
          #- foo.bar.com
          #- baz.com
          - service
        nameservers:
          # Default kube-dns svc IP
          - 172.16.0.2
      networks:
        pod_network_cidr: 172.16.128.0/17
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
      admission_controllers:
        # Enable additional Admission Plugins:
        #- PodPreset
        #- ...
      x509_signers_enabled: True
      x509_signers_duration: 720h
      x509_signers:
        # Cert issuers:
        #- name: name
        #  cert: |
        #  key: |
      log_debug: False
      ca_cert: |
%CA CERT%
      ca_key: |
%CA KEY%
      service_account_signing_key: |
%SA KEY%
      service_account_key: |
%SA PUB%
      front_proxy_ca_cert: |
%PROXY CA CERT%
      front_proxy_ca_key: |
%PROXY CA KEY%
