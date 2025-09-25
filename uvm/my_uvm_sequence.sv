import uvm_pkg::*;


class my_uvm_transaction extends uvm_sequence_item;
    logic [23:0] image_pixel;
    logic wr_eof; 
    logic wr_sof;
    
    function new(string name = "");
        super.new(name);
    endfunction: new

    `uvm_object_utils_begin(my_uvm_transaction)
        `uvm_field_int(image_pixel, UVM_ALL_ON)
    `uvm_object_utils_end
endclass: my_uvm_transaction


class my_uvm_sequence extends uvm_sequence#(my_uvm_transaction);
    `uvm_object_utils(my_uvm_sequence)

    function new(string name = "");
        super.new(name);
    endfunction: new

    task body();        
        my_uvm_transaction tx;
        int in_file, n_bytes=0, i=0;
        logic [0:PCAP_FILE_HEADER_SIZE-1] [7:0] file_header;
        logic [0:PCAP_PACKET_HEADER_SIZE-1] [7:0] packet_header;
        logic [7:0] pixel;
        logic [7:0] data;
        int j;
        logic [31:0] packet_size;

        
        //tx.wr_sof = 1'b0;
        //tx.wr_eof = 1'b0;

        `uvm_info("SEQ_RUN", $sformatf("Loading file %s...", FILE_IN_NAME), UVM_LOW);

        in_file = $fopen(FILE_IN_NAME, "rb");
        if ( !in_file ) begin
            `uvm_fatal("SEQ_RUN", $sformatf("Failed to open file %s...", FILE_IN_NAME));
        end

        // read PCAP header
        i = $fread(file_header, in_file, 0, PCAP_FILE_HEADER_SIZE);

        while ( !$feof(in_file)) begin

            
            // read pcap packet header & get packet length
            packet_header = {(PCAP_PACKET_HEADER_SIZE){8'h00}};
            i += $fread(packet_header, in_file, i, PCAP_PACKET_HEADER_SIZE);
            packet_size = {<<8{packet_header[8:11]}};
            //$display("Packet size: %d", packet_size);
            // iterate through packet length
            j = 0;
            //packet_size = packet_size+1;
            while (j < packet_size) begin

                tx = my_uvm_transaction::type_id::create(.name("tx"), .contxt(get_full_name()));
                start_item(tx);

                i += $fread(data, in_file, i, 1);
                tx.wr_sof = j == 0 ? 1'b1 : 1'b0;
                if (tx.wr_sof ==1) begin 
                   $display("tx.wr_sof = %d", tx.wr_sof);     
                end 
                tx.wr_eof = j == packet_size-1 ? 1'b1 : 1'b0;
                tx.image_pixel = data;
                finish_item(tx);
                j++;
            end
        end

        `uvm_info("SEQ_RUN", $sformatf("Closing file %s...", FILE_IN_NAME), UVM_LOW);
        $fclose(in_file);
    endtask: body
endclass: my_uvm_sequence

typedef uvm_sequencer#(my_uvm_transaction) my_uvm_sequencer;
