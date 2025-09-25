setenv LMC_TIMEUNIT -9
vlib work
vmap work work

# grayscale architecture
vlog -work work "../sv/fifo.sv"
vlog -work work "../sv/fifo_ctrl.sv"
vlog -work work "../sv/parser.sv"
vlog -work work "../sv/udp_top.sv"
#vlog -work work "../sv/udp_tb.sv"

# uvm library
vlog -work work +incdir+$env(UVM_HOME)/src $env(UVM_HOME)/src/uvm.sv
vlog -work work +incdir+$env(UVM_HOME)/src $env(UVM_HOME)/src/uvm_macros.svh
vlog -work work +incdir+$env(UVM_HOME)/src $env(MTI_HOME)/verilog_src/questa_uvm_pkg-1.2/src/questa_uvm_pkg.sv

# uvm package
vlog -work work +incdir+$env(UVM_HOME)/src "../uvm/my_uvm_pkg.sv"
vlog -work work +incdir+$env(UVM_HOME)/src "../uvm/my_uvm_tb.sv"

# start uvm simulation
vsim -classdebug -voptargs=+acc +notimingchecks -L work work.my_uvm_tb -wlf my_uvm_tb.wlf -sv_lib lib/uvm_dpi -dpicpppath /usr/bin/gcc +incdir+$env(MTI_HOME)/verilog_src/questa_uvm_pkg-1.2/src/

# start basic simulation
#vsim -voptargs=+acc +notimingchecks -L work work.udp_tb -wlf udp_tb.wlf

do udp_wave_uvm.do
#do udp_wave.do

run -all
#quit;