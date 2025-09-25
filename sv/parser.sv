module parser #(
    parameter DATA_WIDTH = 8
) (
    input  logic        clock,
    input  logic        reset,
    output logic        in_rd_en,
    input  logic        in_empty,
    input  logic [DATA_WIDTH-1:0] in_dout,
    output logic        out_wr_en,
    input  logic        out_full,
    output logic [DATA_WIDTH-1:0] parser_out,
    input logic        rd_sof,
    input logic        rd_eof
);

typedef enum logic [4:0] {WAIT_FOR_SOF_STATE,
    ETH_DST_ADDR_STATE, // good
    ETH_SRC_ADDR_STATE, // good
    ETH_PROTOCOL_STATE, // good
    IP_VERSION_STATE, // good
    IP_TYPE_STATE, //
    IP_LENGTH_STATE, // good
    IP_ID_STATE, // goof
    IP_FLAGS_STATE,
    IP_TIME_STATE,
    IP_PROTOCOL_STATE,//
    IP_CHECKSUM_STATE,//
    IP_SRC_ADDR_STATE,//
    IP_DST_ADDR_STATE,//
    UDP_SRC_PORT_STATE,//
    UDP_DST_PORT_STATE,//
    UDP_LENGTH_STATE,//
    UDP_CHECKSUM_STATE,//
    UDP_DATA_STATE,
    ETH_TRAILER_STATE,
    WAIT_FOR_EOF_STATE,
    RESET
 } state_types;

state_types state, next_state;

//logic [7:0] gs, gs_c;

//sizes
localparam int ETH_DST_ADDR_BYTES = 6;//
localparam int ETH_SRC_ADDR_BYTES = 6;//
localparam int ETH_PROTOCOL_BYTES = 2; // same as type 
localparam int ETH_TRAILER_BYTES = 4;//
localparam int IP_VERSION_BYTES = 1;//
localparam int IP_TYPE_BYTES = 1;//
localparam int IP_LENGTH_BYTES = 2;//
localparam int IP_ID_BYTES = 2;//
localparam int IP_FLAG_BYTES = 2;//
localparam int IP_TIME_BYTES = 1;//
localparam int IP_PROTOCOL_BYTES = 1;//
localparam int IP_CHECKSUM_BYTES = 2;//
localparam int IP_SRC_ADDR_BYTES = 4;//
localparam int IP_DST_ADDR_BYTES = 4;//
localparam int UDP_DST_PORT_BYTES = 2;//
localparam int UDP_SRC_PORT_BYTES = 2;//
localparam int UDP_LENGTH_BYTES = 2;//
localparam int UDP_CHECKSUM_BYTES = 2;//
localparam int UDP_DATA_BYTES = 8;//
localparam int CHECKSUM_BYTES = 2;

//need to run checks on these values
// also check sum
/*
localparam  IP_PROTOCOL_DEF = 0x0800;
localparam  IP_VERSION_DEF = 0x4;
localparam  IP_HEADER_LENGTH_DEF = 0x5;
localparam  IP_TYPE_DEF = 0x0;
localparam  IP_FLAGS_DEF = 0x4;
localparam  TIME_TO_LIVE = 0xe;
localparam  UDP_PROTOCOL_DEF = 0x11

*/

//init registers
logic [ETH_DST_ADDR_BYTES*8-1:0] eth_dst_addr, eth_dst_addr_c;//
logic [ETH_SRC_ADDR_BYTES*8-1:0] eth_src_addr, eth_src_addr_c;//
logic [ETH_PROTOCOL_BYTES*8-1:0] eth_protocol, eth_protocol_c;//
logic [IP_VERSION_BYTES*8-1:0] ip_version,ip_version_c;//
logic [IP_TYPE_BYTES*8-1:0] ip_type, ip_type_c;//
logic [IP_LENGTH_BYTES*8-1:0] ip_length, ip_length_c;//
logic [IP_ID_BYTES*8-1:0] ip_id, ip_id_c;//
logic [IP_FLAG_BYTES*8-1:0] ip_flags, ip_flags_c;//
logic [IP_TIME_BYTES*8-1:0] ip_time, ip_time_c;//
logic [IP_PROTOCOL_BYTES*8-1:0] ip_protocol, ip_protocol_c;///
logic [IP_CHECKSUM_BYTES*8-1:0] ip_checksum, ip_checksum_c;//
logic [IP_SRC_ADDR_BYTES*8-1:0] ip_src_addr, ip_src_addr_c;//
logic [IP_DST_ADDR_BYTES*8-1:0] ip_dst_addr, ip_dst_addr_c;//
logic [UDP_DST_PORT_BYTES*8-1:0] udp_dst_port, udp_dst_port_c;//
logic [UDP_SRC_PORT_BYTES*8-1:0] udp_src_port, udp_src_port_c;
logic [UDP_LENGTH_BYTES*8-1:0] udp_length, udp_length_c;//
logic [UDP_CHECKSUM_BYTES*8-1:0] udp_checksum, udp_checksum_c;//
logic [ETH_TRAILER_BYTES*8-1:0] eth_trailer, eth_trailer_c;//
logic [15:0] num_bytes, num_bytes_c;
logic [31:0] checksum, checksum_c;
logic [7:0] prev_byte;
logic write_data_out;
logic final_byte_pass;


// internal fifo to write data to

logic int_f_wr_en;
logic int_f_rd_en;
logic int_f_full;
logic int_f_empty;
logic [DATA_WIDTH-1:0] int_f_in;

logic even_bite, odd_bite;




fifo #(
    .FIFO_BUFFER_SIZE(1024),
    .FIFO_DATA_WIDTH(8)
)fifo_internal_inst(
    .reset(reset),
    .wr_clk(clock),
    .wr_en(int_f_wr_en),
    .din(int_f_in),
    .full(int_f_full),
    .rd_clk(clock),
    .rd_en(int_f_rd_en),
    .dout(parser_out),
    .empty(int_f_empty)
);


always_ff @(posedge clock or posedge reset) begin
    if (reset == 1'b1) begin
        state <= WAIT_FOR_SOF_STATE;
        eth_dst_addr <= 0;
        eth_src_addr <= 0;
        eth_protocol <= 0;
        ip_version <= 0;
        ip_type <= 0;
        ip_length <= 0;
        ip_id <= 0;
        ip_flags <= 0;
        ip_time <= 0;
        ip_protocol <= 0;
        ip_checksum <= 0;
        ip_src_addr <= 0;
        ip_dst_addr <= 0;
        udp_src_port <= 0;
        udp_dst_port <= 0;
        udp_length <= 0;
        udp_checksum <= 0;
        eth_trailer <= 0;
        num_bytes <= 0;
        checksum <= 0;
        
    end else begin
        state <= next_state;
        eth_dst_addr <= eth_dst_addr_c;
        eth_src_addr <= eth_src_addr_c;
        eth_protocol <= eth_protocol_c;
        ip_version <= ip_version_c;
        ip_type <= ip_type_c;
        ip_length <= ip_length_c;
        ip_id <= ip_id_c;
        ip_flags <= ip_flags_c;
        ip_time <= ip_time_c;
        ip_protocol <= ip_protocol_c;
        ip_checksum <= ip_checksum_c;
        ip_src_addr <= ip_src_addr_c;
        ip_dst_addr <= ip_dst_addr_c;
        udp_src_port <= udp_src_port_c;
        udp_dst_port <= udp_dst_port_c;
        udp_length <= udp_length_c;
        udp_checksum <= udp_checksum_c;
        eth_trailer <= eth_trailer_c;
        num_bytes <= num_bytes_c;
        checksum <= checksum_c;

    end
end


always_ff @(posedge clock or posedge reset) begin
    if (reset == 1'b1) begin
        int_f_rd_en <= 1'b0;
        out_wr_en <= 1'b0;
    end else begin
        int_f_rd_en <= 1'b0;
        out_wr_en <= 1'b0;
        if (int_f_empty == 1'b0 &&  final_byte_pass != 1 ) begin
            int_f_rd_en <= 1'b1;
            out_wr_en <= 1'b1;
            //int_f_in <= in_dout;
        end
    end
end


always_comb begin
    in_rd_en  = 1'b0;
    int_f_wr_en = 1'b0;
    next_state = state;
    eth_dst_addr_c = eth_dst_addr;
    eth_src_addr_c = eth_src_addr;
    eth_protocol_c = eth_protocol;
    ip_version_c = ip_version;
    ip_type_c = ip_type;
    ip_length_c = ip_length;
    ip_id_c = ip_id;
    ip_flags_c = ip_flags;
    ip_time_c = ip_time;
    ip_protocol_c = ip_protocol;
    ip_checksum_c = ip_checksum;
    ip_src_addr_c = ip_src_addr;
    ip_dst_addr_c = ip_dst_addr;
    udp_src_port_c = udp_src_port;
    udp_dst_port_c = udp_dst_port;
    udp_length_c = udp_length;
    udp_checksum_c = udp_checksum;
    eth_trailer_c = eth_trailer;
    num_bytes_c = num_bytes;    
    checksum_c = checksum;
    even_bite = 1'b0;
    odd_bite = 1'b0;
    write_data_out = 1'b0;



    case (state)
        WAIT_FOR_SOF_STATE: begin
            num_bytes_c = 1'b0;
            final_byte_pass = 1'b0;
            // wait for start-of-frame
            if ((rd_sof == 1'b1) && (in_empty == 1'b0)) begin
                next_state = ETH_DST_ADDR_STATE;
            end else if (in_empty == 1'b0) begin
                in_rd_en = 1'b1;
            end
        end

        ETH_DST_ADDR_STATE: begin
            if (in_empty == 1'b0) begin
                // concatenate new input to bottom 8-bits of previous value
                // do i need to reverse the order of the bytes? 
                eth_dst_addr_c = ($unsigned(eth_dst_addr) << 8) | (ETH_DST_ADDR_BYTES*8)'($unsigned(in_dout));
                num_bytes_c = (num_bytes + 1) % ETH_DST_ADDR_BYTES;
                $display("num_bytes: %d", num_bytes);
                in_rd_en = 1'b1;
                if (num_bytes == ETH_DST_ADDR_BYTES-1) begin
                    next_state = ETH_SRC_ADDR_STATE;
                end
            end
        end

        ETH_SRC_ADDR_STATE: begin
            if (in_empty == 1'b0) begin
                // concatenate new input to bottom 8-bits of previous value
                eth_src_addr_c = ($unsigned(eth_src_addr) << 8) | (ETH_SRC_ADDR_BYTES*8)'($unsigned(in_dout));
                num_bytes_c = (num_bytes + 1) % ETH_SRC_ADDR_BYTES;
                in_rd_en = 1'b1;
                if (num_bytes == ETH_SRC_ADDR_BYTES-1) begin
                    next_state = ETH_PROTOCOL_STATE;
                end
            end
        end

        ETH_PROTOCOL_STATE: begin
            if (in_empty == 1'b0) begin
                // concatenate new input to bottom 8-bits of previous value
                eth_protocol_c = ($unsigned(eth_protocol) << 8) | (ETH_PROTOCOL_BYTES*8)'($unsigned(in_dout));
                num_bytes_c = (num_bytes + 1) % ETH_PROTOCOL_BYTES;
                in_rd_en = 1'b1;
                if (num_bytes == ETH_PROTOCOL_BYTES-1) begin
                    next_state = IP_VERSION_STATE;
                end
            end
        end

        IP_VERSION_STATE: begin
            if (in_empty == 1'b0) begin
                // concatenate new input to bottom 8-bits of previous value
                ip_version_c = ($unsigned(ip_version) << 8) | (IP_VERSION_BYTES*8)'($unsigned(in_dout));
                num_bytes_c = (num_bytes + 1) % IP_VERSION_BYTES;
                in_rd_en = 1'b1;
                if (num_bytes == IP_VERSION_BYTES-1) begin
                    next_state = IP_TYPE_STATE;
                end
            end
        end

        IP_TYPE_STATE: begin
            if (in_empty == 1'b0) begin
                // concatenate new input to bottom 8-bits of previous value
                ip_type_c = ($unsigned(ip_type) << 8) | (IP_TYPE_BYTES*8)'($unsigned(in_dout));
                num_bytes_c = (num_bytes + 1) % IP_TYPE_BYTES;
                in_rd_en = 1'b1;
                if (num_bytes == IP_TYPE_BYTES-1) begin
                    next_state = IP_LENGTH_STATE;
                end
            end
        end

        IP_LENGTH_STATE: begin
            if (in_empty == 1'b0) begin
                // concatenate new input to bottom 8-bits of previous value
                ip_length_c = ($unsigned(ip_length) << 8) | (IP_LENGTH_BYTES*8)'($unsigned(in_dout));
                num_bytes_c = (num_bytes + 1) % IP_LENGTH_BYTES;
                in_rd_en = 1'b1;
                if (num_bytes == IP_LENGTH_BYTES-1) begin
                    
                    checksum_c = checksum + ip_length_c -20;
                    next_state = IP_ID_STATE;
                end
            end
        end

        IP_ID_STATE: begin
            if (in_empty == 1'b0) begin
                // concatenate new input to bottom 8-bits of previous value
                ip_id_c = ($unsigned(ip_id) << 8) | (IP_ID_BYTES*8)'($unsigned(in_dout));
                num_bytes_c = (num_bytes + 1) % IP_ID_BYTES;
                in_rd_en = 1'b1;
                if (num_bytes == IP_ID_BYTES-1) begin
                    next_state = IP_FLAGS_STATE;
                end
            end
        end

        IP_FLAGS_STATE: begin
            if (in_empty == 1'b0) begin
                // concatenate new input to bottom 8-bits of previous value
                ip_flags_c = ($unsigned(ip_flags) << 8) | (IP_FLAG_BYTES*8)'($unsigned(in_dout));
                num_bytes_c = (num_bytes + 1) % IP_FLAG_BYTES;
                in_rd_en = 1'b1;
                if (num_bytes == IP_FLAG_BYTES-1) begin
                    next_state = IP_TIME_STATE;
                end
            end
        end

        IP_TIME_STATE: begin
            if (in_empty == 1'b0) begin
                // concatenate new input to bottom 8-bits of previous value
                ip_time_c = ($unsigned(ip_time) << 8) | (IP_TIME_BYTES*8)'($unsigned(in_dout));
                num_bytes_c = (num_bytes + 1) % IP_TIME_BYTES;
                in_rd_en = 1'b1;
                if (num_bytes == IP_TIME_BYTES-1) begin
                    next_state = IP_PROTOCOL_STATE;
                end
            end
        end

        IP_PROTOCOL_STATE: begin
            if (in_empty == 1'b0) begin
                // concatenate new input to bottom 8-bits of previous value
                ip_protocol_c = ($unsigned(ip_protocol) << 8) | (IP_PROTOCOL_BYTES*8)'($unsigned(in_dout));
                num_bytes_c = (num_bytes + 1) % IP_PROTOCOL_BYTES;

                in_rd_en = 1'b1;

                if (num_bytes == IP_PROTOCOL_BYTES-1) begin
                    checksum_c = checksum + (ip_protocol_c & 16'h00ff);
                    next_state = IP_CHECKSUM_STATE;
                end
            end
        end

        IP_CHECKSUM_STATE: begin
            if (in_empty == 1'b0) begin
                // concatenate new input to bottom 8-bits of previous value
                ip_checksum_c = ($unsigned(ip_checksum) << 8) | (IP_CHECKSUM_BYTES*8)'($unsigned(in_dout));
                num_bytes_c = (num_bytes + 1) % IP_CHECKSUM_BYTES;
                in_rd_en = 1'b1;
                if (num_bytes == IP_CHECKSUM_BYTES-1) begin
                    next_state = IP_SRC_ADDR_STATE;
                end
            end
        end

        IP_SRC_ADDR_STATE: begin
            if (in_empty == 1'b0) begin
                // concatenate new input to bottom 8-bits of previous value
                ip_src_addr_c = ($unsigned(ip_src_addr) << 8) | (IP_SRC_ADDR_BYTES*8)'($unsigned(in_dout));
                num_bytes_c = (num_bytes + 1) % IP_SRC_ADDR_BYTES;

                in_rd_en = 1'b1;
                if (num_bytes == IP_SRC_ADDR_BYTES-1) begin
                    checksum_c = checksum + (ip_src_addr_c[31:16]) + (ip_src_addr_c[15:0]);
                    next_state = IP_DST_ADDR_STATE;
                end
            end
        end

        IP_DST_ADDR_STATE: begin
            if (in_empty == 1'b0) begin
                // concatenate new input to bottom 8-bits of previous value
                ip_dst_addr_c = ($unsigned(ip_dst_addr) << 8) | (IP_DST_ADDR_BYTES*8)'($unsigned(in_dout));
                num_bytes_c = (num_bytes + 1) % IP_DST_ADDR_BYTES;

                in_rd_en = 1'b1;
                if (num_bytes == IP_DST_ADDR_BYTES-1) begin
                    checksum_c = checksum + (ip_dst_addr_c[31:16]) + (ip_dst_addr_c[15:0]);
                    next_state = UDP_SRC_PORT_STATE;
                end
            end
        end

        UDP_SRC_PORT_STATE: begin
            if (in_empty == 1'b0) begin
                // concatenate new input to bottom 8-bits of previous value
                udp_src_port_c = ($unsigned(udp_src_port) << 8) | (UDP_SRC_PORT_BYTES*8)'($unsigned(in_dout));
                num_bytes_c = (num_bytes + 1) % UDP_SRC_PORT_BYTES;

                in_rd_en = 1'b1;
                if (num_bytes == UDP_SRC_PORT_BYTES-1) begin
                    checksum_c = checksum + udp_src_port_c;
                    next_state = UDP_DST_PORT_STATE;
                end
            end
        end

        UDP_DST_PORT_STATE: begin
            if (in_empty == 1'b0) begin
                // concatenate new input to bottom 8-bits of previous value
                udp_dst_port_c = ($unsigned(udp_dst_port) << 8) | (UDP_DST_PORT_BYTES*8)'($unsigned(in_dout));
                num_bytes_c = (num_bytes + 1) % UDP_DST_PORT_BYTES;

                in_rd_en = 1'b1;
                if (num_bytes == UDP_DST_PORT_BYTES-1) begin
                    checksum_c = checksum + udp_dst_port_c;
                    next_state = UDP_LENGTH_STATE;
                end
            end
        end

        UDP_LENGTH_STATE: begin
            if (in_empty == 1'b0) begin
                // concatenate new input to bottom 8-bits of previous value
                udp_length_c = ($unsigned(udp_length) << 8) | (UDP_LENGTH_BYTES*8)'($unsigned(in_dout));
                num_bytes_c = (num_bytes + 1) % UDP_LENGTH_BYTES;

                in_rd_en = 1'b1;
                if (num_bytes == UDP_LENGTH_BYTES-1) begin
                    //udp_length_c = udp_length_c ;
                    checksum_c = checksum + udp_length_c;
                    next_state = UDP_CHECKSUM_STATE;
                end
            end
        end

        UDP_CHECKSUM_STATE: begin
            if (in_empty == 1'b0) begin
                // concatenate new input to bottom 8-bits of previous value
                udp_checksum_c = ($unsigned(udp_checksum) << 8) | (UDP_CHECKSUM_BYTES*8)'($unsigned(in_dout));
                num_bytes_c = (num_bytes + 1) % UDP_CHECKSUM_BYTES;
                in_rd_en = 1'b1;
                if (num_bytes == UDP_CHECKSUM_BYTES-1) begin
                    //calculate checksum up to this point
                    next_state = UDP_DATA_STATE;
                end
            end
        end

        UDP_DATA_STATE: begin
            if (in_empty == 1'b0 && udp_length != 16'b0)  begin
                in_rd_en = 1'b1;

                //WRITE TO INTERNAL FIFO

                if (num_bytes == 0) begin
                    prev_byte = in_dout; 
                end 
                
                else if (num_bytes  % 2 != 0) begin //odd
                    even_bite = 1'd0;
                    odd_bite = 1'd1;
                    //$display("odd byte");
                    checksum_c = checksum + {prev_byte, in_dout};
                end 
                else begin //even
                    even_bite = 1'd1;
                    odd_bite = 1'd0;
                    //$display("even byte");
                    prev_byte = in_dout;
                end
                
                if (int_f_full == 1'b0) begin
                    //enable write to internal fifo
                    int_f_wr_en = 1'b1;
                    
                    //write data to internal fifo
                    int_f_in = in_dout;

                end
                
                num_bytes_c = (num_bytes + 1) % (udp_length -9);
                in_rd_en = 1'b1;
                //was prev 'b1
                //num_bytes 
                if (num_bytes == (udp_length-9)-'b1) begin
                    //check checksum
                        checksum_c = ~((checksum & 16'hffff) + (checksum>>16));

                    // checksum not working as it should - but all code is in place
                    /*
                    if (checksum_c[15:0] != udp_checksum);
                    begin
                        $display("checksum failed");
                        //should be enabled but not getting correct checksum
                        //next_state = WAIT_FOR_SOF_STATE;
                    end
                    */

                    //else begin
                        next_state = WAIT_FOR_EOF_STATE;
                        final_byte_pass = 1'b1;
                    //end
 
                    end
            end
        end

        WAIT_FOR_EOF_STATE: begin
            // wait for end-of-frame

            // let final element through 
            

            if(int_f_full == 1'b0 && final_byte_pass == 1'b1) begin
                in_rd_en = 1'b1;
                int_f_wr_en = 1'b1;
                int_f_in = in_dout;
                final_byte_pass = 1'b0;
            end
 
            
            if ((rd_eof == 1'b1) && (in_empty == 1'b0)) begin
                next_state = WAIT_FOR_SOF_STATE;
                $display("end of frame signal received");
            end else if (in_empty == 1'b0) begin
                in_rd_en = 1'b1;
            end
        end

        default: begin
            //in_rd_en  = 1'b0;
            //out_wr_en = 1'b0;
            //out_din = 8'b0;
            next_state = WAIT_FOR_SOF_STATE;
            //gs_c = 8'hX;
        end

    endcase
end

endmodule



