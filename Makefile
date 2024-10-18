.PHONY: execute prove prove_ultra_honk verify write_vk_ultra_honk verify_ultra_honk write_vk verify zk zk_ultra_honk

execute:
	nargo execute plume --silence-warnings

prove_ultra_honk:
	bb prove_ultra_honk -b ./target/use.json -w ./target/plume.gz -o ./target/proof

prove:
	bb prove -b ./target/use.json -w ./target/plume.gz -o ./target/proof

write_vk_ultra_honk:
	bb write_vk_ultra_honk -b ./target/use.json -o ./target/vk

verify_ultra_honk:
	bb verify_ultra_honk -k ./target/vk -p ./target/proof

write_vk:
	bb write_vk -b ./target/use.json -o ./target/vk

verify:
	bb verify -k ./target/vk -p ./target/proof


zk_ultra_honk:
	make execute
	make prove_ultra_honk
	make verify_ultra_honk
	
zk:
	make execute
	make prove
	make verify