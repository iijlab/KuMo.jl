PREFIX = main
SRC = $(PREFIX).tex
BIB = $(PREFIX)
PDF = $(PREFIX).pdf
LATEX = pdflatex

all:$(SRC)
	target=$(PDF)
	$(LATEX) $(SRC)
	bibtex $(BIB)
	$(LATEX) $(SRC)
	bibtex $(BIB)
	$(LATEX) $(SRC)

.PHONY: clean

clean:
	rm -f ${PREFIX}.pdf ${PREFIX}.log ${PREFIX}.dvi ${PREFIX}.blg ${PREFIX}.bbl $(PREFIX).out *.bst *.aux *~
