all:
	cl65 -tcx16 main.c polygon_array.c scanline_c.s waitforjiffy.s -o main.prg -Or -Ois --codesize 20
