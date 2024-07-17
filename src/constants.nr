global MSG_LEN = 3;
global PADDING_SIZE = 64 + 2 + 50 + 1;
global NUM_PREIMAGE_BYTES = 32 + 1 + 50;

// 2^256 - 2^32 - 2^9 - 2^8 - 2^7 - 2^6 - 2^4 - 1 constant in byte view
global SECP256K1_PRIME = [
    47, 252, 255, 255, 254, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255,
    255, 255, 255, 255, 255, 255, 255, 255
];
