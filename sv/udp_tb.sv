
`timescale 1 ns / 1 ns

module udp_tb;

localparam string PCAP_IN_NAME  = "../udp/test.pcap";
localparam string FILE_OUT_NAME = "../udp/test_output.txt";
localparam string FILE_CMP_NAME = "../udp/test.txt";
localparam CLOCK_PERIOD = 10;
localparam DATA_WIDTH = 8;

logic clock = 1'b1;
logic reset = '0;
logic start = '0;
logic done  = '0;

logic        in_full;
logic        in_wr_en;
logic [7:0]  in_din;
logic        out_rd_en;
logic        out_empty;
logic  [7:0] out_dout;

logic   in_wr_sof;    
logic   in_wr_eof;   

logic   hold_clock    = '0;
logic   in_write_done = '0;
logic   out_read_done = '0;
integer out_errors    = '0;


localparam PCAP_FILE_HEADER_SIZE = 24;
localparam PCAP_PACKET_HEADER_SIZE = 16;

udp_top #(
) udp_top_inst(
    .reset(reset),
    .clock(clock),
    .wr_en(in_wr_en),
    .wr_sof(in_wr_sof),
    .wr_eof(in_wr_eof),
    .data_din(in_din),
    .full(in_full),
    .out_rd_en(out_rd_en),
    .out_dout(out_dout),
    .out_empty(out_empty)
);

always begin
    clock = 1'b1;
    #(CLOCK_PERIOD/2);
    clock = 1'b0;
    #(CLOCK_PERIOD/2);
end

initial begin
    @(posedge clock);
    reset = 1'b1;
    @(posedge clock);
    reset = 1'b0;
end

initial begin : tb_process
    longint unsigned start_time, end_time;

    @(negedge reset);
    @(posedge clock);
    start_time = $time;

    // start
    $display("@ %0t: Beginning simulation...", start_time);
    start = 1'b1;
    @(posedge clock);
    start = 1'b0;

    wait(out_read_done);
    end_time = $time;

    // report metrics
    $display("@ %0t: Simulation completed.", end_time);
    $display("Total simulation cycle count: %0d", (end_time-start_time)/CLOCK_PERIOD);
    $display("Total error count: %0d", out_errors);

    // end the simulation
    $finish;
end

int packet_size;

initial begin : pcap_read_process
    int i, j;
    
    int in_file;
    logic [0:PCAP_FILE_HEADER_SIZE-1] [7:0] file_header;
    logic [0:PCAP_PACKET_HEADER_SIZE-1] [7:0] packet_header;
    @(negedge reset);
    $display("@ %0t: Loading file %s...", $time, PCAP_IN_NAME);
    in_file = $fopen(PCAP_IN_NAME, "rb");
    in_wr_en = 1'b0;
    in_wr_sof = 1'b0;
    in_wr_eof = 1'b0;
    // Skip PCAP Global header
    i = $fread(file_header, in_file, 0, PCAP_FILE_HEADER_SIZE);
    // Read data from image file
    while (!$feof(in_file)) begin
        // read pcap packet header & get packet length
        packet_header = {(PCAP_PACKET_HEADER_SIZE){8'h00}};
        i += $fread(packet_header, in_file, i, PCAP_PACKET_HEADER_SIZE);
        packet_size = {<<8{packet_header[8:11]}};
        $display("Packet size: %d", packet_size);
        // iterate through packet length
        j = 0;
        while (j < packet_size) begin
            @(negedge clock);
            if (in_full == 1'b0) begin
                i += $fread(in_din, in_file, i, 1);
                in_wr_en = 1'b1;
                in_wr_sof = j == 0 ? 1'b1 : 1'b0;
                in_wr_eof = j == packet_size-1 ? 1'b1 : 1'b0;
                j++;
            end else begin
                in_wr_en = 1'b0;
                in_wr_sof = 1'b0;
                in_wr_eof = 1'b0;
            end
        end
    end
    @(negedge clock);
    in_wr_en = 1'b0;
    in_wr_sof = 1'b0;
    in_wr_eof = 1'b0;
    $fclose(in_file);
    in_write_done = 1'b1;
end

initial begin : img_write_process
    int i, r;
    int out_file;
    int cmp_file;
    logic [23:0] cmp_dout;
    //logic [7:0] bmp_header [0:BMP_HEADER_SIZE-1];

    @(negedge reset);
    @(negedge clock);

    $display("@ %0t: Comparing file %s...", $time, FILE_OUT_NAME);
    
    out_file = $fopen(FILE_OUT_NAME, "wb");
    //cmp_file = $fopen(IMG_CMP_NAME, "rb");
    out_rd_en = 1'b0;
    
    // Copy the BMP header
    //r = $fread(bmp_header, cmp_file, 0, BMP_HEADER_SIZE);
    //for (i = 0; i < BMP_HEADER_SIZE; i++) begin
    //    $fwrite(out_file, "%c", bmp_header[i]);
    //end

    i = 0;
    while (i < packet_size*4) begin
        @(negedge clock);
        out_rd_en = 1'b0;
        
        if (out_empty == 1'b0) begin
            $fwrite(out_file, "test output");
            //r = $fread(cmp_dout, cmp_file, BMP_HEADER_SIZE+i, BYTES_PER_PIXEL);
            $fwrite(out_file, "%c", out_dout);

            //if (cmp_dout != {3{out_dout}}) begin
            //    out_errors += 1;
             //   $write("@ %0t: %s(%0d): ERROR: %x != %x at address 0x%x.\n", $time, IMG_OUT_NAME, i+1, {3{out_dout}}, cmp_dout, i);
            end
            out_rd_en = 1'b1;
            i += 1;
        end
    

    @(negedge clock);
    out_rd_en = 1'b0;
    $fclose(out_file);
    $fclose(cmp_file);
    out_read_done = 1'b1;
end






endmodule


/*
initial begin : txt_write_process
    integer fd, z, count;
    logic [DATA_WIDTH-1:0] z_data_cmp, z_data_read;
    z_rd_addr = '0;

    @(negedge reset);
    wait(done);
    @(negedge clock);

    $display("@ %0t: Comparing file %s...", $time, Z_NAME);
    
    fd = $fopen(Z_NAME, "r");

    for (z = 0; z < VECTOR_SIZE; z++) begin
        @(negedge clock);
        z_rd_addr = z;
        @(negedge clock);
        count = $fscanf(fd, "%h", z_data_cmp);
        z_data_read = z_dout;
        if (z_data_read != z_data_cmp) begin
            
            z_errors++;
            $display("@ %0t: %s(%0d): ERROR: %h != %h at address 0x%h.", $time, Z_NAME, z+1, z_data_read, z_data_cmp, z);
        end
        @(posedge clock);
    end
    $fclose(fd);
    z_read_done = 1'b1;
end



*/


/*
initial begin : img_read_process
    int i, r;
    int in_file;
    logic [7:0] bmp_header [0:BMP_HEADER_SIZE-1];

    @(negedge reset);
    $display("@ %0t: Loading file %s...", $time, IMG_IN_NAME);

    in_file = $fopen(IMG_IN_NAME, "rb");
    in_wr_en = 1'b0;

    // Skip BMP header
    r = $fread(bmp_header, in_file, 0, BMP_HEADER_SIZE);

    // Read data from image file
    i = 0;
    while ( i < BMP_DATA_SIZE ) begin
        @(negedge clock);
        in_wr_en = 1'b0;
        if (in_full == 1'b0) begin
            r = $fread(in_din, in_file, BMP_HEADER_SIZE+i, BYTES_PER_PIXEL);
            in_wr_en = 1'b1;
            i += BYTES_PER_PIXEL;
        end
    end

    @(negedge clock);
    in_wr_en = 1'b0;
    $fclose(in_file);
    in_write_done = 1'b1;
end

initial begin : img_write_process
    int i, r;
    int out_file;
    int cmp_file;
    logic [23:0] cmp_dout;
    logic [7:0] bmp_header [0:BMP_HEADER_SIZE-1];

    @(negedge reset);
    @(negedge clock);

    $display("@ %0t: Comparing file %s...", $time, IMG_OUT_NAME);
    
    out_file = $fopen(IMG_OUT_NAME, "wb");
    cmp_file = $fopen(IMG_CMP_NAME, "rb");
    out_rd_en = 1'b0;
    
    // Copy the BMP header
    r = $fread(bmp_header, cmp_file, 0, BMP_HEADER_SIZE);
    for (i = 0; i < BMP_HEADER_SIZE; i++) begin
        $fwrite(out_file, "%c", bmp_header[i]);
    end

    i = 0;
    while (i < BMP_DATA_SIZE) begin
        @(negedge clock);
        out_rd_en = 1'b0;
        if (out_empty == 1'b0) begin
            r = $fread(cmp_dout, cmp_file, BMP_HEADER_SIZE+i, BYTES_PER_PIXEL);
            $fwrite(out_file, "%c%c%c", out_dout, out_dout, out_dout);

            if (cmp_dout != {3{out_dout}}) begin
                out_errors += 1;
                $write("@ %0t: %s(%0d): ERROR: %x != %x at address 0x%x.\n", $time, IMG_OUT_NAME, i+1, {3{out_dout}}, cmp_dout, i);
            end
            out_rd_en = 1'b1;
            i += BYTES_PER_PIXEL;
        end
    end

    @(negedge clock);
    out_rd_en = 1'b0;
    $fclose(out_file);
    $fclose(cmp_file);
    out_read_done = 1'b1;
end

endmodule
*/

//////////////



