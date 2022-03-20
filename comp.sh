#!/bin/bash

nasm -g -f elf64 -o printf.o -l printf.list  printf.asm
ld -o printf printf.o
