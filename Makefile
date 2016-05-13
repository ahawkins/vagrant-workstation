VAGRANT:=tmp/vagrant

WORKSTATION_NAME:=testing
WORKSTATION_VAGRANTFILE=$(CURDIR)/test/Vagrantfile
XDG_DATA_HOME:=$(CURDIR)/tmp/data
WORKSTATION_PROJECT_PATH:=$(CURDIR)/tmp/scratch

MAN_ENV:=tmp/man_env
MAN_IMAGE:=ahawkins/vagrant-workstaion

ENV:=env \
	PATH=$(CURDIR)/bin:$$PATH \
	XDG_DATA_HOME=$(XDG_DATA_HOME)

$(WORKSTATION_PROJECT_PATH):
	mkdir -p $@

$(WORKSTATION_PROJECT_PATH)/smoke:
	mkdir -p $@

$(VAGRANT): $(WORKSTATION_PROJECT_PATH)
	$(ENV) workstation up -p $< -n $(WORKSTATION_NAME) -v $(WORKSTATION_VAGRANTFILE)
	mkdir -p $(@D)
	touch $@

.PHONY: test
test:
ifdef FILE
	$(ENV) bats $(FILE)
else
	$(ENV) bats test
endif

SMOKE_TEST_ENV:=$(ENV) WORKSTATION_NAME=$(WORKSTATION_NAME)

.PHONY: test-smoke
test-smoke: $(VAGRANT) | $(WORKSTATION_PROJECT_PATH)/smoke
	$(SMOKE_TEST_ENV) sh -c 'cd $| && workstation run true'
	$(SMOKE_TEST_ENV) workstation suspend
	$(SMOKE_TEST_ENV) workstation halt
	$(SMOKE_TEST_ENV) workstation reload
	$(SMOKE_TEST_ENV) sh -c 'cd $| && workstation run true'
	$(SMOKE_TEST_ENV) workstation destroy -f
	$(MAKE) clean

.PHONY: clean
clean:
	-env VAGRANT_CWD=$(dir $(WORKSTATION_VAGRANTFILE)) vagrant destroy -f 2>&1
	rm -rf $(VAGRANT) $(XDG_DATA_HOME) $(WORKSTATION_PROJECT_PATH)
	$(MAKE) -C man clean
