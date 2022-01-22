# tang_nano-scarf_pat_gen_edge_counter
FPGA design for Tang Nano board. SCARF SPI slave with block ram slave, pattern generator slave and two edge counter slaves.

This design requires a SPI interface (I used my Raspberry Pi). The python example requires the output of the pattern generator to be connected to the input of the first edge counter. The FPGA's block ram is used to hold pattern data that is driven to upto 8 pin outputs. Two edge counter instances are also included, with 2 pins that can measure high and low duration of a pulse.

I use the FPGA board as a suppliment to the Raspberry Pi, where it can perform and measure real-time signalling.
