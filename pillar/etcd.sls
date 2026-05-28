etcd:
  lookup:
    source_url: https://github.com/etcd-io/etcd/releases/download
    source_version: v3.6.11
    install_dir: /usr/local/bin
    ssl_dir: /etc/kubernetes/pki/etcd
    data_dir: /var/local/etcd
    cluster:
      initial_cluster: True
      initial_cluster_token: k8s-etcd-cluster
