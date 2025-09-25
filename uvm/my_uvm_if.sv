import uvm_pkg::*;

interface my_uvm_if;
    logic        clock;
    logic        reset;
    logic        in_wr_en;
    logic     wr_sof;
    logic     wr_eof;
    logic [7:0] in_din;
    logic        in_full;
    logic       out_rd_en;
    logic      out_empty;
    logic [7:0] out_dout;
endinterface