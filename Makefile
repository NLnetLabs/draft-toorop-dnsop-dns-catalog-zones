all: draft-muks-dns-catalog-zones.txt draft-muks-dns-catalog-zones.html

draft-muks-dns-catalog-zones.txt: draft-muks-dns-catalog-zones.xml
	xml2rfc $<

draft-muks-dns-catalog-zones.html: draft-muks-dns-catalog-zones.xml
	xml2rfc --html $<
