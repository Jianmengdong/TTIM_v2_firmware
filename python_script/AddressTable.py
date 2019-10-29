from ChipsException import ChipsException
from AddressTableItem import AddressTableItem


class AddressTable:

    def __init__(self, address_table):
        self.items = {}
        self.file_name = address_table
        self.__read_table(address_table)

    def show_registers(self):
        reg_list = []
        for k in self.items.keys():
            reg_list.append(k)
        return reg_list

    def get_item(self, register):
        if self.check_item(register):
            return self.items[register]
        else:
            raise ChipsException("Register '" + register + "' does not exist!")

    def check_item(self, register):
        if register in self.items:
            return True
        return False

    def __read_table(self, address_table):
        file = open(address_table, 'r')
        line = file.readline()
        line_number = 1
        while len(line) != 0:
            words = line.split()
            if len(words) != 0:
                if line[0] != '*':
                    if len(words) < 5:
                        raise ChipsException("Line " + str(line_number) +
                                             " does not conform to file format expectations!")
                    try:
                        regName = words[0]
                        regAddr = int(words[1], 16)
                        regMask = int(words[2], 16)
                        regRead = int(words[3])
                        regWrite = int(words[4])
                    except Exception as err:
                        raise ChipsException("Line " + str(line_number) +
                                             " does not conform to file format expectations!")
                    if regName in self.items:
                        raise ChipsException("Register " + regName +
                                             " is included more than once!")
                    item = AddressTableItem(regName, regAddr, regMask, regRead, regWrite)
                    self.items[regName] = item
            line = file.readline()
            line_number += 1

