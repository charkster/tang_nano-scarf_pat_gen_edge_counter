
module scarf_regmap_2_edge_counters
  ( input  logic	    clk,
    input  logic	    rst_n_sync,
    input  logic  [7:0] data_in,
    input  logic	    data_in_valid,
    input  logic	    data_in_finished,
    input  logic  [6:0] slave_id,
    input  logic        rnw,
    output logic  [7:0] read_data_out,
    output logic  [3:0] cfg_trig_out,
    output logic  [3:0] cfg_in_inv,
    output logic  [3:0] enable,
    output logic  [3:0] trig_enable,
    input  logic [31:0] d1_count_0,
    input  logic [31:0] d2_count_0,
    input  logic [31:0] d3_count_0,
    input  logic [31:0] d1_count_1,
    input  logic [31:0] d2_count_1,
    input  logic [31:0] d3_count_1
    );

    parameter SLAVE_ID    = 7'h03;
    parameter MAX_ADDRESS = 6'd25; // 6bit address
    parameter NUM_WRITE_REGS = 2;
 
 
    logic [7:0] registers [1:0];
    logic [5:0] address;
    logic       first_byte;
    logic       final_byte;
    logic       valid_slave;
    logic       valid_read;
    logic       valid_write;
    logic       first_byte_slave_id;
     
    assign valid_slave = (slave_id == SLAVE_ID);
    
    always_ff @(posedge clk, negedge rst_n_sync)
      if (~rst_n_sync)                       first_byte <= 1'd1;
      else if (data_in_finished)             first_byte <= 1'd1;
      else if (data_in_valid && valid_slave) first_byte <= 1'd0;
    
    always_ff @(posedge clk, negedge rst_n_sync)
        if (~rst_n_sync)                                                  address <= 'd0;
        else if (data_in_finished)                                        address <= 'd0;
        else if (valid_slave && data_in_valid && first_byte)              address <= data_in[5:0];
        else if (valid_slave && data_in_valid && (address < MAX_ADDRESS)) address <= address + 1'b1;
        
    always_ff @(posedge clk, negedge rst_n_sync)
        if (~rst_n_sync)                                                                    final_byte <= 1'b0;
        else if (data_in_finished)                                                          final_byte <= 1'b0;
        else if (valid_slave && data_in_valid && (!first_byte) && (address == MAX_ADDRESS)) final_byte <= 1'b1;
 
    assign valid_read = valid_slave && rnw && (!first_byte) && (!final_byte);
    
    assign first_byte_slave_id = valid_slave && rnw && first_byte;
    
    // each edge counter has 12 bytes of address space, 2 counters will have 24 (plus 2 shared config bytes)
    always_comb
      if (first_byte_slave_id)                   read_data_out[7:0] = {1'b0,SLAVE_ID};
      else if (valid_read && (address == 6'd0))  read_data_out[7:0] = registers[0][7:0];
      else if (valid_read && (address == 6'd1))  read_data_out[7:0] = registers[1][7:0];
      else if (valid_read && (address == 6'd2))  read_data_out[7:0] = d1_count_0[7:0];
      else if (valid_read && (address == 6'd3))  read_data_out[7:0] = d1_count_0[15:8];
      else if (valid_read && (address == 6'd4))  read_data_out[7:0] = d1_count_0[23:16];
      else if (valid_read && (address == 6'd5))  read_data_out[7:0] = d1_count_0[31:24];
      else if (valid_read && (address == 6'd6))  read_data_out[7:0] = d2_count_0[7:0];
      else if (valid_read && (address == 6'd7))  read_data_out[7:0] = d2_count_0[15:8];
      else if (valid_read && (address == 6'd8))  read_data_out[7:0] = d2_count_0[23:16];
      else if (valid_read && (address == 6'd9))  read_data_out[7:0] = d2_count_0[31:24];
      else if (valid_read && (address == 6'd10)) read_data_out[7:0] = d3_count_0[7:0];
      else if (valid_read && (address == 6'd11)) read_data_out[7:0] = d3_count_0[15:8];
      else if (valid_read && (address == 6'd12)) read_data_out[7:0] = d3_count_0[23:16];
      else if (valid_read && (address == 6'd13)) read_data_out[7:0] = d3_count_0[31:24];
      else if (valid_read && (address == 6'd14)) read_data_out[7:0] = d1_count_1[7:0];
      else if (valid_read && (address == 6'd15)) read_data_out[7:0] = d1_count_1[15:8];
      else if (valid_read && (address == 6'd16)) read_data_out[7:0] = d1_count_1[23:16];
      else if (valid_read && (address == 6'd17)) read_data_out[7:0] = d1_count_1[31:24];
      else if (valid_read && (address == 6'd18)) read_data_out[7:0] = d2_count_1[7:0];
      else if (valid_read && (address == 6'd19)) read_data_out[7:0] = d2_count_1[15:8];
      else if (valid_read && (address == 6'd20)) read_data_out[7:0] = d2_count_1[23:16];
      else if (valid_read && (address == 6'd21)) read_data_out[7:0] = d2_count_1[31:24];
      else if (valid_read && (address == 6'd22)) read_data_out[7:0] = d3_count_1[7:0];
      else if (valid_read && (address == 6'd23)) read_data_out[7:0] = d3_count_1[15:8];
      else if (valid_read && (address == 6'd24)) read_data_out[7:0] = d3_count_1[23:16];
      else if (valid_read && (address == 6'd25)) read_data_out[7:0] = d3_count_1[31:24];
      else                                       read_data_out[7:0] = 8'd0;
      
    assign valid_write = valid_slave && (!rnw) && data_in_valid && (!first_byte) && (!final_byte);
 
    integer i;
    always_ff @(posedge clk, negedge rst_n_sync)
      if (~rst_n_sync) for (i=0; i<NUM_WRITE_REGS; i=i+1) registers[i]       <= 8'h00;
      else if (valid_write && (address < 6'd2))           registers[address] <= data_in;

    always_comb begin
      enable       = registers[0][3:0];
      trig_enable  = registers[0][7:4];
      cfg_in_inv   = registers[1][3:0];
      cfg_trig_out = registers[1][7:4];
    end

endmodule