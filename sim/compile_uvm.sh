#!/bin/bash
vcs -j4 -cm line+cond+fsm+tgl+branch+assert -sverilog -ntb_opts uvm -timescale=1ns/1ps -lca +incdir+../tb/uvm     -f filelist_uvm.f     dpi_softfloat.c     -CFLAGS "-I/home/guy/Sagi/riscv_processor/spike_install/include/softfloat"     -LDFLAGS "-L/home/guy/Sagi/riscv_processor/spike_install/lib -lsoftfloat -Wl,-rpath=/home/guy/Sagi/riscv_processor/spike_install/lib"     -o simv_uvm
