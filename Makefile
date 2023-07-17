#
# This Makefile serves as a proxy for `zola` commands
#
# yay.
#

SERVE_DIR := public
SERVE_FLAGS = --output-dir $(SERVE_DIR) --interface 0.0.0.0
DIST_DIR := public
DEV_CONFIG := config.dev.toml
PROD_CONFIG := config.toml
NOW := $(shell date)

.PHONY: serve-dev serve-prod build deploy dates-dirs check-unchanged check

serve-prod:
	zola --config $(PROD_CONFIG) serve $(SERVE_FLAGS)

serve-dev:
	zola --config $(DEV_CONFIG) serve --drafts $(SERVE_FLAGS)

build:
	zola --config $(PROD_CONFIG) build --output-dir $(DIST_DIR) --force

check-unchanged:
	bin/check-for-nothing-staged

check:
	zola check

deploy: check check-unchanged build
	git add $(DIST_DIR)
	git commit -m "AUTO: make deploy run on $(NOW)" --allow-empty
	bin/ship $(DIST_DIR) the-details master
