.SUFFIXES: .md .html

all: about.html implementations.html

.md.html:
	pandoc -B menu.html -s --css=github.css --to=html5 --highlight-style=haddock \
       --self-contained -o $@ $<

