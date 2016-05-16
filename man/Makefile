RUBY_IMAGE:=$(shell grep FROM Dockerfile | cut -f 2 -d ' ')
DOCKER:=tmp/docker
IMAGE:=ahawkins/vagrant-workstation

MAN:=dist/workstation.man1

.DEFAULT_GOAL:=dist

Gemfile.lock: Gemfile
	docker run --rm -it -v $(CURDIR):/data -w /data $(RUBY_IMAGE) \
		bundle package --all

$(DOCKER): Gemfile.lock Dockerfile
	docker build -t $(IMAGE) .
	mkdir -p $(@D)
	touch $@

$(MAN): $(DOCKER)
	mkdir -p $(@D) tmp
	docker run --rm -it -v $(CURDIR):/data -w /data $(IMAGE) \
		asciidoctor -d manpage -b manpage -D $(@D) -o $(@F) man.asciidoc

.PHONY: dist
dist: $(MAN)

.PHONY: clean
clean:
	rm -rf $(DOCKER_IMAGE) $(MAN)
