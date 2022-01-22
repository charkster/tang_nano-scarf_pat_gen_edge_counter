#!/usr/bin/python3

from __future__         import print_function
import spidev
import time
import random
from scarf_slave        import scarf_slave
from scarf_pat_gen      import scarf_pat_gen
from scarf_edge_counter import scarf_edge_counter

spi              = spidev.SpiDev(0,0)
spi.max_speed_hz = 12000000 # 12MHz
spi.mode         = 0b00

pat_gen = scarf_pat_gen     (slave_id=0x01, spidev=spi,                   debug=False)
bram    = scarf_slave       (slave_id=0x02, spidev=spi, num_addr_bytes=2, debug=False)
counter = scarf_edge_counter(slave_id=0x03, spidev=spi, num_instances=2,  debug=False)

print("Check for SCARF Slaves")
for ss_id in range(1,128):
	bram.slave_id = ss_id
	if (bram.read_id() != 0x00):
		print("Found scarf slave at 0x{:02x}".format(bram.slave_id))
bram.slave_id = 0x02 # return the slave_id to the original value

# create a list of 32 pages, each page with random values
print("check full range of block ram with random values")
dict_of_pages = {}
for page in range(0, 32):
	list_page = []
	for randbyte in range(0, 256):
		list_page.append(random.randrange(0, 256, 1))
	dict_of_pages[page] = list_page
	bram.write_list(addr=page*256, write_byte_list=list_page)

misscompare = False
for page in range(0, 32):
	read_data = bram.read_list(addr=page*256,num_bytes=256)
	if (read_data != dict_of_pages[page]):
		print("page {:d} miscompares".format(page))
		misscompare = True
if (misscompare == False):
	print("No miscompares for all 32 pages")


print("Drive 1 gpio pin with 24 values, each value lasting 10us")
bram.write_list(addr=0x000000, write_byte_list=[0b01110011, 0b00010100, 0b11111110])
pat_gen.cfg_sram_end_addr(end_addr=0x0002)
pat_gen.cfg_pat_gen(timestep=1, num_gpio=1) # timestep of 1 is 100ns, 2 is 1us, powers of 10
pat_gen.cfg_stage1_count(stage1_count=1)
counter.counter_enable(enable_nibble=0x01)
pat_gen.cfg_enable()
time.sleep(1)
pat_gen.cfg_disable()
print("     high duration was {:g} ns".format(counter.get_count_val(counter_num=1,series_num=1)*10))
print("      low duration was {:g} ns".format(counter.get_count_val(counter_num=1,series_num=2)*10))
print("next high duration was {:g} ns".format(counter.get_count_val(counter_num=1,series_num=3)*10))
