import os
import time
from LiteBus import *
from AddressTable import AddressTable


class TTIM:
    def __init__(self):
        f = open(os.path.dirname(os.path.abspath(__file__)) + "/TTIM_ip.dat")
        host_ip = f.readline().strip()
        f.close()
        self.address_table = AddressTable(os.path.dirname(os.path.abspath(__file__)) + "/TTIM_v2_registers.dat")
        self.lite_bus = LiteBus(self.address_table, host_ip, 2000, 2000)

    def get(self, register):
        time.sleep(0.5)
        return self.lite_bus.read(register)

    def set(self, register, value):
        time.sleep(0.5)
        return self.lite_bus.write(register, value)

    def show_registers(self):
        return self.address_table.show_registers()


def main():
    hw = TTIM()
    test = type(hw.show_registers())
    print(test)


if __name__ == "__main__":
    main()
