
from __future__ import print_function
from scarf_slave import scarf_slave
import math

class scarf_pat_gen:
	
	# Constructor
	def __init__(self, slave_id=0x00, spidev=None, debug=False):
		self.slave_id       = slave_id
		self.num_addr_bytes = 1
		self.spidev         = spidev
		self.debug          = debug
		self.scarf_slave    = scarf_slave(slave_id=self.slave_id, num_addr_bytes=self.num_addr_bytes, spidev=self.spidev, debug=self.debug)
		
	def pat_gen_enable(self, repeat=False):
		print("--------------")
		print("Enable pattern")
		print("--------------")
		self.scarf_slave.write_list(addr=0x00, write_byte_list=[0x00]) # send clear, in case previously enabled
		if (repeat):
			self.scarf_slave.write_list(addr=0x00, write_byte_list=[0x03]) # repeat is bit 1
		else:
			self.scarf_slave.write_list(addr=0x00, write_byte_list=[0x01]) # enable is bit 0
			
	def cfg_enable(self):
		self.scarf_slave.read_and_clear(addr=0x00, clear_mask=0x01)
		self.scarf_slave.read_mod_write(addr=0x00, write_byte=0x01)
	
	def cfg_repeat(self):
		self.scarf_slave.read_mod_write(addr=0x00, write_byte=0x02)
		
	def cfg_stage1_count(self, stage1_count=0):
		if (stage1_count > 15):
			print("Must specify a timestep less than 16")
		byte0 = (stage1_count << 4) & 0xF0
		self.scarf_slave.read_and_clear(addr=0x00, clear_mask=0xF0)
		self.scarf_slave.read_mod_write(addr=0x00, write_byte=byte0)
		
	def cfg_no_repeat(self):
		self.scarf_slave.read_mod_write(addr=0x00, write_byte=0x00)
		
	def cfg_disable(self):
		self.scarf_slave.read_mod_write(addr=0x00, write_byte=0x00)
		
	def cfg_pat_gen(self, timestep=0, num_gpio=1):
		if (timestep > 7):
			print("Must specify a timestep less than 8")
		elif (num_gpio < 0 or num_gpio > 8 or num_gpio == 3 or num_gpio == 5 or num_gpio == 6 or num_gpio == 7):
			print("num_gpio must be 1, 2, 4 or 8")
		else:
			bin_num_gpio = int(math.log(num_gpio,2))
			byte_0 = ((timestep << 3) + bin_num_gpio) & 0xFF
			print("byte0 or cfg_pat_get is 0x{:02x}".format(byte_0))
			self.scarf_slave.write_list(addr=0x01, write_byte_list=[byte_0])

	def cfg_sram_end_addr(self, end_addr=0x0000):
		byte_0 = (end_addr >> 8)  & 0xFF
		byte_1 =  end_addr        & 0xFF
		self.scarf_slave.write_list(addr=0x02, write_byte_list=[byte_0, byte_1])
		
	def read_all_regmap(self):
		read_list = self.scarf_slave.read_list(addr=0x00, num_bytes=5)
		if ((read_list[0] & 0x02) == 0x02):
			print("Repeat bit is set high")
		else:
			print("Repeat bit is set low")
		print("Timestep is {:d}".format((read_list[1] & 0xF8) >> 3))
		print("Num gpio is {:d}".format(2 ** (read_list[1] & 0x03)))
		print("End address is 0x{:04x}".format(((read_list[2] << 8) + read_list[3]) & 0xFFFF))
	
