
module pattern_gen(
    input  logic        clk,
    input  logic        rst_n,
    input  logic        enable_pat_gen,
    input  logic [12:0] end_address_pat_gen,
    input  logic  [1:0] num_gpio_sel_pat_gen, // 2'b00 is 1, 2'b01 is 2, 2'b10 is 4 and 2'b11 is 8
    input  logic  [2:0] timestep_sel_pat_gen,
    input  logic  [3:0] stage1_count_sel_pat_gen,
    input  logic        repeat_enable_pat_gen,
    output logic        pattern_active,
    output logic        pattern_done,
    output logic  [7:0] gpio_pat_gen_out,
    input  logic  [7:0] bram_read_data,
    output logic [12:0] bram_addr
    );
    
    logic        reached_final_address;
    logic        reached_final_bit_count;
    logic        enable_pat_gen_delay;
    logic        enable_pat_gen_rise_edge;
    logic [12:0] current_address;
    logic  [2:0] bit_count;
    logic [25:0] timestep_counter;
    logic [25:0] final_timestep_count;
    logic        reached_final_timestep_count;
    logic        timestep_change;
    logic        timestep_change_delay;
    logic  [7:0] gpio_mask;
    logic  [7:0] gpio_pat_gen_comb;
    logic        enable_bit_counter;
    logic        pattern_active_hold;
    logic        reached_final_stage1_count;
    logic  [3:0] stage1_counter;
    logic  [3:0] final_stage1_count;
    
    assign reached_final_address = (current_address == end_address_pat_gen);
    
    assign reached_final_bit_count  = ((num_gpio_sel_pat_gen ==  2'b00) && (bit_count == 3'd7)) ||
                                      ((num_gpio_sel_pat_gen ==  2'b01) && (bit_count == 3'd6)) ||
                                      ((num_gpio_sel_pat_gen ==  2'b10) && (bit_count == 3'd4)) ||
                                      ((num_gpio_sel_pat_gen ==  2'b11) && (bit_count == 3'd0));
                                      
    always_ff @(posedge clk, negedge rst_n)
      if (~rst_n) enable_pat_gen_delay <= 1'b0;
      else        enable_pat_gen_delay <= enable_pat_gen;
      
    assign enable_pat_gen_rise_edge = (enable_pat_gen && (!enable_pat_gen_delay));
    
    always_ff @(posedge clk, negedge rst_n)
      if (~rst_n)                                                                                                      pattern_active <= 1'b0;
      else if (!enable_pat_gen && (!repeat_enable_pat_gen))                                                            pattern_active <= 1'b0;
      else if (repeat_enable_pat_gen || enable_pat_gen_rise_edge)                                                      pattern_active <= 1'b1;
      else if (reached_final_address && reached_final_bit_count && reached_final_timestep_count && enable_bit_counter) pattern_active <= 1'b0;

   always_ff @(posedge clk, negedge rst_n)
     if (~rst_n) pattern_active_hold <= 1'b0;
     else        pattern_active_hold <= pattern_active;

   always_ff @(posedge clk, negedge rst_n)
     if (~rst_n)                                           pattern_done <= 1'b0;
     else if (!enable_pat_gen && (!repeat_enable_pat_gen)) pattern_done <= 1'b0;
     else if (!pattern_active && pattern_active_hold)      pattern_done <= 1'b1;
   

    always_ff @(posedge clk, negedge rst_n)
      if (~rst_n)                                                                                                          current_address <= '0;
      else if ((!enable_pat_gen && (!repeat_enable_pat_gen)) || (!enable_bit_counter))                                     current_address <= '0;
      else if (!reached_final_address && reached_final_bit_count && reached_final_timestep_count)                          current_address <= current_address + 1;
      else if ( reached_final_address && reached_final_bit_count && reached_final_timestep_count && repeat_enable_pat_gen) current_address <= '0;
      
    assign bram_addr = current_address;

    always_ff @(posedge clk, negedge rst_n)
      if (~rst_n)                                                                  enable_bit_counter <= 1'b0;
      else if ((!enable_pat_gen && (!repeat_enable_pat_gen)) || (!pattern_active)) enable_bit_counter <= 1'b0;
      else if (pattern_active && reached_final_timestep_count)                     enable_bit_counter <= 1'b1;
      
    always_ff @(posedge clk, negedge rst_n)
      if (~rst_n)                                                                                                               bit_count <= '0;
      else if ((!enable_pat_gen && (!repeat_enable_pat_gen)) || (!enable_bit_counter))                                          bit_count <= '0;
      else if (!reached_final_bit_count && reached_final_timestep_count && (num_gpio_sel_pat_gen == 2'b00))                     bit_count <= bit_count + 1;
      else if (!reached_final_bit_count && reached_final_timestep_count && (num_gpio_sel_pat_gen == 2'b01))                     bit_count <= bit_count + 2;
      else if (!reached_final_bit_count && reached_final_timestep_count && (num_gpio_sel_pat_gen == 2'b10))                     bit_count <= bit_count + 4;
      else if ( reached_final_bit_count && reached_final_timestep_count && ((!reached_final_address) || repeat_enable_pat_gen)) bit_count <= '0;

    always_comb
        if (stage1_count_sel_pat_gen >= 3'd2) final_stage1_count = stage1_count_sel_pat_gen - 3'd1;
        else if (timestep_sel_pat_gen == '0)  final_stage1_count = 3'd1; // minimum
        else                                  final_stage1_count = 3'd0;
    
    assign reached_final_stage1_count = (stage1_counter == final_stage1_count);
    
    always_ff @(posedge clk, negedge rst_n)
      if (~rst_n)                                                                  stage1_counter <= '0;
      else if ((!enable_pat_gen && (!repeat_enable_pat_gen)) || (!pattern_active)) stage1_counter <= '0;
      else if (!reached_final_stage1_count)                                        stage1_counter <= stage1_counter + 1;
      else if ( reached_final_stage1_count)                                        stage1_counter <= '0;
 
    always_comb
      case(timestep_sel_pat_gen)
        3'd0:    final_timestep_count = 'd0;
        3'd1:    final_timestep_count = 'd10       - 1;
        3'd2:    final_timestep_count = 'd100      - 1;
        3'd3:    final_timestep_count = 'd1000     - 1; // 1k
        3'd4:    final_timestep_count = 'd10000    - 1;
        3'd5:    final_timestep_count = 'd100000   - 1;
        3'd6:    final_timestep_count = 'd1000000  - 1; // 1M
        3'd7:    final_timestep_count = 'd10000000 - 1; // 10M
        default: final_timestep_count = 'd10000000 - 1;
      endcase
      
    assign reached_final_timestep_count = (timestep_counter == final_timestep_count) && reached_final_stage1_count;
    
    always_ff @(posedge clk, negedge rst_n)
      if (~rst_n)                                                                                           timestep_counter <= '0;
      else if ((!enable_pat_gen && (!repeat_enable_pat_gen)) || (!pattern_active))                          timestep_counter <= '0;
      else if (!reached_final_timestep_count && (timestep_sel_pat_gen != '0) && reached_final_stage1_count) timestep_counter <= timestep_counter + 1;
      else if ( reached_final_timestep_count)                                                               timestep_counter <= '0;
      
    always_ff @(posedge clk, negedge rst_n)
      if (~rst_n)                            timestep_change <= 1'b0;
      else if (reached_final_timestep_count) timestep_change <= 1'b1;
      else                                   timestep_change <= 1'b0;
    
    // need to update the gpio pins after address and bit_count changes
    always_ff @(posedge clk, negedge rst_n)
      if (~rst_n) timestep_change_delay <= 1'b0;
      else        timestep_change_delay <= timestep_change && pattern_active;
      
    always_comb
      case(num_gpio_sel_pat_gen)
        2'b00: gpio_mask = 8'b0000_0001;
        2'b01: gpio_mask = 8'b0000_0011;
        2'b10: gpio_mask = 8'b0000_1111;
        2'b11: gpio_mask = 8'b1111_1111;
      endcase

    // MSB to LSB
    assign gpio_pat_gen_comb = {bram_read_data[bit_count],bram_read_data[1-bit_count],bram_read_data[2-bit_count],bram_read_data[3-bit_count],
                                bram_read_data[4-bit_count],bram_read_data[5-bit_count],bram_read_data[6-bit_count],bram_read_data[7-bit_count]};
      
    always_ff @(posedge clk, negedge rst_n)
      if (~rst_n)                                           gpio_pat_gen_out <= 8'b0000_0000;
      else if (!enable_pat_gen && (!repeat_enable_pat_gen)) gpio_pat_gen_out <= 8'b0000_0000;
      else if (timestep_change_delay)                       gpio_pat_gen_out <= gpio_pat_gen_comb & gpio_mask;

endmodule
