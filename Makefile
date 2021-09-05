CONTAINER := admin dispatch dodup publisher repositoryserver scheduler servicedispatch serviceservice signd signer sourceserver worker
CONTAINER_DEPS := base
PREFIX ?= docker.home.jm0.eu/obs/
TAG ?= latest

all: $(addsuffix .stamp,$(CONTAINER_DEPS)) $(addsuffix .stamp,$(CONTAINER))

%.stamp: Dockerfile.%
	docker build \
		-t $(PREFIX)$(subst Dockerfile.,,$<):$(TAG) \
		--build-arg PREFIX="$(PREFIX)" \
		--build-arg TAG="$(TAG)" \
		-f $< $(CURDIR)
	touch $@

clean:
	rm -fv *.stamp

push: $(addsuffix .push,$(CONTAINER))

%.push: %.stamp
	docker push $(PREFIX)$(subst .stamp,,$<):$(TAG)
