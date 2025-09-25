`ifndef __GLOBALS__
`define __GLOBALS__

// UVM Globals
localparam string FILE_IN_NAME  = "../udp/test.pcap";
localparam string FILE_OUT_NAME = "../sim/test_output.txt";
localparam string FILE_CMP_NAME = "../udp/test.txt";

localparam PCAP_FILE_HEADER_SIZE = 24;
localparam PCAP_PACKET_HEADER_SIZE = 16;




//localparam int IMG_WIDTH = 720;
//localparam int IMG_HEIGHT = 540;
//localparam int BMP_HEADER_SIZE = 54;
localparam int BYTES_PER_PIXEL = 1;
//localparam int BMP_DATA_SIZE = (IMG_WIDTH * IMG_HEIGHT * BYTES_PER_PIXEL);
localparam int CLOCK_PERIOD = 10;

`endif
