CL = cl65.exe

all:
	$(CL) -tcx16 main.c polygon_array.c scanline_c.s polygon_helpers.s waitforjiffy.s -o main.prg -Or -Ois --codesize 20
