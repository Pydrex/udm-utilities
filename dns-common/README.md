# dns-common

## Overview

Target is to have a DNS resolver running on the UDM/P with a separate IPv4 (and/or IPv6) address.

For this, one must

1. Create a dedicated VLAN without DHCP on the UDM/P.
1. Install the CNI (Container Network Interface) plugin, this will allow to access the container via a dedicated IPv4 and IPv6 address.
1. Configure this CNI plugin.
1. Configure the IP links and routing tables.

## Creating a Corporate VLAN without DHCP

Follow the instructions from [Step 1](https://github.com/boostchicken-dev/udm-utilities/wiki/Run-a-Wireguard-VPN-server-on-UDM-Pro#step-1-create-dedicated-corporate-without-dhcp-for-the-vpn). For this example, we use VLAN 5 (instead of 240).

All `macvlan`IP addresses will live in this Corporate VLAN.

## CNI plugin installation

Copy the [05-install-cni-plugins.sh](https://github.com/alxwolf/udm-utilities/blob/87b9f7dac6b3163bb5c09fc9bcb86fcfa7fa0c59/cni-plugins/05-install-cni-plugins.sh) script to /mnt/data/on_boot.d/ and run it.

```bash
curl -Lo /mnt/data/on_boot.d/05-install-cni-plugins.sh https://raw.githubusercontent.com/boostchicken-dev/udm-utilities/master/cni-plugins/05-install-cni-plugins.sh
chmod +x /mnt/data/on_boot.d/05-install-cni-plugins.sh
./05-install-cni-plugins.sh
```

## CNI plugin configuration

### Creating a MAC address

The CNI Interface will require a unique MAC address, this can be generated with the [MAC address generator](mac-address-generator).

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

### IPv4 configuration

* Copy [20-dns.conflist](cni-plugins/20-dns.conflist) to `/mnt/data/podman/cni/`.

     ```bash
    curl -Lo /mnt/data/podman/cni/20-dns.conflist https://raw.githubusercontent.com/boostchicken-dev/udm-utilities/master/cni-plugins/20-dns.conflist
    ```

* If you created a different Corporate VLAN than 5 on the UDM/P: adjust the value `br5` to your VLAN number
* Insert the MAC address you generated in line 9.
* Adjust the IP address and gateway to your liking, if required.

### IPv6 configuration

*
* Copy [20-dnsipv6.conflist](cni-plugins/20-dnsipv6.conflist) to `/mnt/data/podman/cni/`.

     ```bash
    curl -Lo /mnt/data/podman/cni/20-dnsipv6.conflist https://raw.githubusercontent.com/boostchicken-dev/udm-utilities/master/cni-plugins/20-dnsipv6.conflist
    ```

* If you created a different Corporate VLAN than 5 on the UDM/P: adjust the value `br5`to your VLAN number
* Insert the MAC address you generated in line 9.
* Adjust the IPv4 and IPv6 address and gateway to your liking, if required.


Create a link in `/etc/cni/net.d/` to the configuration file you just created.

```bash
ln -s /etc/cni/net.d/ /mnt/data/podman/cni/20-dns.conflist
```

This will create your podman macvlan network.

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
