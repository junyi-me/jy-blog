---
date: "2024-12-10"
title: "Setting up host-only network on VMWare Ubuntu 7"
tags: ['VM', 'networking']
---

During my work, I had to set up an Ubuntu 7 VM on VMWare, and copy some files out of it. Ubuntu 7 is a very old system, and some VMWare features did not work out-of-the-box. \
I spent a lot of time figuring out how to transfer files between the host and the VM, so I decided to write it down here.

Here are some things I tried but did not work:
1. Shared folders: VMWare Tools for Ubuntu 7 did not work, and it was too much trouble to install it from source
2. Bridged network: The VM was not able to get an IP address from the host machine
3. NAT network: Same as above

Finally, I set up a **host-only network**, which worked well. Here are the steps I took:


## Step 1: Confirm network interface on host machine

Identify network interface "VMnet1" on host machine, which is the default host-only network interface for VMWare.

```
> ipconfig
...
Ethernet adapter VMware Network Adapter VMnet1:

   Connection-specific DNS Suffix  . :
   Link-local IPv6 Address . . . . . : fe80::44b0:aca1:904d:4e26%5
   IPv4 Address. . . . . . . . . . . : 192.168.198.1
   Subnet Mask . . . . . . . . . . . : 255.255.255.0
   Default Gateway . . . . . . . . . :
```

## Step 2: Configure network adapter

In order to connect to `VMnet1` from inside the VM, we need to add a network adapter. \
Go to VM settings, and add a network adapter:

![VMWare network adapter settings](/settings.png)
The pre-defiend "Host-only" option did not work for me, so I chose "Custom" and selected "VMnet1" from the dropdown.

After configuring that, confirm it inside the VM:
```bash
ifconfig
```
You should see a new network interface, like `eth1` or `ens33`. In my case, it was `eth1`.

## Step 3: In VM, edit `/etc/network/interfaces`
Make sure to remove the original network interfaces, and configure the newly added one like this:
```
auto lo
iface lo inet loopback

auto eth1
iface eth1 inet static
    address 192.168.198.2
    netmask 255.255.255.0
    gateway 192.168.198.1
```
Make sure the subnet mask matches VMnet1, and the IP is in the subnet

## Step 4: Restart VM networks

Restart the network service to apply the changes.

Since Ubuntu 7 uses `ifupdown`, the command is:

```bash
/etc/init.d/networking restart
ping 192.168.198.1
```

