#  define the bus respond information
INFO_NO_ERR = 0x0
INFO_ID_ERR = 0x1
INFO_TIME_OUT = 0x2
INFO_WRONG_ADDR = 0x3

#  define transaction types
TYPE_READ = 0x0
TYPE_WRITE = 0x1


#  make header for a specific transaction
def makeheader(trans_id, write):
    raw_header = (0x4 << 4) | ((trans_id & 0x7) << 1) | write
    return raw_header

