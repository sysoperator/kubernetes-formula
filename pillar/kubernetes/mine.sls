mine_functions:
  kube_master_ip_addrs:
    mine_function: network.ip_addrs
    interface: [kube0]
    allow_tgt: 'kubernetes'
    allow_tgt_type: nodegroup
