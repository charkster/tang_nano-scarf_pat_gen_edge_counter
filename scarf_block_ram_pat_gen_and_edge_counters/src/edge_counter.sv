
module edge_counter
  ( input  logic	    clk,
    input  logic	    rst_n,
    input  logic	    gpio_in,
    input  logic        enable,
    input  logic        trig_enable,
    input  logic	    trig_in,
    output logic	    trig_out,
    input  logic	    cfg_trig_out,
    input  logic	    cfg_in_inv,
    output logic [31:0] d1_count,
    output logic [31:0] d2_count,
    output logic [31:0] d3_count
    );
    
  logic gpio_in_pol_sync;
  logic gpio_in_pol;
  logic trig_done;
  logic non_trig_done;
  logic d1_count_done;
  logic d1_count_done_hold;
  logic d2_count_done;
  logic d2_count_done_hold;
  logic d3_count_done;
  logic d3_count_done_hold;
  logic pos_edge_trig_out;
  logic neg_edge_trig_out;
  logic trig_out_hold;
    
  assign gpio_in_pol = (cfg_in_inv) ? ~gpio_in : gpio_in;
    
  synchronizer u_synchronizer_gpio_in
    ( .clk      (clk),
      .rst_n    (rst_n),
      .data_in  (gpio_in_pol),
      .data_out (gpio_in_pol_sync)
     );
     
  assign trig_done     =   trig_enable  &&   gpio_in_pol_sync;
  assign non_trig_done = (!trig_enable) && (!gpio_in_pol_sync);
  assign d1_count_done = (d1_count != 32'd0) && (trig_done || non_trig_done);
     
  always_ff @(posedge clk, negedge rst_n)
    if (~rst_n)             d1_count_done_hold <= 1'b0;
    else if (!enable)       d1_count_done_hold <= 1'b0;
    else if (d1_count_done) d1_count_done_hold <= 1'b1;
     
  always_ff @(posedge clk, negedge rst_n)
    if (~rst_n)                                                                     d1_count <= 32'd0;
    else if (!enable)                                                               d1_count <= 32'd0;
    else if ((d1_count == '1) || d1_count_done || d1_count_done_hold)               d1_count <= d1_count;
    else if ((d1_count == 32'd0) && ((trig_in && trig_enable) || gpio_in_pol_sync)) d1_count <= 32'd1;
    else if ((d1_count != 32'd0) &&   trig_enable  && (!gpio_in_pol_sync))          d1_count <= d1_count + 32'd1;
    else if ((d1_count != 32'd0) && (!trig_enable) &&   gpio_in_pol_sync)           d1_count <= d1_count + 32'd1;

  assign d2_count_done = (d2_count != 32'd0) && ((trig_enable && (!gpio_in_pol_sync)) || ((!trig_enable) && gpio_in_pol_sync));
  
  always_ff @(posedge clk, negedge rst_n)
    if (~rst_n)             d2_count_done_hold <= 1'b0;
    else if (!enable)       d2_count_done_hold <= 1'b0;
    else if (d2_count_done) d2_count_done_hold <= 1'b1;
  
  always_ff @(posedge clk, negedge rst_n)
    if (~rst_n)                                                            d2_count <= 32'd0;
    else if (!enable)                                                      d2_count <= 32'd0;
    else if ((d2_count == '1) || d2_count_done || d2_count_done_hold)      d2_count <= d2_count;
    else if ((d2_count == 32'd0) && d1_count_done)                         d2_count <= 32'd1;
    else if ((d2_count != 32'd0) &&   trig_enable  &&   gpio_in_pol_sync)  d2_count <= d2_count + 32'd1;
    else if ((d2_count != 32'd0) && (!trig_enable) && (!gpio_in_pol_sync)) d2_count <= d2_count + 32'd1;
  
  assign d3_count_done = (d3_count != 32'd0) && ((trig_enable && gpio_in_pol_sync) || ((~trig_enable) && (~gpio_in_pol_sync)));
  
  always_ff @(posedge clk, negedge rst_n)
    if (~rst_n)             d3_count_done_hold <= 1'b0;
    else if (!enable)       d3_count_done_hold <= 1'b0;
    else if (d3_count_done) d3_count_done_hold <= 1'b1;
  
  always_ff @(posedge clk, negedge rst_n)
    if (~rst_n)                                                            d3_count <= 32'd0;
    else if (!enable)                                                      d3_count <= 32'd0;
    else if ((d3_count == '1) || d3_count_done || d3_count_done_hold)      d3_count <= d3_count;
    else if ((d3_count == 32'd0) && d2_count_done)                         d3_count <= 32'd1;
    else if ((d3_count != 32'd0) &&   trig_enable  && (!gpio_in_pol_sync)) d3_count <= d3_count + 32'd1;
    else if ((d3_count != 32'd0) && (!trig_enable) &&   gpio_in_pol_sync)  d3_count <= d3_count + 32'd1;
  
  assign pos_edge_trig_out = (!cfg_trig_out) && (d1_count == 32'd0) &&   gpio_in_pol_sync;
  assign neg_edge_trig_out =   cfg_trig_out  && (d1_count != 32'd0) && (!gpio_in_pol_sync);
  
  always_ff @(posedge clk, negedge rst_n)
    if (~rst_n)                                                          trig_out <= 1'b0;
    else if (!enable)                                                    trig_out <= 1'b0;
    else if (!trig_out_hold && (pos_edge_trig_out || neg_edge_trig_out)) trig_out <= 1'b1;
    else                                                                 trig_out <= 1'b0;
    
  always_ff @(posedge clk, negedge rst_n)
    if (~rst_n)        trig_out_hold <= 1'b0;
    else if (!enable)  trig_out_hold <= 1'b0;
    else if (trig_out) trig_out_hold <= 1'b1;

endmodule

   