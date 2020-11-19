% DNS Catalog Zones - Implementations & Interoperability

* Knot DNS has DNS Catalog Zones since [Knot DNS Version 3.0.0](https://www.knot-dns.cz/2020-09-09-version-300.html)
  * [Documentation](https://www.knot-dns.cz/docs/3.0/html/configuration.html#catalog-zones)
  * [catalog_generate](https://gitlab.nic.cz/knot/knot-dns/-/tree/catalog_generate) Branch for generating Catalog Zones
* [PowerCATZ](https://github.com/PowerDNS/powercatz/) program to handle Catalog Zones with PowerDNS
* [NSDCatZ](https://github.com/IETF-Hackathon/NSDCatZ) PoC scripts for producing and consuming Catalog Zones with NSD (version from [zone-verification branch](https://github.com/NLnetLabs/nsd/tree/zone-verification))


| Server          | Software | catalog1.    | catalog2.    |
|-----------------|----------|--------------|--------------|
| `ns1.zones.cat` | NSD      | **Producer** | Consumer     |
| `ns2.zones.cat` | NSD      | Consumer     | Consumer     |
| `ns3.zones.cat` | Knot DNS | Consumer     | **Producer** |
| `ns4.zones.cat` | PowerDNS | Consumer     | Consumer     |

