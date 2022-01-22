
module scarf_2_edge_counters
  ( input  logic        clk,
    input  logic        rst_n_sync,
    input  logic  [7:0] data_in,
    input  logic        data_in_valid,
    input  logic        data_in_finished,
    input  logic  [6:0] slave_id,
    input  logic        rnw,
    output logic  [7:0] read_data_out,
    input  logic        gpio_0_in,
    input  logic        gpio_1_in
    );
    
   parameter SLAVE_ID = 7'd03;
   
   logic        trig_out_0;
   logic        trig_out_1;
   logic  [3:0] cfg_trig_out;
   logic  [3:0] cfg_in_inv;
   logic  [3:0] enable;
   logic  [3:0] trig_enable;
   logic [31:0] d1_count_0;
   logic [31:0] d2_count_0;
   logic [31:0] d3_count_0;
   logic [31:0] d1_count_1;
   logic [31:0] d2_count_1;
   logic [31:0] d3_count_1;


   scarf_regmap_2_edge_counters 
   # ( .SLAVE_ID( SLAVE_ID ) )
   u_scarf_regmap_4_edge_counters
     ( .clk,                   // input
       .rst_n_sync,            // input
       .data_in,               // input [7:0]
       .data_in_valid,         // input
       .data_in_finished,      // input
       .slave_id,              // input [6:0]
       .rnw,                   // input
       .read_data_out,         // output [7:0]
       .cfg_trig_out,          // output [3:0]
       .cfg_in_inv,            // output [3:0]
       .enable,                // output [3:0]
       .trig_enable,           // output [3:0]
       .d1_count_0,            // input  [31:0]
       .d2_count_0,            // input  [31:0]
       .d3_count_0,            // input  [31:0]
       .d1_count_1,            // input  [31:0]
       .d2_count_1,            // input  [31:0]
       .d3_count_1             // input  [31:0]
      );

   edge_counter u_edge_counter_0
     ( .clk,                                   // input
       .rst_n               (rst_n_sync),      // input
       .gpio_in             (gpio_0_in),       // input
       .enable              (enable[0]),       // input
       .trig_enable         (trig_enable[0]),  // input
       .trig_in             (trig_out_1),      // input
       .trig_out            (trig_out_0),      // output
       .cfg_trig_out        (cfg_trig_out[0]), // input
       .cfg_in_inv          (cfg_in_inv[0]),   // input
       .d1_count            (d1_count_0),      // output [31:0]
       .d2_count            (d2_count_0),      // output [31:0]
       .d3_count            (d3_count_0)       // output [31:0]
       );

   edge_counter u_edge_counter_1
     ( .clk,                                   // input
       .rst_n               (rst_n_sync),      // input
       .gpio_in             (gpio_1_in),       // input
       .enable              (enable[1]),       // input
       .trig_enable         (trig_enable[1]),  // input
       .trig_in             (trig_out_0),      // input
       .trig_out            (trig_out_1),      // output
       .cfg_trig_out        (cfg_trig_out[1]), // input
       .cfg_in_inv          (cfg_in_inv[1]),   // input
       .d1_count            (d1_count_1),      // output [31:0]
       .d2_count            (d2_count_1),      // output [31:0]
       .d3_count            (d3_count_1)       // output [31:0]
       );
   
   endmodule