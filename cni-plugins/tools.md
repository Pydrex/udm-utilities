# Useful links and tools for CNI

## MAC address generator

This [MAC address generator](https://gist.github.com/INA2N/079adda7d6e5612996e4e993152d7103) will provide a random MAC address.

Run with

```bash
[UDM] root@udm-pro:/mnt/data/podman/cni# ./macgen.sh 
EE:CC:EC:A2:7C:D1
```

In this example, the partial config in [20-dns.conflist](https://github.com/alxwolf/udm-utilities/blob/master/cni-plugins/20-dns.conflist) or [20-dnsipv6.conflist](https://github.com/alxwolf/udm-utilities/blob/master/cni-plugins/20-dnsipv6.conflist) would be

```json
    {
      "type": "macvlan",
      "mode": "bridge",
      "master": "br5",
      "mac": "EE:CC:EC:A2:7C:D1",
      "ipam": {
 ```

### ULA generator

This [python script](https://github.com/n-st/python-ula) will provide a unique, valid prefix for IPv6 Unique Local Addresses (starting with fdxx:...).

Run with

```bash
[UDM] root@udm-pro:/mnt/data# python ula.py
fdca:5c13:1fb8::
```

In this example, the partial config in [20-dnsipv6.conflist](https://github.com/alxwolf/udm-utilities/blob/master/cni-plugins/20-dnsipv6.conflist) would be

```json
    {
        "address": "fdca:5c13:1fb8::4/64",
        "gateway": "fdca:5c13:1fb8::1"
    }
```
