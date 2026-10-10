run:
	odin run . -linker:radlink 
build:
	odin build . -out:bin/tetris.exe -o:minimal -linker:radlink 
	
debug-build:
	odin build . -debug
clean:
	del bin\*.*
# 	del tetris.pdb