REMOTE_USER ?= lertumpai
REMOTE_HOST ?= 192.168.1.99
REMOTE_DIR  ?= /home/$(REMOTE_USER)/applications
REMOTE_PASSWORD ?= S@rawit5171718

# MetaTrader 5 specific paths
MT5_PATH = /home/$(REMOTE_USER)/.wine/drive_c/Program\ Files/MetaTrader\ 5\ EXNESS/MQL5/Include/Lertumpai/signal

DOCKER_COMPOSE_FILE ?= api.docker-compose.yml
DOCKER_COMPOSE_TEMPLATE ?= template.docker-compose.yml
DOCKER_IMAGE_NAME ?= gold-price-alert-api
APP_TAR := api.tar

VERSION := $(shell node -p "require('./package.json').version" 2>/dev/null || echo "0.0.0")

.PHONY: deploy-mql5 deploy-signal-mt5

# Source file to deploy (override with `make deploy-mql5 MQL_FILE=path/to/file`)
MQL_FILE ?= binaryoption/lib/connector_martingale.mqh

deploy-signal:
	@if [ ! -f "$(MQL_FILE)" ]; then \
		echo "[ERROR] Local file not found: $(MQL_FILE)"; \
		exit 1; \
	fi
	@echo "[PROCESS] Deploying MQL5 file: $(MQL_FILE) -> $(REMOTE_USER)@$(REMOTE_HOST):$(REMOTE_DIR)/";
	@if [ -z "$(REMOTE_PASSWORD)" ]; then \
		ssh -o StrictHostKeyChecking=no $(REMOTE_USER)@$(REMOTE_HOST) "mkdir -p '$(REMOTE_DIR)'"; \
		scp -o StrictHostKeyChecking=no "$(MQL_FILE)" $(REMOTE_USER)@$(REMOTE_HOST):"$(REMOTE_DIR)/"; \
	else \
		sshpass -p "$(REMOTE_PASSWORD)" ssh -o StrictHostKeyChecking=no $(REMOTE_USER)@$(REMOTE_HOST) "mkdir -p '$(REMOTE_DIR)'"; \
		sshpass -p "$(REMOTE_PASSWORD)" scp -o StrictHostKeyChecking=no "$(MQL_FILE)" $(REMOTE_USER)@$(REMOTE_HOST):"$(REMOTE_DIR)/"; \
	fi
	@echo "[DONE] MQ5 file deployed."

deploy-signal-mt5:
	@echo "[PROCESS] Deploying all signal files to MetaTrader 5 Include directory...";
	@echo "Target directory: $(MT5_PATH)";
	@if [ -z "$(REMOTE_PASSWORD)" ]; then \
		ssh -o StrictHostKeyChecking=no $(REMOTE_USER)@$(REMOTE_HOST) "mkdir -p '$(MT5_PATH)'"; \
		scp -o StrictHostKeyChecking=no -r binaryoption/lib/signal/* "$(REMOTE_USER)@$(REMOTE_HOST):$(MT5_PATH)/"; \
	else \
		sshpass -p "$(REMOTE_PASSWORD)" ssh -o StrictHostKeyChecking=no $(REMOTE_USER)@$(REMOTE_HOST) "mkdir -p '$(MT5_PATH)'"; \
		sshpass -p "$(REMOTE_PASSWORD)" scp -o StrictHostKeyChecking=no -r binaryoption/lib/signal/* "$(REMOTE_USER)@$(REMOTE_HOST):$(MT5_PATH)/"; \
	fi
	@echo "[DONE] All signal files deployed to MetaTrader 5 Include directory."
	@echo "[VERIFY] Checking deployed files...";
	@if [ -z "$(REMOTE_PASSWORD)" ]; then \
		ssh -o StrictHostKeyChecking=no $(REMOTE_USER)@$(REMOTE_HOST) "ls -la '$(MT5_PATH)'"; \
	else \
		sshpass -p "$(REMOTE_PASSWORD)" ssh -o StrictHostKeyChecking=no $(REMOTE_USER)@$(REMOTE_HOST) "ls -la '$(MT5_PATH)'"; \
	fi