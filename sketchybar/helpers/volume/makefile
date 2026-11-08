bin/volume: volume.c | bin
	clang -std=c99 -O3 -framework CoreAudio -framework AudioToolbox $< -o $@

bin:
	mkdir bin
