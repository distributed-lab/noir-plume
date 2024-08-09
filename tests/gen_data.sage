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

def update_prover_toml(filepath, version1: bool, msg_len: int):
    data = toml.load(filepath)
    (msg, c, s, pk, nullifier) = plume_generate_test_case(version1, msg_len)
    
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

def update_plume_version(is_v1: bool):
    path = "../crates/use/src/"
    p1_line = 13
    p2_line = 14

    with open(path + 'main.nr', 'r') as file:
        lines = file.readlines()

    if is_v1:
        lines[p1_line] = "    plume_v1(msg, c, s, pk, nullifier);\n"
        lines[p2_line] = "    // plume_v2(msg, c, s, pk, nullifier);\n"
    else:
        lines[p1_line] = "    // plume_v1(msg, c, s, pk, nullifier);\n"
        lines[p2_line] = "    plume_v2(msg, c, s, pk, nullifier);\n"

    with open(path + 'main.nr', 'w') as file:
        file.writelines(lines)


def update_MSG_LEN_variable(msg_len: int):
    path = "../crates/plume/src/"
    with open(path + 'constants.nr', 'r') as file:
        lines = file.readlines()
    
    MSG_LEN_line = 2
    lines[MSG_LEN_line] = lines[MSG_LEN_line][:-4] + str(msg_len) + ";\n"

    with open(path + 'constants.nr', 'w') as file:
        file.writelines(lines)


# Take MSG_LEN number and plume version (v1 or v2)
if __name__ == "__main__":
    run_command("nargo check")

    prover_toml_path = "../crates/use/Prover.toml"
    if len(sys.argv) != 3:
        print("Error: incorrect number of arguments")
        sys.exit()
        
    versions = ["v1", "v2"]

    if sys.argv[1] not in versions:
        print("Error:", sys.argv[1], "incorrect version.")
        sys.exit()

    is_v1 = sys.argv[1] == versions[0]
    msg_len = int(sys.argv[2])

    update_plume_version(is_v1)
    update_MSG_LEN_variable(msg_len)
    update_prover_toml(prover_toml_path, is_v1, msg_len)
