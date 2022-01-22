
module scarf_block_ram_top
( input  logic        clk_24mhz,       // osc board clock
  input  logic        button_b,         // button reset
  input  logic        sclk,             // SPI CLK
  input  logic        ss_n,             // SPI CS_N
  input  logic        mosi,             // SPI MOSI
  output logic        miso,             // SPI MISO
  output logic [7:0]  gpio_pat_gen_out, // pattern output pins
  output logic        pattern_done,     // pattern was active and but no longer is
  input  logic        gpio_0_in,        // edge counter #1 input
  input  logic        gpio_1_in         // edge counter #2 input
 );

  logic  [7:0] read_data_in;
  logic  [7:0] read_data_out_bram;
  logic  [7:0] read_data_out_pat_gen;
  logic  [7:0] read_data_out_edge;
  logic  [7:0] data_out;
  logic        data_out_valid;
  logic        data_out_finished;
  logic  [6:0] slave_id;
  logic        rnw;
  logic        clk_100mhz;
  logic        rst_n_100mhz_sync;
  logic        bram_wen;
  logic        bram_ren;
  logic [12:0] bram_addr;
  logic  [7:0] bram_read_data;
  logic  [7:0] bram_write_data;
  logic        scarf_bram_wen;
  logic        scarf_bram_ren;
  logic [12:0] scarf_bram_addr;
  logic        pat_gen_bram_ren;
  logic [12:0] pat_gen_bram_addr;       
  logic [12:0] end_address_pat_gen;
  logic        enable_pat_gen;
  logic        repeat_enable_pat_gen;
  logic  [1:0] num_gpio_sel_pat_gen;
  logic  [2:0] timestep_sel_pat_gen;
  logic  [3:0] stage1_count_sel_pat_gen;
  logic        pattern_active;
  
  assign read_data_in = read_data_out_bram | read_data_out_pat_gen | read_data_out_edge;

  Gowin_rPLL u_pll(
        .clkout(clk_100mhz), //output clkout
        .clkin(clk_24mhz)    //input clkin
    );
   
  scarf u_scarf
  ( .sclk,                                 // input
    .mosi,                                 // input
    .miso,                                 // output
    .ss_n,                                 // input
    .clk              (clk_100mhz),        // input
    .rst_n            (button_b),          // input
    .read_data_in,                         // input  [7:0]
    .rst_n_sync       (rst_n_100mhz_sync), // output
    .data_out,                             // output [7:0]
    .data_out_valid,                       // output
    .data_out_finished,                    // output
    .slave_id,                             // output [6:0]
    .rnw                                   // output
   );
   
  scarf_regmap_pat_gen 
  # ( .SLAVE_ID( 7'h01 ) )
  u_scarf_regmap_pattern_gen
  ( .clk                  (clk_100mhz),        // input
    .rst_n_sync           (rst_n_100mhz_sync), // input
    .data_in              (data_out),          // input [7:0]
    .data_in_valid        (data_out_valid),    // input
    .data_in_finished     (data_out_finished), // input
    .slave_id,                                 // input [6:0]
    .rnw,                                      // input
    .read_data_out_pat_gen,                    // output [7:0]
    .end_address_pat_gen,                      // output [12:0]
    .enable_pat_gen,                           // output
    .repeat_enable_pat_gen,                    // output
    .num_gpio_sel_pat_gen,                     // output [1:0]
    .timestep_sel_pat_gen,                     // output [2:0]
    .stage1_count_sel_pat_gen                  // output [3:0]
   );
         
  pattern_gen u_pattern_gen
  ( .clk                    (clk_100mhz),        // input
    .rst_n                  (rst_n_100mhz_sync), // input
    .enable_pat_gen,                             // input
    .end_address_pat_gen,                        // input  [12:0]
    .num_gpio_sel_pat_gen,                       // input  [1:0]
    .timestep_sel_pat_gen,                       // input  [2:0]
    .stage1_count_sel_pat_gen,                   // input  [3:0]
    .repeat_enable_pat_gen,                      // input
    .pattern_active,                             // output
    .pattern_done,                               // output
    .gpio_pat_gen_out,                           // output [7:0]
    .bram_read_data,                             // input  [7:0]
    .bram_addr              (pat_gen_bram_addr)  // output [12:0]
   );  
                
  scarf_bram
  # ( .SLAVE_ID(7'h02) )
  u_scarf_bram
  ( .clk                   (clk_100mhz),         // input
    .rst_n_sync            (rst_n_100mhz_sync),  // input
    .data_in               (data_out),           // input  [7:0]
    .data_in_valid         (data_out_valid),     // input
    .data_in_finished      (data_out_finished),  // input
    .slave_id,                                   // input  [6:0]
    .rnw,                                        // input
    .read_data_out         (read_data_out_bram), // output [7:0] 
    .scarf_bram_read_data  (bram_read_data),     // input  [7:0]
    .scarf_bram_write_data (bram_write_data),    // output [7:0]
    .scarf_bram_addr,                            // output [12:0]
    .scarf_bram_wen,                             // output
    .scarf_bram_ren                              // output
   );

assign bram_addr = (pattern_active) ? pat_gen_bram_addr : scarf_bram_addr;
assign bram_ren  = (pattern_active) ? 1'b1              : scarf_bram_ren;
assign bram_wen  = (pattern_active) ? 1'b0              : scarf_bram_wen;

  block_ram
  #( .RAM_WIDTH(8),
     .RAM_ADDR_BITS(13) )
  u_block_ram
  ( .clk          (clk_100mhz),      // input
    .write_enable (bram_wen),        // input 
    .address      (bram_addr),       // input [12:0]
    .write_data   (bram_write_data), // input [7:0]
    .read_enable  (bram_ren),        // input
    .read_data    (bram_read_data)   // output [7:0]
   );

  scarf_2_edge_counters 
  # ( .SLAVE_ID(7'h03) )
  u_scarf_2_edge_counters
  ( .clk              (clk_100mhz),         // input
    .rst_n_sync       (rst_n_100mhz_sync),  // input
    .data_in          (data_out),           // input [7:0]
    .data_in_valid    (data_out_valid),     // input
    .data_in_finished (data_out_finished),  // input
    .slave_id,                              // input [6:0]
    .rnw,                                   // input
    .read_data_out    (read_data_out_edge), // output [7:0]
    .gpio_0_in,                             // input
    .gpio_1_in                              // input
    );

endmodule