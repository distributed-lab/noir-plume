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
    c = ["0" for i in range(32)]
    msg = [str(i + 97) for i in range(3)]
    nullifier = ["0" for i in range(32)]
    pk = [["0" for i in range(32)] for _ in range(2)]
    s = ["0" for i in range(32)]

    return c, msg, nullifier, pk, s

def format_array(arr):
    return "[" + ", ".join(f'"{item}"' for item in arr) + "]"

def format_pk_array(pk):
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
    nullifier_str = format_array(nullifier)
    pk_str = format_pk_array(pk)
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
