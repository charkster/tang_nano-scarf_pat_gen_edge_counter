
// CPOL == 1'b0, CPHA = 1'b0, why would anyone do anything else?

module scarf
  ( input  logic       sclk,                // SPI
    input  logic       mosi,                // SPI
    output logic       miso,                // SPI
    input  logic       ss_n,                // SPI active low select
    input  logic       clk,                 // fpga clock
    input  logic       rst_n,               // async reset
    input  logic [7:0] read_data_in,        // read data fpga clk domain
    output logic       rst_n_sync,          // active low reset synchronized to fpga clk
    output logic [7:0] data_out,            // byte data,          fpga clk domain
    output logic       data_out_valid,      // byte data is valid, fpga clk domain
    output logic       data_out_finished,   // indicates bus cycle has finished
    output logic [6:0] slave_id,            // slave select        fpga clk domain
    output logic       rnw                  // read not-write      fpga clk domain
    );

   //////////////////////////////////////////////////////////////////////
   // sclk domain
   //////////////////////////////////////////////////////////////////////
   
   logic       rst_n_spi;
   logic [6:0] mosi_buffer;
   logic [2:0] bit_count;
   logic [7:0] spi_data;
   logic       spi_data_valid;
   logic       spi_data_valid_sync_ff_sync;
   logic       spi_data_valid_sync_ff_sync_ff;
   logic       spi_data_valid_clr;
   logic [7:0] rdata_spi;
   logic [7:0] rdata_spi_hold;
   logic       spi_data_valid_sync_ff; // this is clk domain, but needs to be declared before used
   
   assign rst_n_spi = rst_n && !ss_n; // clear the SPI when the chip_select is inactive
   
   always_ff @(posedge sclk, negedge rst_n_spi)
     if (~rst_n_spi) mosi_buffer <= 7'd0;
     else            mosi_buffer <= {mosi_buffer[5:0],mosi};

   always_ff @(posedge sclk, negedge rst_n_spi)
     if (~rst_n_spi) bit_count <= 3'd0;
     else            bit_count <= bit_count + 1; // overflow expected
     
   always_ff @(posedge sclk, negedge rst_n)  //  this needs to remain valid until clk has captured it
     if (~rst_n)                 spi_data <= 8'd0;
     else if (bit_count == 3'd7) spi_data <= {mosi_buffer[6:0],mosi};
   
   always_ff @(posedge sclk, negedge rst_n) // this reset can't clear with ss_n
     if (~rst_n)                  spi_data_valid <= 1'b0;
     else if (bit_count == 3'd7)  spi_data_valid <= 1'b1;
     else if (spi_data_valid_clr) spi_data_valid <= 1'b0; // clr expected to come before bit_count gets to 7
     
    synchronizer u_synchronizer_data_valid_ff_sclk
      ( .clk      (sclk),
        .rst_n    (rst_n_spi),
        .data_in  (spi_data_valid_sync_ff),
        .data_out (spi_data_valid_sync_ff_sync)
       );
       
   always_ff @(posedge sclk, negedge rst_n_spi)
     if (~rst_n_spi) spi_data_valid_sync_ff_sync_ff <= 1'b0;
     else            spi_data_valid_sync_ff_sync_ff <= spi_data_valid_sync_ff_sync;
     
   assign spi_data_valid_clr = spi_data_valid_sync_ff_sync && (!spi_data_valid_sync_ff_sync_ff);
     
   //always_ff @(posedge sclk, negedge rst_n_spi)
   //  if (~rst_n_spi)              rdata_spi <= 8'd0;
   //  else if (spi_data_valid_clr) rdata_spi <= read_data_in;
     
   always_ff @(posedge sclk, negedge rst_n_spi)
     if (~rst_n_spi)             rdata_spi_hold <= 8'd0;
  //   else if (bit_count == 3'd7) rdata_spi_hold <= rdata_spi;
     else if (bit_count == 3'd7) rdata_spi_hold <= read_data_in;
     
   always_ff @(negedge sclk, negedge rst_n_spi)
     if (~rst_n_spi) miso <= 1'b0;
     else            miso <= rdata_spi_hold[3'd7 - bit_count];
     
   //////////////////////////////////////////////////////////////////////
   // clk domain
   //////////////////////////////////////////////////////////////////////
   
   logic spi_data_valid_sync;
   logic ss_n_sync;
   logic ss_n_sync_ff;
   logic ss_n_sync_fedge_hold;
   logic slave_valid_hold;
   logic first_data_byte;
   logic spi_data_valid_redge;
   
   synchronizer u_synchronizer_rst_n_sync
      ( .clk      (clk),
        .rst_n    (rst_n),
        .data_in  (1'b1),
        .data_out (rst_n_sync)
       );
     
   synchronizer u_synchronizer_data_valid_clk
      ( .clk      (clk),
        .rst_n    (rst_n_sync),
        .data_in  (spi_data_valid),
        .data_out (spi_data_valid_sync)
       );
     
   always_ff @(posedge clk, negedge rst_n_sync)
     if (~rst_n_sync) spi_data_valid_sync_ff <= 1'b0;
     else             spi_data_valid_sync_ff <= spi_data_valid_sync;
     
   assign spi_data_valid_redge = spi_data_valid_sync && (!spi_data_valid_sync_ff);
     
   always_ff @(posedge clk, negedge rst_n_sync)
     if (~rst_n_sync)                                   data_out_valid <= 1'b0;
     else if (slave_valid_hold && spi_data_valid_redge) data_out_valid <= 1'b1;
     else                                               data_out_valid <= 1'b0;
     
   always_ff @(posedge clk, negedge rst_n_sync)
     if (~rst_n_sync)     data_out_finished <= 1'b0;
     else if (ss_n_sync)  data_out_finished <= 1'b1;
     else if (!ss_n_sync) data_out_finished <= 1'b0;
     
   always_ff @(posedge clk, negedge rst_n_sync)
     if (~rst_n_sync)                                   data_out <= 8'd0;
     else if (slave_valid_hold && spi_data_valid_redge) data_out <= spi_data;
     
   synchronizer u_synchronizer_ss_n
      ( .clk      (clk),
        .rst_n    (rst_n),
        .data_in  (ss_n),
        .data_out (ss_n_sync)
       );
       
   always_ff @(posedge clk, negedge rst_n_sync)
     if (~rst_n_sync) ss_n_sync_ff <= 1'b1;
     else             ss_n_sync_ff <= ss_n_sync;
     
   always_ff @(posedge clk, negedge rst_n_sync)
     if (~rst_n_sync)                     ss_n_sync_fedge_hold <= 1'b0;
     else if (!ss_n_sync && ss_n_sync_ff) ss_n_sync_fedge_hold <= 1'b1;
     else if (slave_valid_hold)           ss_n_sync_fedge_hold <= 1'b0;
     
   assign first_data_byte = spi_data_valid_redge && ss_n_sync_fedge_hold;
     
   always_ff @(posedge clk, negedge rst_n_sync)
     if (~rst_n_sync)          slave_valid_hold <= 1'b0;
     else if (ss_n_sync)       slave_valid_hold <= 1'b0;
     else if (first_data_byte) slave_valid_hold <= 1'b1;
     
   always_ff @(posedge clk, negedge rst_n_sync)
     if (~rst_n_sync)          slave_id <= 7'd0;
     else if (first_data_byte) slave_id <= spi_data[6:0]; //lower 7 bits
     
   always_ff @(posedge clk, negedge rst_n_sync)
     if (~rst_n_sync)          rnw <= 1'b0;
     else if (first_data_byte) rnw <= spi_data[7]; // MSB

endmodule