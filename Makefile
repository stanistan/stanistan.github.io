# allows for overriding zola location in case of debugging
ZOLA ?= zola

SERVE_FLAGS = --output-dir $(SERVE_DIR) --interface 0.0.0.0
SERVE_DIR := $(PWD)/public-dev
DIST_DIR := $(PWD)/public
DEV_CONFIG := config.dev.toml
PROD_CONFIG := config.toml
NOW := $(shell date)

.PHONY: help
help: ## show help (this)
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: serve-prod
serve-prod: ## serve production config (dev)
	$(ZOLA) --config $(PROD_CONFIG) serve $(SERVE_FLAGS) --force

.PHONY: serve-dev
serve-dev: ## serve dev config (including drafts)
	$(ZOLA) --config $(DEV_CONFIG) serve --drafts $(SERVE_FLAGS) --force

.PHONY: build
build: ## build static site output
	$(ZOLA) --config $(PROD_CONFIG) build --output-dir $(DIST_DIR) --force

.PHONY: check-unchanged
check-unchanged: ## check for nothing staged
	bin/check-for-nothing-staged

.PHONY: check
check: ## run zola check
	$(ZOLA) check

.PHONY: deploy
deploy: check check-unchanged build
	git add $(DIST_DIR) static/processed_images
	git commit -m "AUTO: make deploy run on $(NOW)" --allow-empty
	bin/ship $(DIST_DIR) the-details master
