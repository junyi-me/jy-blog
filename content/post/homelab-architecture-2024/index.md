---
date: "2024-12-10"
title: "My home lab - 2024"
image: "images/motherboard.jpg"
tags: ["self-hosting", "kubernetes"]
---

Year 2024 is coming to an end, so I thought it's a good time to reflect on my home lab setup.

This is my first time summarizing my home lab setup, and I'm planning to make this an annual thing to have a record of how my setup evolves over time.

![High-level architecture overview](/homelab.drawio.png)

## Hardware

Three Dell Optiplexes run everything in my home lab.

| host  | model                                     | CPU cores | RAM (GB) |
| ----- | ----------------------------------------- | --------- |--------- |
| opx01 | Dell OptiPlex 7050 SFF Intel Core i5-7500 | 4         | 16       |
| opx02 | Dell OptiPlex 5070 SFF Intel Core i7-9700 | 8         | 16       |
| opx03 | Dell OptiPlex 7070 SFF Intel Core i7-9700 | 8         | 16       |

Currently they are more than enough to handle my workload. Next year I might look into getting a NAS for storage, instead of using NFS on `kshare01` and `kshare02` (see below). That should give me more bandwidth.

## Infrastructure software

### Virtual machines

I'm running the following VMs on these hosts using `libvirt` (`KVM` and `QEMU`).

Each VM has 2 vCPUs and 4GB of RAM, and running Debian 12. 3 of them are Kubernetes master nodes, 2 of them are NFS servers, and the rest are worker nodes.

| host  | vm name     | role                        |
| ----- | ----------- | --------------------------- |
| opx01 | kmaster01   | k8s master node             |
|       | kshare01    | NFS server                  |
| opx02 | kwork02     | k8s worker node             |
|       | kwork03     | k8s worker node             |
|       | kwork04     | k8s worker node             |
|       | kmaster03   | k8s master node             |
| opx03 | kwork01     | k8s worker node             |
|       | kwork06     | k8s worker node             |
|       | kshare02    | NFS server (backup)         |
|       | kmaster02   | k8s master node             |

I might look into using Proxmox or similar to manage my VMs, just for the sake of better UI.

### Kubernetes

I'm using k3s as my Kubernetes distribution. To tolerate one master node failure, I have 3 master nodes running `etcd` data store in HA mode. More on that [here]({{< ref "hosting-website-k3s-cluster" >}}).

Here are the addons I use in my cluster:
1. [MetalLB](https://metallb.universe.tf/) for load balancing
2. [Cert-manager](https://cert-manager.io/) for managing TLS certificates
3. [Longhorn](https://longhorn.io/) for persistent storage

## Workflow

In the Kubernetes cluster, I use the following tools to aid my workflow:
1. [ArgoCD](https://argoproj.github.io/argo-cd/) for GitOps
2. [Kubernetes Dashboard](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/) for monitoring

