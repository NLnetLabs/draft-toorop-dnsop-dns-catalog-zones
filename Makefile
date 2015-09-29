all: draft-muks-dnsop-dns-catalog-zones.txt draft-muks-dnsop-dns-catalog-zones.html

draft-muks-dnsop-dns-catalog-zones.txt: draft-muks-dnsop-dns-catalog-zones.xml
	xml2rfc $<

draft-muks-dnsop-dns-catalog-zones.html: draft-muks-dnsop-dns-catalog-zones.xml
	xml2rfc --html $<
