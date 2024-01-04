#
# This Makefile serves as a proxy for `zola` commands
#
# yay.


ZOLA ?= zola # allows for overriding zola location in case of debugging

SERVE_DIR := $(PWD)/public-dev
SERVE_FLAGS = --output-dir $(SERVE_DIR) --interface 0.0.0.0

DIST_DIR := $(PWD)/public
DEV_CONFIG := config.dev.toml
PROD_CONFIG := config.toml
NOW := $(shell date)

.PHONY: serve-prod
serve-prod:
	$(ZOLA) --config $(PROD_CONFIG) serve $(SERVE_FLAGS) --force

.PHONY: serve-dev
serve-dev:
	$(ZOLA) --config $(DEV_CONFIG) serve --drafts $(SERVE_FLAGS) --force

.PHONY: build
build:
	$(ZOLA) --config $(PROD_CONFIG) build --output-dir $(DIST_DIR) --force

.PHONY: check-unchanged
check-unchanged:
	bin/check-for-nothing-staged

.PHONY: check
check:
	$(ZOLA) check

.PHONY: deploy
deploy: check check-unchanged build
	git add $(DIST_DIR) static/processed_images
	git commit -m "AUTO: make deploy run on $(NOW)" --allow-empty
	bin/ship $(DIST_DIR) the-details master
