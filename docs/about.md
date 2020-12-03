% DNS Catalog Zones - About

DNS Catalog Zones is a method in which a catalog of zones is represented as a regular DNS zone, and transferred using DNS zone transfers. As zones are added to or removed from the catalog zone, the changes are propagated to the secondary nameservers in the normal way. The secondary nameservers then add/remove/modify the zones they serve in accordance with the changes to the zone.

- datatracker: [draft-ietf-dnsop-dns-catalog-zones](https://datatracker.ietf.org/doc/draft-ietf-dnsop-dns-catalog-zones/)
- github repo: [https://github.com/NLnetLabs/draft-toorop-dnsop-dns-catalog-zones](https://github.com/NLnetLabs/draft-toorop-dnsop-dns-catalog-zones)
- please send all feedback or suggestions on the draft to the [dnsop mailing-list](https://www.ietf.org/mailman/listinfo/dnsop)
- informal chat on development of DNS Catalog Zones and the draft is in DNS OARC's Mattermost service: [https://chat.dns-oarc.net/community/channels/catalog-zones](https://chat.dns-oarc.net/community/channels/catalog-zones)

## News

- 20 November 2020
  - First stab at interoperability testing during [the hackathon at IETF109](https://trac.ietf.org/trac/ietf/meeting/wiki/109hackathon#DNS).
    Results presented at the DNSOP WG session (<[video](https://www.youtube.com/watch?v=R13CeJng9JI&t=167)> <[slides](https://datatracker.ietf.org/meeting/109/materials/slides-109-dnsop-sessb-dns-hackathon-results-00)>)
