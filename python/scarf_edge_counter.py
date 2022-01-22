from __future__ import print_function
from scarf_slave import scarf_slave
import math

class scarf_edge_counter:
	
	# Constructor
	def __init__(self, slave_id=0x03, spidev=None, num_instances=2, debug=False):
		self.slave_id       = slave_id
		self.num_addr_bytes = 1
		self.spidev         = spidev
		self.num_instances  = num_instances
		self.debug          = debug
		self.scarf_slave    = scarf_slave(slave_id=self.slave_id, num_addr_bytes=self.num_addr_bytes, spidev=self.spidev, debug=self.debug)
		
	def counter_enable(self, enable_nibble=0x0, trigger_nibble=0x0):
		print("--------------")
		print("Enable counter(s)")
		print("--------------")
		byte_0 = (enable_nibble & 0x0F) + ((trigger_nibble << 4) & 0xF0)
		self.scarf_slave.write_list(addr=0x00, write_byte_list=[0x00]) # send clear, in case previously enabled
		self.scarf_slave.write_list(addr=0x00, write_byte_list=[byte_0]) # enable is bit 0
		
	def cfg_counter(self, trig_out_nibble=0x0, invert_nibble=0x0):
		print("--------------")
		print("Config counter(s)")
		print("--------------")
		byte_0 = (invert_nibble & 0x0F) + ((trig_out_nibble << 4) & 0xF0)
		# A high invert bit will invert, else no invsersion. A high trig_out will pulse the tigger on the falling edge, else rising
		self.scarf_slave.write_list(addr=0x01, write_byte_list=[byte_0]) # enable is bit 0
		
	def get_count_val(self, counter_num=1, series_num=1):
		if (counter_num < 1 or counter_num > self.num_instances):
			print("ERROR: Must specify a counter_num between 1 to {:d}".format(self.num_instances))
		elif (series_num != 1 and series_num != 2 and series_num != 3):
			print("ERROR: Must specify a series_num of 1, 2 or 3")
		else:
			start_address = 2 + (counter_num - 1) * 12 + (series_num - 1) * 4
			read_list = self.scarf_slave.read_list(addr=start_address, num_bytes=4)
			count = 0
			for byte in range(0,4):
				count = count + (read_list[byte] << (byte * 8))
			return count

	def read_all_regmap(self):
		read_list = self.scarf_slave.read_list(addr=0x00, num_bytes=(2 + 12*self.num_instances))
