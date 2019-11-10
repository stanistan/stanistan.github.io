# This Makefile serves as a proxy for `zola` commands

SERVE_DIR := public
DIST_DIR := dist
DEV_CONFIG := config.dev.toml
PROD_CONFIG := config.toml
NOW := $(shell date)

.PHONY: serve-dev serve-prod build deploy dates-dirs check-unchanged check

serve-prod:
	zola --config $(PROD_CONFIG) serve --output-dir $(SERVE_DIR)

serve-dev:
	zola --config $(DEV_CONFIG) serve --output-dir $(SERVE_DIR) --drafts

build:
	zola --config $(PROD_CONFIG) build --output-dir $(DIST_DIR)

date-dirs:
	bin/verify-content-dates

check-unchanged:
	bin/check-for-nothing-staged

check:
	shellcheck bin/*
	zola check

deploy: check check-unchanged build
	git add $(DIST_DIR)
	git commit -m "AUTO: make deploy run on $(NOW)" --allow-empty
	bin/ship $(DIST_DIR) the-details master
