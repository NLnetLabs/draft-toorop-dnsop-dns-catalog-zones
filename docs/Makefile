PAGES = about.html implementations.html

.SUFFIXES: .md .html

all: $(PAGES) draft-ietf-dnsop-dns-catalog-zones.html
clean:
	rm -f $(PAGES) draft-ietf-dnsop-dns-catalog-zones.html

draft-ietf-dnsop-dns-catalog-zones.html: ../draft-ietf-dnsop-dns-catalog-zones-00.html menu.html
	awk '{print}/^<body>$$/{system("cat menu.html")}' $< >$@

.md.html:
	pandoc -B menu.html -s --css=github.css --to=html5 --highlight-style=haddock \
       --self-contained -o $@ $<

$(PAGES): menu.html

