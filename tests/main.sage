load('test_gen.sage')

if __name__ == "__main__":
    (msg, c, s, pk, nullifier) = plume_generate_test_case(False)
    print("msg =", msg, end='\n\n')
    print("c =", c, end='\n\n')
    print("s =", s, end='\n\n')
    print("pk =", pk, end='\n\n')
    print("nullifier =", nullifier)
