module udp_top#(
    parameter FIFO_DATA_WIDTH = 8
)
(
input logic reset,
input logic clock,
input logic wr_en, 
input logic wr_sof,
input logic wr_eof,
input logic [FIFO_DATA_WIDTH-1:0] data_din,
output logic full,
input logic out_rd_en,
output logic [FIFO_DATA_WIDTH-1:0] out_dout,
output logic out_empty

);

// ctrl fifo <--> parser

logic rd_sof;
logic rd_eof;
logic [FIFO_DATA_WIDTH-1:0] ctrl_dout;
logic ctrl_empty;
logic ctrl_rd_en;

// parser <--> output fifo


logic out_wr_en;
logic out_full;
logic [FIFO_DATA_WIDTH-1:0] parser_out;

fifo_ctrl #(
    .FIFO_DATA_WIDTH(FIFO_DATA_WIDTH),
    .FIFO_BUFFER_SIZE(1024)
)
fifi_ctrl_inst(
    .reset(reset),
    .wr_clk(clock),
    .wr_en(wr_en),
    .wr_sof(wr_sof),
    .wr_eof(wr_eof),
    .data_din(data_din),
    .full(full),
    .rd_clk(clock),
    .rd_en(ctrl_rd_en),
    .rd_sof(rd_sof),
    .rd_eof(rd_eof),
    .data_dout(ctrl_dout),
    .empty(ctrl_empty)
);

parser #(
    .DATA_WIDTH(FIFO_DATA_WIDTH)
)
parser_inst(
    .clock(clock),
    .reset(reset),
    .in_rd_en(ctrl_rd_en),
    .in_empty(ctrl_empty),
    .in_dout(ctrl_dout),
    .out_wr_en(out_wr_en),
    .out_full(out_full),
    .parser_out(parser_out),
    .rd_sof(rd_sof),
    .rd_eof(rd_eof)
);

// output fifo 

fifo #(
    .FIFO_BUFFER_SIZE(1024),
    .FIFO_DATA_WIDTH(8)
) fifo_out_inst (
    .reset(reset),
    .wr_clk(clock),
    .wr_en(out_wr_en),
    .din(parser_out),
    .full(out_full),
    .rd_clk(clock),
    .rd_en(out_rd_en),
    .dout(out_dout),
    .empty(out_empty)
);




endmodule