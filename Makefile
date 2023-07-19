#
# This Makefile serves as a proxy for `zola` commands
#
# yay.
#

SERVE_DIR := public-dev 
SERVE_FLAGS = --output-dir $(SERVE_DIR) --interface 0.0.0.0

DIST_DIR := public
DEV_CONFIG := config.dev.toml
PROD_CONFIG := config.toml
NOW := $(shell date)

.PHONY: serve-prod
serve-prod:
	zola --config $(PROD_CONFIG) serve $(SERVE_FLAGS)

.PHONY: serve-dev
serve-dev:
	zola --config $(DEV_CONFIG) serve --drafts $(SERVE_FLAGS)

.PHONY: build
build:
	zola --config $(PROD_CONFIG) build --output-dir $(DIST_DIR) --force

.PHONY: check-unchanged
check-unchanged:
	bin/check-for-nothing-staged

.PHONY: check
check:
	zola check

.PHONY: deploy
deploy: check check-unchanged build
	git add $(DIST_DIR) static/processed_images
	git commit -m "AUTO: make deploy run on $(NOW)" --allow-empty
	bin/ship $(DIST_DIR) the-details master
