def crc8(data):
    crc = 0xff
    for i in range(len(data)):
        crc ^= data[i]
        for j in range(8):
            if (crc & 0x80) != 0:
                crc = (crc << 1) ^ 0x31
            else:
                crc <<= 1

            crc &= 0xFF

    return crc