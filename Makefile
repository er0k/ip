.PHONY: build build-static push

build:
	crystal build -s -p -t src/*

install:
	install ip /usr/local/bin/ip.r0k

build-static:
	crystal build -s -p -t --static src/*

