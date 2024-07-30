import sys
import subprocess
import toml
load('test_gen.sage')

# Run a shell command and print the output
def run_command(command):
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    if result.stdout:
        print(result.stdout, end='')
    
    if result.returncode != 0:
        if result.stderr:
            print(result.stderr)
        raise subprocess.CalledProcessError(result.returncode, command)

def format_array(arr):
    return "[" + ", ".join(f'"{item}"' for item in arr) + "]"

def format_double_array(pk):
    return "[" + ", ".join(format_array(subarr) for subarr in pk) + "]"

def update_prover_toml(filepath, version1):
    data = toml.load(filepath)
    (msg, c, s, pk, nullifier) = plume_generate_test_case(version1)
    
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

    prover_toml_path = "../crates/use/Prover.toml"
    is_v1 = len(sys.argv) == 1 or sys.argv[1] == "v1"
    update_prover_toml(prover_toml_path, is_v1)

    run_command('nargo execute plume')
    run_command('bb prove -b ../target/use.json -w ../target/plume.gz -o ../target/proof')
    
    run_command('bb write_vk -b ../target/use.json -o ../target/vk')
    run_command('bb verify -k ../target/vk -p ../target/proof')
