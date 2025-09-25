module fifo_ctrl #(
parameter FIFO_DATA_WIDTH = 8,
parameter FIFO_BUFFER_SIZE = 1024)
(
input logic reset,
input logic wr_clk, //
input logic wr_en, //
input logic wr_sof,//
input logic wr_eof,//
input logic [FIFO_DATA_WIDTH-1:0] data_din,//
output logic full,//
input logic rd_clk,//
input logic rd_en,//
output logic rd_sof,//
output logic rd_eof,//
output logic [FIFO_DATA_WIDTH-1:0] data_dout,//
output logic empty//
);

logic [1:0] ctrl_din;
logic data_full;
logic ctrl_full;
logic data_empty;
logic ctrl_empty;

logic [1:0] ctrl_dout;

assign ctrl_din = {wr_eof, wr_sof}; 
assign full = data_full || ctrl_full;
assign empty = data_empty || ctrl_empty;

assign rd_eof = ctrl_dout[1]; 
assign rd_sof = ctrl_dout[0];


fifo #(
    .FIFO_BUFFER_SIZE(1024),
    .FIFO_DATA_WIDTH(8)
) fifo_data(
    .reset(reset),
    .wr_clk(wr_clk),
    .wr_en(wr_en),
    .din(data_din),
    .full(data_full),
    .rd_clk(rd_clk),
    .rd_en(rd_en),
    .dout(data_dout),
    .empty(data_empty)
);



fifo #(
    .FIFO_BUFFER_SIZE(1024),
    .FIFO_DATA_WIDTH(2)
) fifo_ctrl(
    .reset(reset),
    .wr_clk(wr_clk),
    .wr_en(wr_en),
    .din(ctrl_din),
    .full(ctrl_full),
    .rd_clk(rd_clk),
    .rd_en(rd_en),
    .dout(ctrl_dout),
    .empty(ctrl_empty)
);





endmodule 