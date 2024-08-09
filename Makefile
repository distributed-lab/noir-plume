.PHONY: fmt check execute prove verify zk

fmt:
	nargo fmt

check:
	nargo check

execute:
	nargo execute plume

prove: 
	bb prove -b ./target/use.json -w ./target/plume.gz -o ./target/proof

verify:
	bb write_vk -b ./target/use.json -o ./target/vk
	bb verify -k ./target/vk -p ./target/proof

zk:
	make execute
	make prove
	make verify