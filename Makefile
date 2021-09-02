
DIAG=diag.log
BTEST=../../../auxil/btest/btest

make-verbose: docker
	@rm -f $(DIAG)
	@$(BTEST) -f $(DIAG)

make-brief: docker
	@rm -f $(DIAG)
	@$(BTEST) -b -f $(DIAG)

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

.PHONY: make-verbose make-brief clean coverage distclean docker update-timing
