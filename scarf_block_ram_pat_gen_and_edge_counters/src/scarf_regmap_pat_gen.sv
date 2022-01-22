
module scarf_regmap_pat_gen
  ( input  logic        clk,
    input  logic        rst_n_sync,
    input  logic  [7:0] data_in,
    input  logic        data_in_valid,
    input  logic        data_in_finished,
    input  logic  [6:0] slave_id,
    input  logic        rnw,
    output logic  [7:0] read_data_out_pat_gen,
    output logic [12:0] end_address_pat_gen,
    output logic        enable_pat_gen,
    output logic        repeat_enable_pat_gen,
    output logic  [1:0] num_gpio_sel_pat_gen,
    output logic  [4:0] timestep_sel_pat_gen,
    output logic  [3:0] stage1_count_sel_pat_gen
    );

    parameter SLAVE_ID    = 7'h01;
    parameter MAX_ADDRESS = 4'd3;
 
    logic [7:0] registers[4:0];
    logic [3:0] address;
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
        else if (valid_slave && data_in_valid && first_byte)              address <= data_in[3:0];
        else if (valid_slave && data_in_valid && (address < MAX_ADDRESS)) address <= address + 1'b1;
        
    always_ff @(posedge clk, negedge rst_n_sync)
        if (~rst_n_sync)                                                                    final_byte <= 1'b0;
        else if (data_in_finished)                                                          final_byte <= 1'b0;
        else if (valid_slave && data_in_valid && (!first_byte) && (address == MAX_ADDRESS)) final_byte <= 1'b1;
 
    assign valid_read = valid_slave && rnw && (!first_byte) && (!final_byte);
    
    assign first_byte_slave_id = valid_slave && rnw && first_byte;
    
    always_comb
      read_data_out_pat_gen[7:0] =  ({8{valid_read}} & registers[address]) | ({8{first_byte_slave_id}} & {1'b0,SLAVE_ID});
      
    assign valid_write = valid_slave && (!rnw) && data_in_valid && (!first_byte) && (!final_byte);
 
    integer i;
    always_ff @(posedge clk, negedge rst_n_sync)
      if (~rst_n_sync)      for (i=0; i<=MAX_ADDRESS; i=i+1) registers[i]       <= 8'h00;
      else if (valid_write)                                  registers[address] <= data_in;

    always_comb begin
      end_address_pat_gen      = {registers[2][4:0],registers[3]};
      enable_pat_gen           = registers[0][0];
      repeat_enable_pat_gen    = registers[0][1];
      stage1_count_sel_pat_gen = registers[0][7:4];
      num_gpio_sel_pat_gen     = registers[1][1:0];
      timestep_sel_pat_gen     = registers[1][5:3];
    end

endmodule