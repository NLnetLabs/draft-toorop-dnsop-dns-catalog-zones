%%%
Title = "DNS Catalog Zones"
abbrev = "dns-catalog-zones"
docname = "@DOCNAME@"
category = "std"
ipr = "trust200902"
area = "Internet"
workgroup = "DNSOP Working Group"
date = @TODAY@

[seriesInfo]
name = "Internet-Draft"
value = "@DOCNAME@"
stream = "IETF"
status = "standard"

[[author]]
initials = "P."
surname = "van Dijk"
fullname = "Peter van Dijk"
organization = "PowerDNS"
[author.address]
 email = "peter.van.dijk@powerdns.com"
[author.address.postal]
 city = "Den Haag"
 country = "Netherlands"

[[author]]
initials = "L."
surname = "Peltan"
fullname = "Libor Peltan"
organization = "CZ.NIC"
[author.address]
 email = "libor.peltan@nic.cz"
[author.address.postal]
 country = "CZ"

[[author]]
initials = "O."
surname = "Sury"
fullname = "Ondrej Sury"
organization = "Internet Systems Consortium"
[author.address]
 email = "ondrej@isc.org"
[author.address.postal]
 country = "CZ"

[[author]]
initials="W."
surname="Toorop"
fullname="Willem Toorop"
organization = "NLnet Labs"
[author.address]
 email = "willem@nlnetlabs.nl"
[author.address.postal]
 street = "Science Park 400"
 city = "Amsterdam"
 code = "1098 XH"
 country = "Netherlands"

[[author]]
initials="K."
surname ="Monshouwer"
fullname="Kees Monshouwer"
[author.address]
 email = "mind@monshouwer.eu"
[author.address.postal]
 country = "Netherlands"

[[author]]
initials = "P."
surname = "Thomassen"
fullname = "Peter Thomassen"
organization = "deSEC, SSE - Secure Systems Engineering"
[author.address]
 email = "peter@desec.io"
[author.address.postal]
 city = "Berlin"
 country = "Germany"

[[author]]
initials = "A."
surname = "Sargsyan"
fullname = "Aram Sargsyan"
organization = "Internet Systems Consortium"
[author.address]
 email = "aram@isc.org"
%%%


.# Abstract

This document describes a method for automatic DNS zone provisioning among DNS
primary and secondary nameservers by storing and transferring the catalog of
zones to be provisioned as one or more regular DNS zones.

{mainmatter}


# Introduction

The content of a DNS zone is synchronized amongst its primary and secondary
nameservers using AXFR and IXFR.  However, the list of zones served by the
primary (called a catalog in [@!RFC1035]) is not automatically synchronized
with the secondaries.  To add or remove a zone, the administrator of a DNS
nameserver farm not only has to add or remove the zone from the primary, they
must also add/remove the zone from all secondaries, either manually or via an
external application.  This can be both inconvenient and error-prone; it is 
also dependent on the nameserver implementation.

This document describes a method in which the catalog is represented as a
regular DNS zone (called a "catalog zone" here), and transferred using DNS zone
transfers.  As zones are added to or removed from the catalog zone, these changes
are distributed to the secondary nameservers in the normal way.  The secondary
nameservers then add/remove/modify the zones they serve in accordance with the
changes to the catalog zone. Other use-cases of nameserver remote configuration
by catalog zones are possible, where the catalog consumer might not be a
secondary.

# Terminology

The key words "**MUST**", "**MUST NOT**", "**REQUIRED**",
"**SHALL**", "**SHALL NOT**", "**SHOULD**", "**SHOULD NOT**",
"**RECOMMENDED**", "**NOT RECOMMENDED**", "**MAY**", and
"**OPTIONAL**" in this document are to be interpreted as described in
BCP 14 [@!RFC2119;@!RFC8174] when, and only when, they appear in all
capitals, as shown here.

Catalog zone
: A DNS zone containing a DNS catalog, that is, a list of DNS zones and associated properties.

Member zone
: A DNS zone whose configuration is published inside a catalog zone.

Member node
: The DNS name in the Catalog zone representing a Member zone.

`$CATZ`
: Used in examples as a placeholder to represent the domain name of the
  catalog zone itself.
  `$OLDCATZ` and `$NEWCATZ` are used to discuss migration a member zone from one catalog zone `$OLDCATZ` to another catalog zone `$NEWCATZ`.

Catalog producer
: An entity that generates and is responsible for the contents of the catalog zone.

Catalog consumer
: An entity that extracts information from the catalog zone (such as a DNS
  server that configures itself according to the catalog zone's contents).

# Description {#description}

A catalog zone is a DNS zone whose contents are specially crafted. Its records primarily constitute a list of PTR records referencing other DNS zones (so-called "member zones"). The catalog zone may contain other records indicating additional metadata (so-called "properties") associated with these member zones.

Catalog consumers SHOULD ignore any RR in the catalog zone which is meaningless or useless to the implementation.

Authoritative servers may be preconfigured with multiple catalog zones, each associated with a different set of configurations.

Although the contents of a catalog zone are interpreted and acted upon by
nameservers, a catalog zone is a regular DNS zone and so must adhere to the
standards for such zones.

A catalog zone is primarily intended for the management of a farm of authoritative nameservers.
The content of catalog zones may not be accessible from any recursive nameserver.

# Catalog Zone Structure

## SOA and NS Records

As with any other DNS zone, a catalog zone MUST have a syntactically correct
SOA record and at least one NS record at its apex.

The SOA record's SERIAL, REFRESH, RETRY and EXPIRE fields [@!RFC1035] are used
during zone transfer.  A catalog zone's SOA SERIAL field MUST increase when an
update is made to the catalog zone's contents as per serial number arithmetic
defined in [@!RFC1982].  Otherwise, catalog consumers might not notice
updates to the catalog zone's contents.

There is no requirement to be able to query the catalog zone via recursive nameservers.
Catalog consumers SHOULD ignore NS record at apex.
However, at least one is still required so that catalog zones are syntactically correct DNS zones.
A single NS RR with a NSDNAME field containing the absolute name "invalid." is RECOMMENDED [@!RFC2606;@!RFC6761].

## Member Zones {#listofmemberzones}

The list of member zones is specified as a collection of member nodes, represented by domain names under the owner name "zones" where "zones" is a direct child domain of the catalog zone.

The names of member zones are represented on the RDATA side (instead of as a part of owner names) of a PTR record, so that all valid domain names may be represented regardless of their length [@!RFC1035].
This PTR record MUST be the only record in the PTR RRset with the same name.
More than one record in the RRset denotes a broken catalog zone which MUST NOT be processed (see (#generalrequirements)).
The reason a catalog zone is considered broken SHOULD always be communicated clearly to the operator (e.g. through a log message).

For example, if a catalog zone lists three zones "example.com.",
"example.net." and "example.org.", the member node RRs would appear as follows:

```
<unique-1>.zones.$CATZ 0 IN PTR example.com.
<unique-2>.zones.$CATZ 0 IN PTR example.net.
<unique-3>.zones.$CATZ 0 IN PTR example.org.
```

where `<unique-N>` is a label that tags each record in the collection.
`<unique-N>` has an unique value in the collection.
When different `<unique-N>` labels hold the same PTR value (i.e. point to the same member zone), the catalog zone is broken and MUST NOT be processed (see (#generalrequirements)).

Member node labels carry no informational meaning beyond labeling member zones.
A changed label may indicate that the state for a zone needs to be reset (see (#zonereset)).

Having the zones uniquely tagged with the `<unique-N>` label ensures that additional RRs can be added below the member node (see (#properties)).

The CLASS field of every RR in a catalog zone MUST be IN (1).

The TTL field's value is not defined by this memo.  Catalog zones are
for authoritative nameserver management only and are not intended for general
querying via recursive resolvers.


## Properties

Catalog zone information is stored in the form of "properties".
Catalog consumers SHOULD ignore records they do not understand.

Properties are identified by their name, which is used as an owner name prefix for one or more record sets underneath a member node, with type(s) as appropriate for the respective property.
Record sets that appear at a property owner name known to the catalog consumer but with an unknown RR type, SHOULD be ignored by the consumer.

Known properties with the correct RR type, but which are for some reason
invalid (for example because of an impossible value or because of an illegal
number of RRs in the RRset), denote a broken catalog zone which MUST NOT be
processed (see (#generalrequirements)).
The reason a catalog zone is considered broken SHOULD always be communicated clearly to the operator (e.g. through a log message).

This specification defines a number of so-called properties,
as well as a mechanism to allow implementers to store additional information in the catalog zone with Custom properties, see (#customproperties).
The meaning of such custom properties is determined by the implementation in question.

Some properties are defined at the global level; others are scoped to apply only to a specific member zone.
This document defines a single mandatory global property in (#version). Member-specific properties are described in (#properties).

More properties may be defined in future documents.

### Schema Version (`version` property) {#version}

The catalog zone schema version is specified by an integer value embedded in a TXT RR named `version.$CATZ`.
All catalog zones MUST have a TXT RRset named `version.$CATZ` with exactly one RR.

Catalog consumers MUST NOT apply catalog zone processing to 

  - zones without the `version` property
  - zones with a `version` property with more than one RR in the RRset
  - zones with a `version` property without an expected value in the
    `version.$CATZ` TXT RR

These conditions signify a broken catalog zone which MUST NOT be processed (see
(#generalrequirements)).
The reason a catalog zone is considered broken SHOULD always be communicated clearly to the operator (e.g. through a log message).

For this memo, the value of the `version.$CATZ` TXT RR MUST be set to "2", i.e.:

``` dns-zone
version.$CATZ 0 IN TXT "2"
```

NB: Version 1 was used in a draft version of this memo and reflected
the implementation first found in BIND 9.11.


## Member Zone Properties {#properties}

Each member zone MAY have one or more additional properties, described in this chapter.
These properties are completely optional and catalog consumers SHOULD ignore those it does not understand.
Member zone properties are represented by RRsets below the corresponding member node.

### Change of Ownership (`coo` property) {#cooproperty}

The `coo` property facilitates controlled migration of a member zone from one catalog to another.

A Change Of Ownership is signaled by the `coo` property in the catalog zone currently "owning" the zone.
The name of the new catalog is the value of a PTR record in the relevant coo property in the old catalog.
For example if member "example.com." will migrate from catalog zone `$OLDCATZ` to catalog zone `$NEWCATZ`, this appears in the `$OLDCATZ` catalog zone as follows:

```
<unique-N>.zones.$OLDCATZ 0 IN PTR example.com.
coo.<unique-N>.zones.$OLDCATZ 0 IN PTR $NEWCATZ
```

The PTR RRset MUST consist of a single PTR record.
More than one record in the RRset denotes a broken catalog zone which MUST NOT be processed (see (#generalrequirements)).
The reason a catalog zone is considered broken SHOULD always be communicated clearly to the operator (e.g. through a log message).

When a consumer of catalog zone `$OLDCATZ` receives an update which adds or changes a `coo` property for a member zone in `$OLDCATZ`, it does *not* migrate the member zone immediately.
The migration has to wait for an update of `$NEWCATZ`. in which the member zone is present. The consumer MUST verify, before the actual migration, that `coo` property pointing to `$NEWCATZ` is still present in `$OLDCATZ`.

Unless the member node label (i.e. `<unique-N>`) for the member is the same in `$NEWCATZ`, all associated state for a just migrated zone MUST be reset (see (#zonereset)).
Note that the owner of `$OLDCATZ` allows for the zone associated state to be taken over by the owner of `$NEWCATZ` by default.
To prevent the takeover of state, the owner of `$OLDCATZ` must remove this state by updating the assosiated properties or by performing a zone state reset (see (#zonereset)) before or simultaneous with adding the `coo` property. (see also (#security))

The old owner may remove the member zone containing the `coo` property from `$OLDCATZ` once it has been established that all its consumers have processed the Change of Ownership.


### Groups (`group` property)

With a `group` property, consumer(s) can be signalled to treat some member zones within the catalog zone differently.

The consumer MAY apply different configuration options when processing member zones, based on the value of the `group` property.
The exact handling of configuration referred to by the `group` property value is left to the consumer's implementation and configuration.
The property is defined by a TXT record in the sub-node labelled `group`.

The producer MAY assign a `group` property to all, some, or none of the member zones within a catalog zone.
The producer MAY assign more than one `group` property to one member zone. This will make it possible to transfer group information for different consumer operators in a single catalog zone.
Consumer operators SHOULD namespace their group properties to limit risk of clashes.

The consumer MUST ignore `group` property values it does not understand.

When a consumer sees multiple values in a `group` property of a single member
zone that it *does* understand, it MAY choose to process multiple, any one or
none of them.
This is left to the implementation.

#### Example

```
<unique-1>.zones.$CATZ        0 IN PTR    example.com.
group.<unique-1>.zones.$CATZ  0 IN TXT    nodnssec
<unique-2>.zones.$CATZ        0 IN PTR    example.net.
group.<unique-2>.zones.$CATZ  0 IN TXT    operator-x-sign-with-nsec3
group.<unique-2>.zones.$CATZ  0 IN TXT    operator-y-nsec3

```

The catalog zone (snippet) above is an example where the producer signals how the consumer(s) shall treat DNSSEC for the zones "example.net." and "example.com."

For "example.com.", the consumer might be implemented and configured in the way that the member zone will not be signed with DNSSEC.
For "example.net.", the consumers, at two different operators, might be implemented and configured in the way that the member zone will be signed with a NSEC3 chain.


## Custom Properties (`*.ext` properties) {#customproperties}

Implementations and operators of catalog zones may choose to provide their own properties.
Custom properties can occur both globally, or for a specific member zone.
To prevent a name clash with future properties, such properties should be represented below the label `ext`.

`ext` is not a placeholder, so a custom property would have domains names as follows:

```
; a global custom property:
<your-property>.ext.$CATZ

; a member zone custom property:
<your-property>.ext.<unique-N>.zones.$CATZ
```

`<your-property>` may consist of one or more labels.

Implementations SHOULD namespace their custom properties to limit risk of clashes with other implementations of catalog zones.
For example by including the name of the implementation in the property, e.g. like: `<property-name>.<implementation-name>.ext.$CATZ`.

Implementations MAY use such properties on the member zone level to store additional information about member zones,
for example to flag them for specific treatment.

Further, implementations MAY use custom properties on the global level to store additional information about the catalog zone itself.
While there may be many use cases for this, a plausible one is to store default values for custom properties on the global level,
then overriding them using a property of the same name on the member level (= under the `ext` label of the member node) if so desired.
A property description should clearly say what semantics apply, and whether a property is global, member, or both.

The meaning of the custom properties described in this section is determined by the implementation alone, without expectation of interoperability.
A catalog consumer SHOULD ignore custom properties it does not understand.


# Nameserver Behavior {#behavior}

## General Requirements {#generalrequirements}

As it is a regular DNS zone, a catalog zone can be transferred using DNS zone
transfers among nameservers.

Catalog updates should be automatic, i.e., when a nameserver that supports
catalog zones completes a zone transfer for a catalog zone, it SHOULD apply
changes to the catalog within the running nameserver automatically without any
manual intervention.

Nameservers MAY allow loading and transfer of broken zones with incorrect
catalog zone syntax (as they are treated as regular zones).
The reason a catalog zone is considered broken SHOULD always be communicated clearly to the operator (e.g. through a log message).

When a previously correct catalog zone becomes a broken catalog zone, because
of an update through an incremental transfer or otherwise, it loses its catalog
meaning.
No special processing occurs. Member zones previously configured by this catalog
MUST NOT be removed or reconfigured in any way.

If a name server restarts with a broken catalog zone, the broken catalog SHOULD
NOT prevent the name server from starting up and serving the member zones in
the last valid version of the catalog zone.

Processing of a broken catalog SHALL start (or resume) when the catalog turns
into a correct catalog zone, for example by an additional update (through zone
transfer or updates) fixing the catalog zone.

Similarly, when a catalog zone expires, it loses its catalog meaning and
MUST no longer be processed as such.
No special processing occurs until the zone becomes fresh again.

## Member zone name clash {#nameclash}

If there is a clash between an existing zone's name (either from an existing member zone or otherwise configured zone) and an incoming
member zone's name (via transfer or update), the new instance of the zone MUST
be ignored and an error SHOULD be logged.

A clash between an existing member zone's name and an incoming member zone's name (via transfer or update), may be an attempt to migrate a zone to a different catalog, but should not be treated as one except as described in (#cooproperty).

## Member zone removal {#zoneremoval}

When a member zone is removed from a specific catalog zone, an authoritative server MUST NOT remove the zone and associated state data if the zone was not configured from that specific catalog zone.
Only when the zone was configured from a specific catalog zone, and the zone is removed as a member from that specific catalog zone, the zone and associated state (such as zone data and DNSSEC keys) MUST be removed.

## Member node name change {#namechange}

When via a single update or transfer, the member node's label value (`<unique-N>`) changes, catalog consumers MUST process this as a member zone removal including all the zone's associated state (as described in (#zoneremoval)), immediately followed by processing the member as a newly to be configured zone in the same catalog.
<!-- (adhering to all the stipulations that come with processing a member as a newly to be configured zone, such as anticipating name clashes as described in (#nameclash)) -->

## Migrating member zones between catalogs {#zonemigration}

If all consumers of the catalog zones involved support the `coo` property, it is RECOMMENDED to perform migration of a member zone by following the procedure described in (#cooproperty).
Otherwise a migration of member zone from a catalog zone `$OLDCATZ` to a catalog zone `$NEWCATZ` has to be done by: first removing the member zone from `$OLDCATZ`; second adding the member zone to `$NEWCATZ`.

If in the process of a migration some consumers of the involved catalog zones did not catch the removal of the member zone from `$OLDCATZ` yet (because of a lost packet or down time or otherwise), but did already see the update of `$NEWCATZ`, they may consider the update adding the member zone in `$NEWCATZ` to be a name clash (see (#nameclash)) and as a consequence the member is not migrated to `$NEWCATZ`.
This possibility needs to be anticipated with a member zone migration.
Recovery from such a situation is out of the scope of this document.
It may for example entail a manually forced retransfer of `$NEWCATZ` to consumers after they have been detected to have received and processed the removal of the member zone from `$OLDCATZ`.

## Zone-associated state reset {#zonereset}

It may be desirable to reset state (such as zone data and DNSSEC keys) associated with a member zone.

A zone state reset may be performed by a change of the member node's name (see (#namechange)).

# Implementation and operational Notes {#implementationnotes}

Although any valid domain name can be used for the catalog name $CATZ, it is
RECOMMENDED to use either a domain name owned by the catalog producer, or to
use a name under a suitable Special-Use Domain Name [@!RFC6761].

Catalog zones on secondary nameservers would have to be setup manually, perhaps
as static configuration, similar to how ordinary DNS zones are configured when catalog zones or another automatic configuration mechanism is not in place.
The secondary additionally needs to be configured as a catalog consumer for the catalog zone to enable processing of the member zones in the catalog, such as automatic synchronization of the member zones for secondary service.

Operators of catalog consumers should note that secondary name servers may
receive DNS NOTIFY messages [@!RFC1996] for zones before they are seen as a
newly added member zones to the catalog from which that secondary is
provisioned.

Although they are regular DNS zones, catalog zones contain only information for
the management of a set of authoritative nameservers.  For this reason,
operators may want to limit the systems able to query these zones.

Querying/serving catalog zone contents may be inconvenient via DNS
due to the nature of their representation.
An administrator may therefore want to use a different method for
looking at data inside the catalog zone.  Typical
queries might include dumping the list of member zones, dumping a member zone's
effective configuration, querying a specific property value of a member zone,
etc.  Because of the structure of catalog zones, it may not be possible to
perform these queries intuitively, or in some cases, at all, using DNS QUERY.
For example, it is not possible to enumerate the contents of a multi-valued
property (such as the list of member zones) with a single QUERY.
Implementations are therefore advised to provide a tool that uses either the
output of AXFR or an out-of-band method to perform queries on catalog zones.

Great power comes with great responsibility: Catalog zones simplifies zone
provisioning by orchestrating zones on secondary name servers from a single
data source - the catalog.  Hence, the catalog source has great power and
changes must be treated carefully. For example if the catalog is generated by
some script and this script for whatever reason generates an empty catalog,
millions of member zones may get deleted from their secondaries within seconds
and all the affected domains may be offline in a blink.

# Security Considerations {#security}

As catalog zones are transmitted using DNS zone transfers,
it is RECOMMENDED that catalog zone transfer are protected from unexpected modifications by way of authentication,
for example by using TSIG [@!RFC8945], or Strict or Mutual TLS authentication with DNS Zone transfer over TLS [@!RFC9103].

Use of DNS UPDATE [@!RFC2136] to modify the content of catalog zones SHOULD similarly be authenticated.

Zone transfers of member zones SHOULD similarly be authenticated.
TSIG shared secrets used for member zones SHOULD NOT be mentioned in the catalog zone data.
However, key identifiers may be shared within catalog zones.

Catalog zones reveal the zones served by the consumers of the catalog zone.
It is RECOMMENDED to limit the systems able to query these zones.
It is RECOMMENDED to transfer catalog zones confidentially [@!RFC9103].

As with regular zones, primary and secondary nameservers for a catalog zone may
be operated by different administrators.  The secondary nameservers may be
configured as catalog consumer to synchronize catalog zones from the primary, but the primary's
administrators may not have any administrative access to the secondaries.

Administrative control over what zones are served from the configured name servers shifts completely from the server operator (consumer) to the "owner" (producer) of the catalog zone content.

With migration of member zones between catalogs using the `coo` property, it is possible for the owner of the target catalog (i.e. `$NEWCATZ`) to take over all associated state with the zone from the original owner (i.e. `$OLDCATZ`) by maintaining the same member node label (i.e. `<unique-N>`).
To prevent the takeover of the zone associated state, the original owner has to enforce a zone state reset by changing the member node label (see (#zonereset)) before or simultaneously with adding the `coo` property.

# Acknowledgements

Our deepest thanks and appreciation go to Stephen Morris,
Ray Bellis and Witold Krecicki who initiated this draft and did the bulk of
the work.

Catalog zones originated as the chosen method among various proposals that were
evaluated at ISC for easy zone management.  The chosen method of storing the
catalog as a regular DNS zone was proposed by Stephen Morris.

The initial authors discovered that Paul Vixie's earlier [@Metazones] proposal
implemented a similar approach and reviewed it.  Catalog zones borrows some
syntax ideas from Metazones, as both share this scheme of representing the
catalog as a regular DNS zone.

Thanks to Leo Vandewoestijne. Leo's presentation in the DNS devroom at the
FOSDEM'20 [@FOSDEM20] was one of the motivations to take up and continue the
effort of standardizing catalog zones.

Thanks to Brian Conry, Klaus Darilion, Brian Dickson, Tony Finch, Evan Hunt, Shane Kerr, Patrik Lundin, Matthijs Mekking, Victoria Risk, Petr Spacek and Carsten Strotmann for reviewing draft proposals and offering comments and suggestions.

<reference anchor="FIPS.180-4.2015" target="http://csrc.nist.gov/publications/fips/fips180-4/fips-180-4.pdf">
  <front>
    <title>Secure Hash Standard</title>
    <author>
      <organization>National Institute of Standards and Technology</organization>
    </author>
    <date month="August" year="2015" />
  </front>
  <seriesInfo name="FIPS" value="PUB 180-4" />
</reference>

<reference anchor='Metazones' target='http://family.redbarn.org/~vixie/mz.pdf'>
  <front>
    <title>Federated Domain Name Service Using DNS Metazones</title>
    <author fullname="Paul Vixie" initials="P." surname="Vixie" />
    <date year="2005" />
  </front>
</reference>

<reference anchor="RPZ" target="http://ftp.isc.org/isc/dnsrpz/isc-tn-2010-1.txt">
  <front>
    <title>DNS Response Policy Zones (DNS RPZ)</title>
    <author fullname="Paul Vixie" initials="P." surname="Vixie" />
    <author fullname="Vernon Schryver" initials="V." surname="Schryver" />
    <date year="2010" />
  </front>
</reference>

<reference anchor='FOSDEM20' target='https://archive.fosdem.org/2020/schedule/event/dns_catz/'>
  <front>
    <title>Extending Catalog zones - another approach in automating maintenance</title>
    <author fullname="Leo Vandewoestijne" initials="L." surname="Vandewoestijne" />
    <date year="2020" />
  </front>
</reference>

{backmatter}

# Implementation Status

**Note to the RFC Editor**: please remove this entire appendix before publication.

In the following implementation status descriptions, "DNS Catalog Zones" refers
to DNS Catalog Zones as described in this document.

* Knot DNS 3.1 (released August 2, 2021) supports full producing and consuming of catalog zones, including the group property.

* PowerDNS has a proof of concept external program called
  [PowerCATZ](https://github.com/PowerDNS/powercatz/), that can process DNS
  Catalog Zones.

* Proof of concept [python scripts](https://github.com/IETF-Hackathon/NSDCatZ)
  that can be used for both generating and consuming DNS Catalog Zones with NSD
  have been developed during the hackathon at the IETF-109.

* BIND 9.18.3+ supports version 2 catalog zones as described in this document

Interoperability between the above implementations has been tested during the
hackathon at the IETF-109.

# Change History

**Note to the RFC Editor**: please remove this entire appendix before publication.

* draft-muks-dnsop-dns-catalog-zones-00

> Initial public draft.

* draft-muks-dnsop-dns-catalog-zones-01

> Added Witold, Ray as authors.  Fixed typos, consistency issues.
  Fixed references.  Updated Area.  Removed newly introduced custom
  RR TYPEs.  Changed schema version to 1.  Changed TSIG requirement
  from MUST to SHOULD.  Removed restrictive language about use of
  DNS QUERY.  When zones are introduced into a catalog zone, a
  primary SHOULD first make the new zones available for transfers
  first (instead of MUST).  Updated examples, esp. use IPv6 in
  examples per Fred Baker.  Add catalog zone example.

* draft-muks-dnsop-dns-catalog-zones-02

> Addressed some review comments by Patrik Lundin.

* draft-muks-dnsop-dns-catalog-zones-03

> Revision bump.

* draft-muks-dnsop-dns-catalog-zones-04

> Reordering of sections into more logical order.
  Separation of multi-valued properties into their own category.

* draft-toorop-dnsop-dns-catalog-zones-00

> New authors to pickup the editor pen on this draft

> Remove data type definitions for zone properties
  Removing configuration of member zones through zone properties altogether

> Remove Open issues and discussion Appendix, which was about zone options (including primary/secondary relationships) only.

* draft-toorop-dnsop-dns-catalog-zones-01

> Added a new section "The Serial Property", introducing a new mechanism
  which can help with disseminating zones from the primary to the secondary
  nameservers in a timely fashion more reliably.

> Three different ways to provide a "serial" property with a member zone are
  offered to or the workgroup for discussion.

> Added a new section "Implementation Status", listing production ready,
  upcoming and Proof of Concept implementations, and reporting on
  interoperability of the different implementations.

* draft-toorop-dnsop-dns-catalog-zones-02

> Adding the `coo` property for zone migration in a controlled fashion

> Adding the `group` property for reconfigure settings of member zones
  in an atomic update

> Adding the `epoch` property to reset zone associated state in a controlled fashion

* draft-toorop-dnsop-dns-catalog-zones-03

> Big cleanup!

> Introducing the terms catalog consumer and catalog producer

> Reorganized topics to create a more coherent whole

> Properties all have consistent format now

> Try to assume the least possible from implementations w.r.t.:

> 1) Predictability of the <unique-N> IDs of member zones

> 2) Whether or not fallback catalog zones can be found for a member

> 3) Whether or not a catalog consumer can maintain state

* draft-toorop-dnsop-dns-catalog-zones-04

> Move Implementation status to appendix

> Miscellaneous textual improvements

> `coo` property points to `$NEWCATZ` (and not `zones.$NEWCATZ`)

> Remove suggestion to increase serial and remove member zone from `$OLDCATZ` after migration

> More consistent usage of the terms catalog consumer and catalog producer throughout the document

> Better (safer) description of resetting refresh timers of member zones with the `serial` property

> Removing a member MUST remove zone associated state

> Make authentication requirements a bit less prescriptive in security considerations

> Updated implementation status for KnotDNS

> Describe member node name changes and update "Zone associated state reset" to use that as the mechanism for it.

> Add Peter Thomassen as co-author

> Complete removal of the `epoch` property.  We consider consumer optimizations with predictable member node labels (for example based on a hash) out of the scope of this document.

> Miscellaneous editorial improvements

* draft-toorop-dnsop-dns-catalog-zones-05

> Add Kees Monshouwer as co-author

> Removed the "serial" property

> Allow custom properties on the global level

* draft-toorop-dnsop-dns-catalog-zones-06

> Move administrative control explanation to Security Considerations

> Move comment on query methods to Implementation Notes

> Clarify what happens on expiry

> Clarify catalog consumer behavior when MUST condition is violated

> Better text on ordering of operations for Change of Ownership

> Suggest to namespace custom properties

> Clarify how to handle property record with wrong type

> Cover the case of multiple different <unique-N>'s having the same value

> Recommendations for naming catalog zones

> Add and operational note about notifies for not yet existing zones

> Add text about name server restarts with broken zones

> Great power comes with great responsibility (Thanks Klaus!)

> Mention the new BIND implementation

> All invalid properties cause a broken catalog zone, including invalid `group` and `version` properties.

> Add Aram Sargsyan as author (he did the BIND9 implementation)

> `group` properties can have more than one value
