class AddressTableItem:
    def __init__(self, name, address, mask, read=True, write=True):
        self._name = name
        self._address = 0xff & address
        self._mask = 0xffffffffffff & mask
        self._read = bool(read)
        self._write = bool(write)
        self.__bitShiftForMaskedData = self.__maskedDataBitShift()

    def getName(self): return self._name

    def getAddress(self): return self._address

    def getMask(self): return self._mask

    def getReadFlag(self): return self._read

    def getWriteFlag(self): return self._write

    def setName(self, name): self._name = name

    def setAddress(self, address): self._address = 0xff & address

    def setMask(self, mask):
        self._mask = (0xffffffffffff & mask)
        self.__bitShiftForMaskedData = self.__maskedDataBitShift()

    def setReadFlag(self, read): self._read = bool(read)

    def setWriteFlag(self, write): self._write = bool(write)

    def shiftDataToMask(self, data):
        shiftedData = (data & 0xffffffffffff) << self.__bitShiftForMaskedData
        return shiftedData

    def __maskedDataBitShift(self):
        shiftingMask = self._mask
        bitShiftRequired = 0
        while (shiftingMask & 0x1) == 0:
            shiftingMask >>= 1
            bitShiftRequired += 1
        return bitShiftRequired
