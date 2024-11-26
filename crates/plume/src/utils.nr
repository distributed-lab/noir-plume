pub fn to_field<let N: u32>(bytes: [u8; N]) -> Field {
    let mut as_field = 0;
    let mut offset = 1;
    for i in 0..N {
        let mut index = i;
        index = N - i - 1;
        as_field += (bytes[index] as Field) * offset;
        offset *= 256;
    }
    std::as_witness(as_field);

    as_field
}
