cni:
  lookup:
    source_url: https://github.com/containernetworking/plugins/releases/download
    source_version: v1.4.1
    install_dir: /opt/cni/bin
    cni:
      etc_dir: /etc/cni/net.d
      data_dir: /run/cni/networks
      network_name: kubenet
      bridge_name: cbr0
