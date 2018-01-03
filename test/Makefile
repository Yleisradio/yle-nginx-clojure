DOCKER_COMPOSE = docker-compose -p yle-nginx-test
PID := $$$$

TEST_CONFS := $(wildcard conf/*)
TEST_SCRIPTS := $(wildcard scripts/*)

.PHONY: all clean test

all: test

clean:
	$(DOCKER_COMPOSE) down --rmi all -v
	-rm -rf .build_*

test: .build_test .build_bats
	$(DOCKER_COMPOSE) run --rm --name yle-nginx-bats-$(PID) bats
	@# Unfortunately the `--rm` option above won't remove depended services,
	@# i.e. nginx, so we have to stop it ourselves.
	@# https://github.com/docker/compose/issues/2791
	$(DOCKER_COMPOSE) down

.build_test: Dockerfile_test docker-compose.yml $(TEST_CONFS)
	$(DOCKER_COMPOSE) build $(DOCKER_BUILD_OPTIONS) nginx
	touch $@

.build_bats: Dockerfile_bats docker-compose.yml $(TEST_SCRIPTS)
	$(DOCKER_COMPOSE) build $(DOCKER_BUILD_OPTIONS) bats
	touch $@
