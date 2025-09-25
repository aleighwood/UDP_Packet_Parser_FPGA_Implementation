

#add wave -noupdate -group edge_detect_tb
#add wave -noupdate -group edge_detect_tb -radix decimal /edge_detect_tb/*

#add wave -noupdate -group edge_detect_tb/edge_detect_inst
#add wave -noupdate -group edge_detect_tb/edge_detect_inst -radix decimal /edge_detect_tb/edge_detect_inst/*

#add wave -noupdate -group edge_detect_tb/edge_detect_inst/edge_detect_inst
#add wave -noupdate -group edge_detect_tb/edge_detect_inst/edge_detect_inst -radix decimal /edge_detect_tb/edge_detect_inst/edge_detect_inst/*

#add wave -noupdate -group edge_detect_tb/edge_detect_inst/grayscale_top_inst
#add wave -noupdate -group edge_detect_tb/edge_detect_inst/grayscale_top_inst -radix decimal /edge_detect_tb/edge_detect_inst/grayscale_top_inst/*

#add wave -noupdate -group edge_detect_tb/edge_detect_inst/grayscale_top_inst/fifo_out_inst
#add wave -noupdate -group edge_detect_tb/edge_detect_inst/grayscale_top_inst -radix decimal /edge_detect_tb/edge_detect_inst/grayscale_top_inst/fifo_out_inst/*

#add wave -noupdate -group edge_detect_tb/edge_detect_inst/sobel_inst
#add wave -noupdate -group edge_detect_tb/edge_detect_inst/sobel_inst -radix decimal /edge_detect_tb/edge_detect_inst/sobel_inst/*

#add wave -noupdate -group edge_detect_tb/edge_detect_inst/fifo_out_inst
#add wave -noupdate -group edge_detect_tb/edge_detect_inst/fifo_out_inst -radix decimal /edge_detect_tb/edge_detect_inst/fifo_out_inst/*

add wave -noupdate -group udp_tb -radix hexadecimal /udp_tb/*
add wave -noupdate -group udp_tb/udp_top_inst -radix hexadecimal /udp_tb/udp_top_inst/*
add wave -noupdate -group udp_tb/udp_top_inst/parser_inst -radix hexadecimal /udp_tb/udp_top_inst/parser_inst/*
add wave -noupdate -group udp_tb/udp_top_inst/parser_inst/fifo_internal_inst -radix hexadecimal /udp_tb/udp_top_inst/parser_inst/fifo_internal_inst/*

