# Include version definitions
include VERSIONS

CURL = curl --fail --silent --show-error --location
DOCKER_BUILD_ARGS = NGINX_VERSION NGINX_CLOJURE_VERSION

CONFS := $(wildcard conf/*)
SOURCE_NAMES := nginx-$(NGINX_VERSION) nginx-clojure-$(NGINX_CLOJURE_VERSION)

.PHONY: all clean shasums test update-lein
.SECONDARY: $(addsuffix .tar.gz, $(SOURCE_NAMES))

all: .build_nginx

clean:
	-rm -rf src .build_*
	$(MAKE) -C test clean

shasums: $(addsuffix .tar.gz, $(SOURCE_NAMES))
	@for f in $^; do \
	    echo "Generating checksum file for '$$f'"; \
	    shasum -a 256 $$f > $$f.shasum; \
	done

test: .build_nginx
	$(MAKE) -C test

update-lein:
	$(CURL) --output scripts/lein https://raw.github.com/technomancy/leiningen/stable/bin/lein
	chmod +x scripts/lein

.build_nginx: Dockerfile scripts/lein $(addprefix src/, $(SOURCE_NAMES)) $(CONFS)
	docker build \
	    $(DOCKER_BUILD_OPTIONS) \
	    $(foreach arg, $(DOCKER_BUILD_ARGS),--build-arg $(arg)=$(value $(arg))) \
	    $(addprefix --tag , $(DOCKER_TAGS)) \
	    --tag yle-nginx-clojure \
	    .
	touch $@

src/%: %.tar.gz .%.tar.gz.check
	mkdir -p src
	tar xzf $< -C src
	touch $@

nginx-clojure-%.tar.gz:
	$(CURL) --output $@ https://github.com/nginx-clojure/nginx-clojure/archive/v$*.tar.gz

nginx-%.tar.gz:
	$(CURL) --output $@ https://nginx.org/download/nginx-$*.tar.gz

.%.check: %.shasum %
	shasum -c $<
	touch $@

%.shasum:
	@echo "Checksum file '$@' does not exist. Run \`make shasums\`." >&2
	@exit 1
