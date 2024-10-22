kubernetes-formula
==================

Kubernetes cluster deployment formula.

## Dependencies

* [crictl](../../../crictl-formula)
* [containerd](../../../containerd-formula)
* [systemd](../../../systemd-formula)
* [debian](../../../debian-formula)
* [common](../../../salt-common)
* [docker.repository](../../../docker-formula/blob/master/docker/repository.sls)


## Components

- Core
  - [kubernetes](https://github.com/kubernetes/kubernetes) v1.29.9
  - [etcd](https://github.com/etcd-io/etcd) v3.5.15
  - [containerd](https://containerd.io/) v1.6.26
  - [crictl](https://github.com/kubernetes-sigs/cri-tools) v1.29.0

- Network Plugin
  - [cni-plugins](https://github.com/containernetworking/plugins) v1.5.1
  - [flannel](https://github.com/flannel-io/flannel) v0.25.7


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
