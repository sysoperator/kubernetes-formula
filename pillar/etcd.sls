#!yaml|gpg
etcd:
  lookup:
    source_url: https://github.com/etcd-io/etcd/releases/download
    source_version: v3.5.6
    install_dir: /usr/local/bin
    etc_dir: /etc/etcd
    ssl_dir: /pki
    data_dir: /var/local/etcd
    endpoints:
      - https://10.81.10.1:2379
    cluster:
      name: etcd-cluster
      peers:
        - name: etcd-peer0
          ip: 10.81.10.1
      initial_cluster: True
      ca_cert: |
%CA CERT%
      ca_key: |
%CA KEY%
