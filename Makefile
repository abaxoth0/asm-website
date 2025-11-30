main: server.asm
	fasm ./server.asm
run: server.asm
	fasm ./server.asm && ./server
