docker:
	./make.sh

# This might need root
clean:
	rm -rf ./build/*

# This might need root
distclean: clean
	rm -rf ./cache/*
	docker rmi -f zeektest/prebuild zeektest/build zeektest/zeek

.PHONY: docker clean purge
