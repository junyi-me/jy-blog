---
date: 2024-11-16
title: k3s worker node with multiple IPs
draft: false
image: 
tags: [k3s, kubernetes, networking, linux]
categories: [self-hosting]
---

## The issue
When setting up nodes for my k3s cluster, I noticed that some nodes were not able to communicate with each other. After some digging, I found the issue was that nodes were joining the cluster with wrong IPs.

When each node has two IPs like this, (`/etc/network/interfaces`)
```bash
allow-hotplug enp1s0
iface enp1s0 inet dhcp

allow-hotplug enp1s0
iface enp1s0 inet static
    address 10.0.69.101
    netmask 255.255.0.0
```

they might join the cluster using the DHCP IP, not the static one
```
jy:~/git/homelab{0}$ kgn -o wide
NAME      STATUS   ROLES                  AGE   VERSION        INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                         KERNEL-VERSION   CONTAINER-RUNTIME
kmaster01   Ready    control-plane,master   15d   v1.30.5+k3s1   10.0.69.101   <none>        Debian GNU/Linux 12 (bookworm)   6.1.0-26-amd64   containerd://1.7.21-k3s2
kwork02   Ready    <none>                 82m   v1.30.5+k3s1   10.0.0.99   <none>        Debian GNU/Linux 12 (bookworm)   6.1.0-26-amd64   containerd://1.7.21-k3s2
```

**This is problematic, as it sometimes prevents pods running on these nodes from accessing kubernetes' internal IPs.**

In my case, dropping the DHCP IP was not an option, since internet was only reachable on the /24 subnet, and my static IPs live on the /16 subnet.

## Solution
It turns out we can keep both IPs, and
1. use the /24 one for internet access (default route)
2. use the /16 one for in-cluster communication

To do that, all we need to do is edit the k3s service units on each host.
```bash
# master node
sudo systemctl edit k3s
# worker node
sudo systemctl edit k3s-agent
```

Adding this argument to the startup command would tell k3s to use a specific IP.
```bash
    --node-ip <static_ip> \
```
Example for a worker node:
```bash
[Service]
ExecStart=
ExecStart=/usr/local/bin/k3s \
    agent \
    --node-ip 10.0.69.104 \
```

Finally, restart the k3s services on each node.

For master nodes,
```bash
sudo systemctl daemon-reload && sudo systemctl restart k3s.service
```
For worker nodes,
```bash
sudo systemctl daemon-reload && sudo systemctl restart k3s-agent.service
```
