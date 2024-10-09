.PHONY: fmt check execute prove prove_ultra_honk verify verify_ultra_honk zk zk_ultra_honk

fmt:
	nargo fmt

check:
	nargo check

execute:
	nargo execute plume


prove_ultra_honk:
	bb prove_ultra_honk -b ./target/use.json -w ./target/plume.gz -o ./target/proof

prove:
	bb prove -b ./target/use.json -w ./target/plume.gz -o ./target/proof


verify_ultra_honk:
	bb write_vk_ultra_honk -b ./target/use.json -o ./target/vk
	bb verify_ultra_honk -k ./target/vk -p ./target/proof

verify:
	bb write_vk -b ./target/use.json -o ./target/vk
	bb verify -k ./target/vk -p ./target/proof


zk_ultra_honk:
	make execute
	make prove_ultra_honk
	make verify_ultra_honk
	
zk:
	make execute
	make prove
	make verify