#!/usr/bin/python

from __future__ import print_function

class scarf_slave:
	
	# Constructor
	def __init__(self, slave_id=0x00, num_addr_bytes=1, spidev=None, debug=False):
		self.slave_id       = slave_id
		self.num_addr_bytes = num_addr_bytes
		self.spidev         = spidev
		self.debug          = debug
		
	def read_list(self, addr=0x00, num_bytes=1):
		if (self.debug == True):
			print("Called read")
		if (num_bytes == 0):
			print("Error: num_bytes must be larger than zero")
			return []
		else:
			byte0 = (self.slave_id + 0x80) & 0xFF
			addr_byte_list = []
			for addr_byte_num in range(self.num_addr_bytes):
				addr_byte_list.insert(0, addr >> (8*addr_byte_num) & 0xFF )
			filler_bytes = [0x00] * int(num_bytes+1)
			read_list = self.spidev.xfer2([byte0] + addr_byte_list + filler_bytes)
			num_bytes_to_remove = 1 + self.num_addr_bytes + 1
			del read_list[0:num_bytes_to_remove]
			if (self.debug == True):
				address = addr
				for read_byte in read_list:
					print("Address 0x{:02x} Read data 0x{:02x}".format(address,read_byte))
					address += 1
			return read_list
	
	def write_list(self, addr=0x00, write_byte_list=[]):
		byte0 = self.slave_id & 0xFF
		addr_byte_list = []
		for addr_byte_num in range(self.num_addr_bytes):
			addr_byte_list.insert(0, addr >> (8*addr_byte_num) & 0xFF )
		self.spidev.xfer2([byte0] + addr_byte_list + write_byte_list)
		if (self.debug == True):
			print("Called write_bytes")
			address = addr
			for write_byte in write_byte_list:
				print("Wrote address 0x{:02x} data 0x{:02x}".format(address,write_byte))
				address += 1
		return 1
		
	def read_mod_write(self, addr=0x00, write_byte=0x00):
		read_list = self.read_list(addr=addr, num_bytes=1)
		mod_write_byte = read_list[0] | write_byte
		self.write_list(addr=addr, write_byte_list=[mod_write_byte])
		
	def read_and_clear(self,addr=0x00, clear_mask=0x00):
		read_list = self.read_list(addr=addr, num_bytes=1)
		mod_write_byte = read_list[0] & (~clear_mask)
		self.write_list(addr=addr, write_byte_list=[mod_write_byte])
		
	def read_id(self):
		byte0 = (self.slave_id + 0x80) & 0xFF
		slave_id = self.spidev.xfer2([byte0] + [0x00, 0x00])
		if (self.debug == True):
			print("Slave ID is 0x{:02x}".format(slave_id[2]))
		return slave_id[2]
		
