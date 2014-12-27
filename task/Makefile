# File options
INPUT=Dokumentation.markdown
OUTPUT=Dokumentation

# Converter options
ENV=LANG=de_DE.utf8
CONVERTER=pandoc
LATEXOPTS=-V geometry:margin=1in
CONVOPTS=-s

all: pdf html

html:
	$(ENV) $(CONVERTER) $(INPUT) $(CONVOPTS) $(LATEXOPTS) -o $(OUTPUT).html

pdf:
	$(ENV) $(CONVERTER) $(INPUT) $(CONVOPTS) $(LATEXOPTS) -o $(OUTPUT).pdf


clean:
	rm -f $(OUTPUT).pdf
	rm -f $(OUTPUT).html
