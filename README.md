kubernetes-formula
==================

Kubernetes cluster deployment formula.

## Dependencies

- Vars and helpers:
  - [common](../../../salt-common)
  - [systemd](../../../salt-systemd)
  - [ca](../../../ca-formula)

- Core formulas:
  - [crictl](../../../crictl-formula)
  - [containerd](../../../containerd-formula)
  - [debian](../../../debian-formula)
  - [sysctl](../../../sysctl-formula)
  - [docker.repository](../../../docker-formula/blob/master/docker/repository.sls)

## Components

- Core
  - [kubernetes](https://github.com/kubernetes/kubernetes) v1.33.5
  - [etcd](https://github.com/etcd-io/etcd) v3.5.24
  - [containerd](https://containerd.io/) v1.7.24
  - [crictl](https://github.com/kubernetes-sigs/cri-tools) v1.33.0

- Network Plugin
  - [cni-plugins](https://github.com/containernetworking/plugins) v1.8.0
  - [flannel](https://github.com/flannel-io/flannel) v0.27.3

## Pre-requisities

### Roles

Target minion should have the following grains configured:

```
kubernetes:
  clustername: local
roles:
- kube-master
- kube-cluster-member
```

See: https://docs.saltproject.io/en/latest/topics/grains/index.html#grains-in-etc-salt-grains

### Nodegroup

Navigate to `/etc/salt/master.d` and create a file called `nodegroups.conf` with these contents:

```
nodegroups:
  kubernetes: 'G@roles:kube-cluster-member or G@roles:kube-node-proxier'
```

Then restart `salt-master` service:

```shell
systemctl restart salt-master
```

See: https://docs.saltproject.io/en/latest/topics/targeting/nodegroups.html

### Certificates

Certificate generation heavily relies on the [ca](../../../ca-formula) formula. For Kubernetes the following subordinate CAs should be defined:

```
    sub_ca:
      - name: KubernetesCA
        CN: kubernetes-ca
        O: Kubernetes general CA
      - name: KubernetesProxyCA
        CN: kubernetes-front-proxy-ca
        O: Kubernetes Proxy CA
      - name: etcdCA
        CN: etcd-ca
        O: etcd CA
      - name: etcdpeerCA
        CN: etcd-peer-ca
        O: etcd peer CA
```

and the following [x509_signing_policies](https://docs.saltproject.io/en/3006/ref/modules/all/salt.modules.x509_v2.html#signing-policies) as well:

```
  kubernetes_ca:
    - minions: '<minion matcher>'
    - signing_private_key: {{ ca.pki_dir }}/KubernetesCA.key
    - signing_cert: {{ ca.pki_dir }}/KubernetesCA.crt
    - basicConstraints: "critical, CA:FALSE"
    - keyUsage: "critical, digitalSignature, keyEncipherment"
    - copypath: {{ ca.pki_dir }}/{{ ca.issued_certs_dir }}/
  kubernetes_front_proxy_ca:
    - minions: '<minion matcher>'
    - signing_private_key: {{ ca.pki_dir }}/KubernetesProxyCA.key
    - signing_cert: {{ ca.pki_dir }}/KubernetesProxyCA.crt
    - basicConstraints: "critical, CA:FALSE"
    - keyUsage: "critical, digitalSignature, keyEncipherment"
    - copypath: {{ ca.pki_dir }}/{{ ca.issued_certs_dir }}/
  etcd_ca:
    - minions: '<minion matcher>'
    - signing_private_key: {{ ca.pki_dir }}/etcdCA.key
    - signing_cert: {{ ca.pki_dir }}/etcdCA.crt
    - basicConstraints: "critical, CA:FALSE"
    - keyUsage: "critical, digitalSignature, keyEncipherment"
    - copypath: {{ ca.pki_dir }}/{{ ca.issued_certs_dir }}/
  etcd_peer_ca:
    - minions: '<minion matcher>'
    - signing_private_key: {{ ca.pki_dir }}/etcdpeerCA.key
    - signing_cert: {{ ca.pki_dir }}/etcdpeerCA.crt
    - basicConstraints: "critical, CA:FALSE"
    - keyUsage: "critical, digitalSignature, keyEncipherment"
    - copypath: {{ ca.pki_dir }}/{{ ca.issued_certs_dir }}/
```

### Pillar

1. Add the following content to the pillar's `top.sls` file:

```
base:
  kubernetes:
    - match: nodegroup
    - containerd
    - crictl
    - etcd
    - flannel
    - cni
    - kubernetes
  'roles:kube-master':
    - match: grain
    - kubernetes/mine
```

2. Open `kubernetes/mine.sls` and replace `kube0` with the default interface name of the cluster members.
For a single-machine installation, leave it default and configure a dummy interface `kube0` in `/etc/network/interfaces`:

```
# Kubernetes dummy interface
auto kube0
iface kube0 inet static
	address 10.81.10.1/24
	pre-up ip link add $IFACE type dummy
	pre-up ip link set $IFACE multicast on
```

Then bring the interface up:

```shell
ifup kube0
```

3. Populate the Salt Mine with data:

```shell
salt -N kubernetes saltutil.refresh_all
salt -N kubernetes mine.update
```

See: https://docs.saltproject.io/en/latest/topics/mine/index.html
