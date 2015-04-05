VAGRANT:=tmp/vagrant

WORKSTATION_VAGRANTFILE=$(CURDIR)/test/Vagrantfile
WORKSTATION_HOME:=$(CURDIR)/tmp/data
WORKSTATION_PROJECT_PATH:=$(CURDIR)/tmp/scratch

ENV=env \
		PATH=$(CURDIR)/bin:$$PATH \
		WORKSTATION_HOME=$(WORKSTATION_HOME) \
		WORKSTATION_VAGRANTFILE=$(WORKSTATION_VAGRANTFILE)

$(WORKSTATION_PROJECT_PATH):
	mkdir -p $@

$(WORKSTATION_PROJECT_PATH)/smoke:
	mkdir -p $@

$(VAGRANT): $(WORKSTATION_PROJECT_PATH)
	$(ENV) workstation up $<
	mkdir -p $(@D)
	touch $@

.PHONY: test
test: $(VAGRANT)
	$(ENV) WORKSTATION_PROJECT_PATH=$(WORKSTATION_PROJECT_PATH) bats test

.PHONY: test-smoke
test-smoke: $(VAGRANT) $(WORKSTATION_PROJECT_PATH)/smoke
	$(ENV) workstation run -p smoke true
	$(ENV) workstation suspend
	$(ENV) workstation halt
	$(ENV) workstation reload
	$(ENV) workstation run -p smoke true
	$(ENV) workstation destroy -f
	$(MAKE) clean

.PHONY: clean
clean: 
	-env VAGRANT_CWD=$(dir $(WORKSTATION_VAGRANTFILE)) vagrant destroy -f 2>&1
	rm -rf $(VAGRANT) $(WORKSTATION_HOME) $(WORKSTATION_PROJECT_PATH)
