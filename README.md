# tang_nano-scarf_pat_gen_edge_counter
![picture](https://image.space.rakuten.co.jp/d/strg/ctrl/9/0416b9703403dc8ec59582e91aa7aeea686b257e.40.9.9.3.jpeg)

FPGA design for Tang Nano board. SCARF SPI slave with block ram slave, pattern generator slave and two edge counter slaves.

This design requires a SPI interface (I used my Raspberry Pi). The python example requires the output of the pattern generator to be connected to the input of the first edge counter. The FPGA's block ram is used to hold pattern data that is driven to upto 8 pin outputs. Two edge counter instances are also included, with 2 pins that can measure high and low duration of a pulse.

I use the FPGA board as a suppliment to the Raspberry Pi, where it can perform and measure real-time signalling.
