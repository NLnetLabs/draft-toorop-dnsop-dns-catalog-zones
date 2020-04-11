%%%
Title = "DNS Catalog Zones"
abbrev = "dns-catalog-zones"
docname = "@DOCNAME@"
category = "std"
ipr = "trust200902"
area = "Internet"
workgroup = "DNSOP Working Group"
date = 2020-03-09T23:59:00Z

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
initials="L."
surname="Vandewoestijne"
fullname="Leo Vandewoestijne"
[author.address]
 email = "leo@dns.company"
[author.address.postal]
 country = "Netherlands"
%%%


.# Abstract

This document describes a method for automatic DNS zone provisioning among DNS
primary and secondary nameservers by storing and transferring the catalog of
zones to be provisioned as one or more regular DNS zones.

{mainmatter}


# Introduction

The data in a DNS zone is synchronized amongst its primary and secondary
nameservers using AXFR and IXFR.  However, the list of zones served by the
primary (called a catalog in [@!RFC1035]) is not automatically synchronized
with the secondaries.  To add or remove a zone, the administrator of a DNS
nameserver farm not only has to add or remove the zone from the primary, they
must also add/remove the zone from all secondaries, either manually or via an
external application.  This can be both inconvenient and error-prone; it is 
also dependent on the nameserver implementation.

This document describes a method in which the catalog is represented as a
regular DNS zone (called a "catalog zone" here), and transferred using DNS zone
transfers.  As zones are added to or removed from the catalog zone, the changes
are propagated to the secondary nameservers in the normal way.  The secondary
nameservers then add/remove/modify the zones they serve in accordance with the
changes to the zone.

The contents and representation of catalog zones are described in (#description).
Nameserver behavior is described in (#behavior).

# Terminology

The key words "**MUST**", "**MUST NOT**", "**REQUIRED**",
"**SHALL**", "**SHALL NOT**", "**SHOULD**", "**SHOULD NOT**",
"**RECOMMENDED**", "**NOT RECOMMENDED**", "**MAY**", and
"**OPTIONAL**" in this document are to be interpreted as described in
BCP 14 [@!RFC2119] [@!RFC8174] when, and only when, they appear in all
capitals, as shown here.

Catalog zone
: A DNS zone containing a DNS catalog, that is, a list of DNS zones and
  associated zone configuration.

Member zone
: A DNS zone whose configuration is published inside a catalog zone.

Zone property
: A configuration parameter of a zone, sometimes also called a zone option,
  represented as a key/value pair.
  This document does not describe or define zone properties.
  Implementations of catalog zones however may have Zone properties defined.

$CATZ
: Used in examples as a placeholder to represent the domain name of the
  catalog zone itself (c.f. $ORIGIN).

# Description {#description}

A catalog zone is a specially crafted DNS zone that contains, as DNS zone data:

* A list of DNS zones (called "member zones").

An implementation of catalog zones MAY have 

* Default zone configuration information common to all member zones.

* Zone-specific configuration information.

Zone properties are not described nor defined in this document.
Implementations of catalog zones MAY have zone properties defined.
Implementations of catalog zones SHOULD ignore zone properties or any other RR in the catalog zone which is meaningless or useless to the implementation.

An implementation of catalog zones MAY allow the catalog to contain other
catalog zones as member zones, but default zone configuration present in a
catalog zone only applies to its immediate member zones.

Although the contents of a catalog zone are interpreted and acted upon by
nameservers, a catalog zone is a regular DNS zone and so must adhere to the
standards for such zones.

A catalog zone is primarily intended for the management of a farm of
authoritative nameservers.  It is not expected that the content of catalog
zones will be accessible from any recursive nameserver.

# Catalog Zone Structure

## SOA and NS Records

As with any other DNS zone, a catalog zone MUST have a syntactically correct
SOA record and at least one NS record at its apex.

The SOA record's SERIAL, REFRESH, RETRY and EXPIRE fields [@!RFC1035] are used
during zone transfer.  A catalog zone's SOA SERIAL field MUST increase when an
update is made to the catalog zone's contents as per serial number arithmetic
defined in [@!RFC1982].  Otherwise, secondary nameservers might not notice
updates to the catalog zone's contents.

Should the zone be made available for querying, the SOA record's MINIMUM
field's value is the negative cache time (as defined in [@!RFC2308]).  Since
recursive nameservers are not expected to be able to access (and subsequently
cache) entries from a catalog zone a value of zero (0) is RECOMMENDED.

There is no requirement to be able to query the catalog zone via recursive nameservers.
Implementations of catalog zones MUST ignore and MUST NOT assume or require NS records at the apex.
However, at least one is still required so that catalog zones are syntactically correct DNS zones.
A single NS RR with an NSDNAME field containing the absolute name "invalid." is RECOMMENDED [@!RFC2606].

## Catalog Zone Schema Version

The catalog zone schema version is specified by an unsigned integer property
with the property name "version".  All catalog zones MUST have this property
present.  Primary and secondary nameservers MUST NOT use catalog zones with an
unexpected value in this property, but they may be transferred as ordinary
zones.  For this memo, the "version" property value MUST be set to 2, i.e.

~~~ ascii-art
version.$CATZ 0 IN TXT "2"
~~~

NB: Version 1 was used in a draft version of this memo and reflected
the implementation first found in BIND 9.11.

## List of Member Zones {#listofmemberzones}

The list of member zones is specified as a collection of domain names under the owner name "zones" where "zones" is a direct child domain of the catalog zone.

The names of member zones are represented on the RDATA side (instead of as a part of owner names) so that all valid domain names may be represented regardless of their length [@!RFC1035].

For example, if a catalog zone lists three zones "example.com.",
"example.net." and "example.org.", the RRs would appear as follows:

~~~ asci-art
<m-unique-1>.zones.$CATZ 0 IN PTR example.com.
<m-unique-2>.zones.$CATZ 0 IN PTR example.net.
<m-unique-3>.zones.$CATZ 0 IN PTR example.org.
~~~

where `<m-unique-N>` is a label that uniquely tags each record in the collection.

The reason for the `<m-unique-N>` label is that catalog zones could contain a larger number of zones.
The number of zones might be larger than that what can be conveyed in a single "zones" RRset in a zone transfer.
Uniquely tagging each zone makes sure the list can be split over multiple transfer messages.

The CLASS field of every RR in a catalog zone MUST be IN (1).

The TTL field's value is not specially defined by this memo.  Catalog zones are
for authoritative nameserver management only and are not intended for general
querying via recursive resolvers and therefore a value of zero (0) is
RECOMMENDED.

It is an error for any single owner name within a catalog zone (other
than the apex of the zone itself) to have more than one RR associated
with it.

## Zone properties {#zoneproperties}

TBD: Remove this section too?

Zone properties are not described nor defined in this document.
Catalog zones are still advantageous without zone properties.
Authoritative server could be preconfigured with multiple catalog zones, each associated with a different set of configurations.
A member zone can be reconfigured with a different set of preconfigured settings by removing it as a member of one catalog zone and making it a member of another.

Implementations of catalog zones MAY have zone properties defined.
Implementations of catalog zones SHOULD ignore zone properties or any other RR in the catalog zone which is meaningless or useless to the implementation.

When implementations do have zone properties, it is RECOMMENDED those properties are in the spots described in (#defaultzoneconfig) and (#memberzoneconfig).
When implementations do have zone properties, the property names MUST NOT start with "cz-"; i.e. the letter "C" followed by the letter "Z" followed by a dash ("-").

### Default Zone Configuration {#defaultzoneconfig}

Default zone configuration comprises a set of properties that are applied to
all member zones listed in the catalog zone unless overridden my member
zone-specific information.

All such properties are stored as child nodes of the owner name "defaults"
itself a direct child node of the catalog zone, e.g.:

~~~ ascii-art
<property-name>.defaults.$CATZ 0 IN TXT "Example"
~~~

where `<property-name>` does not start with "cz-";

### Zone Properties Specific to a Member Zone {#memberzoneconfig}

Default zone properties can be overridden on a per-zone basis by specifying the
property under the sub-domain associated with the member zone in the list
of zones, e.g.:

~~~ ascii-art
<property-name>.<m-unique>.zones.$CATZ 0 IN TXT "Example"
~~~

where "m-unique" is the label that uniquely identifies the member zone name as described in (#listofmemberzones) and where `<property-name>` does not start with "cz-".

### Vendor-specific Properties

TBD: Prepare a list of zone configuration properties that are common to DNS
implementations.  This is so that a company may manage a catalog zone using a
Windows DNS server as the primary, and a secondary nameserver hosting service
may pick up the common properties and may use a different nameserver
implementation such as BIND or NSD on a POSIX operating system to serve it.

TBD: Any list of zone properties is ideally maintained as a registry rather
than within this memo.

# Nameserver Behavior {#behavior}

## General Requirements

As it is a regular DNS zone, a catalog zone can be transferred using DNS zone
transfers among nameservers.

Although they are regular DNS zones, catalog zones contain only information for
the management of a set of authoritative nameservers.  For this reason,
operators may want to limit the systems able to query these zones.  It may be
inconvenient to serve some contents of catalog zones via DNS queries anyway due
to the nature of their representation.  A separate method of querying entries
inside the catalog zone may be made available by nameserver implementations
(see (#implementationnotes)).

Catalog updates should be automatic, i.e., when a nameserver that supports
catalog zones completes a zone transfer for a catalog zone, it SHOULD apply
changes to the catalog within the running nameserver automatically without any
manual intervention.

As with regular zones, primary and secondary nameservers for a catalog zone may
be operated by different administrators.  The secondary nameservers may be
configured to synchronize catalog zones from the primary, but the primary's
administrators may not have any administrative access to the secondaries.

A catalog zone can be updated via DNS UPDATE on a reference primary nameserver,
or via zone transfers.  Nameservers MAY allow loading and transfer of broken
zones with incorrect catalog zone syntax (as they are treated as regular
zones), but nameservers MUST NOT process such broken zones as catalog
zones.  For the purpose of catalog processing, the broken catalogs MUST be
ignored.  If a broken catalog zone was transferred, the newly transferred
catalog zone MUST be ignored (but the older copy of the catalog zone SHOULD
be left running subject to values in SOA fields).

If there is a clash between an existing member zone's name and an incoming
member zone's name (via transfer or update), the new instance of the zone MUST
be ignored and an error SHOULD be logged.

When zones are introduced into a catalog zone, a primary SHOULD first make the
new zones available for transfers before making the updated catalog zone
available for transfer, or sending NOTIFY for the catalog zone to secondaries.
Note that secondary nameservers may attempt to transfer the catalog zone upon
refresh timeout, so care must be taken to make the member zones available
before any update to the list of member zones is visible in the catalog zone.

When zones are deleted from a catalog zone, a primary MAY delete the member
zone immediately after notifying secondaries.  It is up to the secondary
nameserver to handle this condition correctly.

TBD: Transitive primary-secondary relationships

# Updating Catalog Zones

TBD: Explain updating catalog zones using DNS UPDATE.

## Implementation Notes {#implementationnotes}

Catalog zones on secondary nameservers would have to be setup manually, perhaps
as static configuration, similar to how ordinary DNS zones are configured.
Members of such catalog zones will be automatically synchronized by the
secondary after the catalog zone is configured.

An administrator may want to look at data inside a catalog zone.  Typical
queries might include dumping the list of member zones, dumping a member zone's
effective configuration, querying a specific property value of a member zone,
etc.  Because of the structure of catalog zones, it may not be possible to
perform these queries intuitively, or in some cases, at all, using DNS QUERY.
For example it is not possible to enumerate the contents of a multi-valued
property (such as the list of member zones) with a single QUERY.
Implementations are therefore advised to provide a tool that uses either the
output of AXFR or an out-of-band method to perform queries on catalog zones.

# Security Considerations

As catalog zones are transmitted using DNS zone transfers, it is absolutely
essential for these transfers to be protected from unexpected modifications on
the route.  So, catalog zone transfers SHOULD be authenticated using TSIG
[@!RFC2845].  A primary nameserver SHOULD NOT serve a catalog zone for transfer
without using TSIG and a secondary nameserver SHOULD abandon an update to a
catalog zone that was received without using TSIG.

Use of DNS UPDATE [@!RFC2136] to modify the content of catalog zones SHOULD
similarly be authenticated using TSIG.

Zone transfers of member zones SHOULD similarly be authenticated using TSIG
[@!RFC2845].  The TSIG shared secrets used for member zones MUST NOT be mentioned
anywhere in the catalog zone data.  However, key identifiers may be shared
within catalog zones.

Catalog zones do not need to be signed using DNSSEC, their zone transfers being
authenticated by TSIG.  Signed zones MUST be handled normally by nameservers,
and their contents MUST NOT be DNSSEC- validated.

# IANA Considerations

This document has no IANA actions.

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

Thanks to Brian Conry, Tony Finch, Evan Hunt, Patrik Lundin, Victoria Risk and
Carsten Strettman for reviewing draft proposals and offering comments and
suggestions.

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

<reference anchor='Metazones' target='http://ss.vix.su/~vixie/mz.pdf'>
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

{backmatter}

# Open issues and discussion (to be removed before final publication)

Config options
: We want catalog zones to be adopted by multiple DNS implementations.  Towards
  this, we have to generalize zone config options and adopt a minimal set that
  we can expect most implementations to support.

Catalog zone and member zones on different primary nameservers
: Will it be possible to setup a catalog zone on one nameserver as
  primary, and allow its member zones to be served by different
  primary nameservers?

Transitive relationships
: For a catalog zone, a secondary nameserver may be a primary
  nameserver to a different set of nameservers in a nameserver
  farm.  In these transitive relationships, zone configuration
  options (such as also-notify and allow-transfer) may differ based
  on the location of the primary in the hierarchy.  It may not be
  possible to specify this within a catalog zone.

Overriding controls
: A way to override zone config options (as prescribed by the
  catalog zones) on secondary nameservers was requested.  As this
  would be configured outside catalog zones, it may be better to
  leave this to implementations.

# Change History (to be removed before final publication)

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

* draft-toorop-dnsop-dns-catalog-zones-01

> Remove data type definitions for zone properties
