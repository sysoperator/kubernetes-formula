#!yaml|gpg
etcd:
  lookup:
    source_url: https://github.com/etcd-io/etcd/releases/download
    source_version: v3.5.23
    install_dir: /usr/local/bin
    ssl_dir: /etc/kubernetes/pki/etcd
    data_dir: /var/local/etcd
    cluster:
      name: etcd-cluster
      initial_cluster: True
      ca_cert:
      ca_key:
