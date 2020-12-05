% DNS Catalog Zones - About

DNS Catalog Zones is a method in which a catalog of zones is represented as a regular DNS zone, and transferred using DNS zone transfers. As zones are added to or removed from the catalog zone, the changes are propagated to the secondary nameservers in the normal way. The secondary nameservers then add/remove/modify the zones they serve in accordance with the changes to the zone.

- datatracker: [draft-ietf-dnsop-dns-catalog-zones](https://datatracker.ietf.org/doc/draft-ietf-dnsop-dns-catalog-zones/)
- github repo: [https://github.com/NLnetLabs/draft-toorop-dnsop-dns-catalog-zones](https://github.com/NLnetLabs/draft-toorop-dnsop-dns-catalog-zones)
- please send all feedback or suggestions on the draft to the [dnsop mailing-list](https://www.ietf.org/mailman/listinfo/dnsop)
- informal chat on development of DNS Catalog Zones and the draft is in DNS OARC's Mattermost service: [https://chat.dns-oarc.net/community/channels/catalog-zones](https://chat.dns-oarc.net/community/channels/catalog-zones)

## News

- 4 December 2020
  - A new version [01](https://datatracker.ietf.org/doc/draft-ietf-dnsop-dns-catalog-zones/01/) of the draft has been submitted, with:
    - A new section [The Serial Property](https://www.ietf.org/archive/id/draft-ietf-dnsop-dns-catalog-zones-01.html#name-the-serial-property), introducing a new mechanism which can help with disseminating zones from the primary to the secondary nameservers in a timely fashion more reliably.
    - A new section [Implementation Status](https://www.ietf.org/archive/id/draft-ietf-dnsop-dns-catalog-zones-01.html#name-implementation-status), listing production ready, upcoming and Proof of Concept implementations, and reporting on interoperability of the different implementations.

- 20 November 2020
  - First stab at interoperability testing during [the hackathon at IETF109](https://trac.ietf.org/trac/ietf/meeting/wiki/109hackathon#DNS).
    Results presented at the DNSOP WG session (<[video](https://www.youtube.com/watch?v=R13CeJng9JI&t=167)> <[slides](https://datatracker.ietf.org/meeting/109/materials/slides-109-dnsop-sessb-dns-hackathon-results-00)>)
