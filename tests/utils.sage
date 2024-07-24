def bytes_to_num(arr, base=8):
    base = 2**base
    res = 0

    for i in range(len(arr)):
        res += base**i * int(arr[i])
    return res

def num_to_bytes(num):
    res = []
    while num > 0:
        res.append(num & 0xff)
        num >>= 8
    return res
