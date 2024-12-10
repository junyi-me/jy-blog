---
date: '2024-11-10T06:56:21-07:00'
title: 'Setting up a k3s cluster for my home lab'
image: 'sideshot.jpg'
tags: ['k3s', 'kubernetes', 'self-hosting']
category: 'self-hosting'
---

This is a written record of how I set up a [k3s](https://k3s.io/) cluster on some bare metal machines.

References
1. https://docs.k3s.io/quick-start
2. https://docs.k3s.io/datastore/ha

## Components
Three physical servers were used in this setup.

| host  | model                                     |
| ----- | ----------------------------------------- |
| opx01 | Dell OptiPlex 7050 SFF Intel Core i5-7500 |
| opx02 | Dell OptiPlex 5070 SFF Intel Core i7-9700 |
| opx03 | Dell OptiPlex 7070 SFF Intel Core i7-9700 |

These are the VMs that I run on those hosts. (IPs are arbitrary)

| host  | vm name   | role                        | IP           |
| ----- | --------- | --------------------------- | ------------ |
| opx01 | kmaster01 | k8s master node             | 192.168.1.2  |
|       | kshare01  | NFS server                  | 192.168.1.3  |
| opx02 | kwork02   | k8s worker node             | 192.168.1.4  |
|       | kwork03   | k8s worker node             | 192.168.1.5  |
|       | kwork04   | k8s worker node             | 192.168.1.6  |
|       | kwork05   | k8s worker node             | 192.168.1.7  |
| opx03 | kwork01   | k8s worker node             | 192.168.1.8  |
|       | kwork06   | k8s worker node             | 192.168.1.9  |
|       | kshare02  | k8s db, NFS server (backup) | 192.168.1.10 |
|       | kmaster02 | k8s master node             | 192.168.1.11 |

The VMs all run [Debian 12](https://www.debian.org/releases/bookworm/), and the following packages are installed
1. nfs-common (on all VMs)
2. nfs-kernel-server (on `kshare01`, `kshare02`)

Also, before doing any of the following, I created a [PostgreSQL](https://www.postgresql.org/) database on `kshare02` to use as a external data source for my master nodes. \
In this example, assume it's running on port 5432 of `kshare02`, and the following database is set up and ready to accept connections.

| property      | value  |
| ------------- | ------ |
| database name | master |
| username      | k3s    |
| password      | pass   |

## Setting up the first master node
Install k3s, telling it to use external data source
```bash
curl -sfL https://get.k3s.io | sh -s - server --datastore-endpoint="postgres://k3s:pass@192.168.1.10:5432/master"
```

Then edit k3s service
```
ExecStart=/usr/local/bin/k3s \
    server \
    --node-ip 192.168.1.2 \
    --datastore-endpoint="postgres://k3s:pass@192.168.1.10:5432/master" \
    --disable servicelb \
```
and reload+restart it

## Setting up the second master node
Set up another master node, and join it to the cluster

From `kmaster01`, copy the server token
```bash
sudo cat /var/lib/rancher/k3s/server/token
# copy for later use
```

on `kmaster02`
```bash
  curl -sfL https://get.k3s.io | sh -s - server \
    --datastore-endpoint="postgres://k3s:pass@192.168.1.10:5432/master" \
    --token "<token>"
```

To confirm both nodes are there, log in to `kmaster01` and run the command:
```bash
sudo kubectl get node
```
Confirm that both `kmaster01` and `kmaster02` are shown.

## Join worker nodes
Log in to each worker node and run the following command:
```bash
curl -sfL https://get.k3s.io | K3S_URL=https://192.168.1.2:6443 K3S_TOKEN="<token>" sh -
```

Again, to confirm all nodes are added, log in to `kmaster01` (or kmaster02) and run:
```bash
sudo kubectl get node
```

## Conclusion
It was fun, and far easier than I thought to set up a kubernetes cluster with baremetal machines. Currently I use my cluster to run this blog, a personal portfolio website, and a few other pods for my own use.

There is one issue, though, which is that although there are two master nodes in this setup, the DB is still the single point of failure. Once I figure out a redundant solution, I will post it here.
