def bytes_to_num(arr):
    return int.from_bytes(bytes(arr), byteorder='little')

def num_to_bytes(num):
    res = []
    while num > 0:
        res.append(num & 0xff)
        num >>= 8
    return res

def get_limbs(num):
    num = int(num)
    res = [0] * 3
    module = 0xffffffffffffffffffffffffffffff
    
    for i in range(len(res)):
        res[i] = num & module
        num >>= 120
    return res