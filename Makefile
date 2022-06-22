DIAG=diag.log
BTEST=../../../auxil/btest/btest

# Fall back to installed btest, for runs outside of a full Zeek tree.
ifeq ("$(wildcard $(BTEST))","")
	BTEST=btest
endif

make-verbose: docker test-verbose

make-brief: docker test-brief

test-verbose: docker
	@rm -f $(DIAG)
	@$(BTEST) -j -f $(DIAG)

test-brief: docker
	@rm -f $(DIAG)
	@$(BTEST) -j -b -f $(DIAG)

clean:
	$(MAKE) -C Docker clean

distclean:
	$(MAKE) -C Docker distclean

docker:
	$(MAKE) -C Docker

coverage:
	true

update-timing:
	true

.PHONY: make-verbose make-brief test-verbose test-brief clean coverage distclean docker update-timing
