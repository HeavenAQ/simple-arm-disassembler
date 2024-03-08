EXE := main

.PHONY: all clean

all:
	as -g -o $(EXE).o $(EXE).s
    ld -o $(EXE) $(EXE).o

clean:
	rm -f $(EXE) $(EXE).o
