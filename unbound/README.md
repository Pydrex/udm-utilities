# Running `unbound` on the UDM/P

## Prerequisites

Finish setup of [dns-common](https://github.com/alxwolf/udm-utilities/tree/unbound/dns-common#overview)

## Create another `podman` network

We will use another IP address. In the current examples, the DNS resolver (e.g., pi-hole) is listening on `10.0.5.2`. The example will make `unbound` listen on `10.0.5.3`.

Follow the steps in ["Creating the podman network"](https://github.com/alxwolf/udm-utilities/tree/unbound/dns-common#creating-the-podman-network), but use
