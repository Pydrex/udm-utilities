# dns-common

## Overview

Target is to have a DNS resolver running on the UDM/P with a separate IPv4 (and/or IPv6) address.

For this, one must

1. Create a dedicated VLAN without DHCP on the UDM/P.
1. Install the CNI (Container Network Interface) plugin, this will allow to access the container via a dedicated IPv4 and IPv6 address.
1. Configure this CNI plugin.
1. Create the `podman` network
1. Configure the IPs, IP links and routing tables.
1. Install the DNS resolver of your choice.
1. Optional: install `unbound`to become fully independent from your ISP or big tech DNS resolvers.

## Creating a Corporate VLAN without DHCP

Follow the instructions from [Step 1](https://github.com/boostchicken-dev/udm-utilities/wiki/Run-a-Wireguard-VPN-server-on-UDM-Pro#step-1-create-dedicated-corporate-without-dhcp-for-the-vpn). For this example, we use VLAN 5 (instead of 240).

All `macvlan`IP addresses will live in this Corporate VLAN.

## CNI plugin installation

Copy the [05-install-cni-plugins.sh](https://github.com/alxwolf/udm-utilities/blob/87b9f7dac6b3163bb5c09fc9bcb86fcfa7fa0c59/cni-plugins/05-install-cni-plugins.sh) script to `/mnt/data/on_boot.d/`. Do not run it yet.

```bash
curl -Lo /mnt/data/on_boot.d/05-install-cni-plugins.sh https://raw.githubusercontent.com/boostchicken-dev/udm-utilities/master/cni-plugins/05-install-cni-plugins.sh
chmod +x /mnt/data/on_boot.d/05-install-cni-plugins.sh
```

## CNI plugin configuration

### Creating a MAC address

The CNI Interface will require a unique MAC address, this can be generated with the [MAC address generator](https://github.com/alxwolf/udm-utilities/blob/master/cni-plugins/tools.md#mac-address-generator).

```bash
cd /mnt/data/podman/cni
curl -Lo macgen.sh https://gist.githubusercontent.com/INA2N/079adda7d6e5612996e4e993152d7103/raw/2e770f82f85794f7e4ee959b39112df9c04b3c71/macgen.sh
chmod +x macgen.sh
./macgen.sh
```

will deliver a result similar to

```bash
EE:CC:EC:A2:7C:D1
```

It's beneficial to have and keep a hard-coded MAC address, like described also in this [Wiki](..wiki/Update-your-MacVLAN-containers-to-have-hardcoded-MAC-addresses) entry.

### IPv4 only configuration

* Copy [20-dns.conflist](cni-plugins/20-dns.conflist) to `/mnt/data/podman/cni/`.

     ```bash
    curl -Lo /mnt/data/podman/cni/20-dns.conflist https://raw.githubusercontent.com/boostchicken-dev/udm-utilities/master/cni-plugins/20-dns.conflist
    ```

* If you created a different Corporate VLAN than 5 on the UDM/P: adjust the value `br5` to your VLAN number
* Insert the MAC address you generated in line 9.
* Adjust the IP address and gateway to your liking, if required.

### IPv6 and IPv6 configuration

Above configuration can be extended to also use and serve IPv6 addresses.

If there is no public IPv6 address assigned to the network, use of an ULA is recommended. An ULA (Unique Local Address) allows to have a fixed, local/private IP address for your DNS resolver. How to get the corresponding prefix is described [here](ula-generator).

Instead of doing the IPv4 steps, setup is:

* Copy [20-dnsipv6.conflist](cni-plugins/20-dnsipv6.conflist) to `/mnt/data/podman/cni/`.

     ```bash
    curl -Lo /mnt/data/podman/cni/20-dnsipv6.conflist https://raw.githubusercontent.com/boostchicken-dev/udm-utilities/master/cni-plugins/20-dnsipv6.conflist
    ```

* If you created a different Corporate VLAN than 5 on the UDM/P: adjust the value `br5` to your VLAN number
* Insert the MAC address you generated in line 9.
* Adjust the IPv4 and IPv6 address and gateway to your liking, if required.

## Creating the `podman` network

Create the `podman` macvlan network and run the CNI installer script. This script will be executed on each boot and will create the links in `/etc/cni/net.d/` to the configuration file you just adjusted.

```bash
podman network create dns
/bin/sh /mnt/data/on_boot.d/05-install-cni-plugins.sh
```

Copy [10-dns.sh](dns-common/on_boot.d/10-dns.sh) to `/mnt/data/on_boot.d/`, update it to your modified values if required, execute the script.

```bash
curl -Lo /mnt/data/on_boot.d/10-dns.sh https://raw.githubusercontent.com/alxwolf/udm-utilities/unbound/dns-common/on_boot.d/10-dns.sh
chmod +x /mnt/data/on_boot.d/10-dns.sh
/bin/sh /mnt/data/on_boot.d/10-dns.sh
```

On first execution (if the DNS resolver container has not been initialized yet), you can expect to get an error ("Container xyz not found"). That is of no concern.

## Finally, get the DNS resolver(s) running

Choose the Ad-/tracking blocker to your liking from the [main project page](https://github.com/boostchicken-dev/udm-utilities).

If you want to run your own `unbound`, check [here](https://github.com/alxwolf/udm-utilities/blob/master/unbound/README.md).

## Useful links and tools

### MAC address generator

This [MAC address generator](https://gist.github.com/INA2N/079adda7d6e5612996e4e993152d7103) will provide a random MAC address.

Run with

```bash
[UDM] root@udm-pro:/mnt/data/podman/cni# ./macgen.sh 
EE:CC:EC:A2:7C:D1
```

In this example, the partial config in [21-unbound.conflist](cni-plugins/21-unbound.conflist) or [21-unboundipv6.conflist](cni-plugins/21-unboundipv6.conflist) would be

```json
    {
      "type": "macvlan",
      "mode": "bridge",
      "master": "br5",
      "mac": "EE:CC:EC:A2:7C:D1",
      "ipam": {
 ```

### ULA generator

This [Python script](https://github.com/n-st/python-ula) will provide a unique, valid prefix for IPv6 Unique Local Addresses (starting with fdxx:...).

Run with

```bash
[UDM] root@udm-pro:/mnt/data# python ula.py
fdca:5c13:1fb8::
```

In this example, the partial config in [21-unboundipv6.conflist](cni-plugins/21-unboundipv6.conflist) would be

```json
    {
        "address": "fdca:5c13:1fb8::4/64",
        "gateway": "fdca:5c13:1fb8::1"
    }
```
