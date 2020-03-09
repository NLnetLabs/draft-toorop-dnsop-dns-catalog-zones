VERSION = 00
DOCNAME = draft-toorop-dnsop-dns-catalog-zones

all: $(DOCNAME)-$(VERSION).txt $(DOCNAME)-$(VERSION).html

$(DOCNAME)-$(VERSION).txt: $(DOCNAME).xml
	xml2rfc --text -o $@ $<

$(DOCNAME)-$(VERSION).html: $(DOCNAME).xml
	xml2rfc --html -o $@ $<

$(DOCNAME).xml: $(DOCNAME).md
	sed 's/@DOCNAME@/$(DOCNAME)-$(VERSION)/g' $< | mmark --xml2 --page > $@

clean:
	rm -f $(DOCNAME)-$(VERSION).txt $(DOCNAME)-$(VERSION).html
