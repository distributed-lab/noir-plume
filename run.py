import subprocess
import toml

# Run a shell command and print the output
def run_command(command):
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    if result.stdout:
        print(result.stdout)
    
    if result.returncode != 0:
        if result.stderr:
            print(result.stderr)
        raise subprocess.CalledProcessError(result.returncode, command)

def fill_values():
    c = [84, 50, 232, 188, 237, 50, 59, 254, 35, 82, 174, 186, 20, 85, 170, 45, 111, 86, 182, 159, 71, 26, 115, 32, 175, 219, 109, 146, 44, 252, 167, 198]
    msg = [65, 110, 32, 101, 120, 97, 109, 112, 108, 101, 32, 97, 112, 112, 32, 109, 101, 115, 115, 97, 103, 101, 32, 115, 116, 114, 105, 110, 103]
    nullifier = [[48, 88, 229, 103, 12, 29, 111, 98, 30, 92, 164, 115, 100, 166, 197, 252, 69, 231, 204, 194, 224, 185, 228, 221, 138, 239, 114, 129, 210, 62, 188, 87], [115, 203, 158, 229, 127, 8, 214, 145, 168, 143, 163, 126, 230, 58, 159, 159, 96, 17, 225, 136, 33, 221, 110, 228, 58, 243, 88, 141, 72, 65, 47, 106]]
    pk = [[174, 118, 96, 73, 116, 167, 211, 28, 204, 218, 230, 13, 255, 191, 234, 249, 84, 67, 129, 16, 131, 166, 114, 38, 224, 9, 141, 224, 142, 2, 236, 12], [189, 127, 210, 11, 107, 191, 40, 193, 81, 143, 207, 83, 183, 9, 0, 93, 249, 18, 173, 1, 136, 142, 164, 182, 151, 152, 64, 160, 251, 113, 244, 239]]
    s = [202, 40, 186, 121, 96, 189, 224, 125, 45, 19, 234, 232, 99, 209, 144, 177, 95, 151, 46, 209, 51, 227, 97, 247, 229, 111, 203, 132, 125, 2, 159, 230]

    return c, msg, nullifier, pk, s

def format_array(arr):
    return "[" + ", ".join(f'"{item}"' for item in arr) + "]"

def format_double_array(pk):
    return "[" + ", ".join(format_array(subarr) for subarr in pk) + "]"

def update_prover_toml(filepath):
    data = toml.load(filepath)
    
    c, msg, nullifier, pk, s = fill_values()
    
    data['c'] = c
    data['msg'] = msg
    data['nullifier'] = nullifier
    data['pk'] = pk
    data['s'] = s
    
    c_str = format_array(c)
    msg_str = format_array(msg)
    nullifier_str = format_double_array(nullifier)
    pk_str = format_double_array(pk)
    s_str = format_array(s)
    
    with open(filepath, 'w') as f:
        f.write(f'c = {c_str}\n')
        f.write(f'msg = {msg_str}\n')
        f.write(f'nullifier = {nullifier_str}\n')
        f.write(f'pk = {pk_str}\n')
        f.write(f's = {s_str}\n')

if __name__ == "__main__":
    run_command("nargo check")

    prover_toml_path = "Prover.toml"
    update_prover_toml(prover_toml_path)

    run_command("nargo prove")
