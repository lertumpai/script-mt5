REMOTE_USER ?= lertumpai
REMOTE_HOST ?= 192.168.1.99
REMOTE_DIR  ?= /home/$(REMOTE_USER)/applications
REMOTE_PASSWORD ?= S@rawit5171718

# MetaTrader 5 specific paths
MT5_INCLUDE_PATH = /home/$(REMOTE_USER)/.wine/drive_c/Program\ Files/MetaTrader\ 5\ EXNESS/MQL5/Include/Lertumpai/signal
MT5_EXPERT_PATH = /home/$(REMOTE_USER)/.wine/drive_c/Program\ Files/MetaTrader\ 5\ EXNESS/MQL5/Experts

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

deploy-signal:
	@echo "[PROCESS] Deploying all signal files to MetaTrader 5 Include directory...";
	@echo "Target directory: $(MT5_INCLUDE_PATH)";
	@if [ -z "$(REMOTE_PASSWORD)" ]; then \
		ssh -o StrictHostKeyChecking=no $(REMOTE_USER)@$(REMOTE_HOST) "mkdir -p '$(MT5_INCLUDE_PATH)'"; \
		scp -o StrictHostKeyChecking=no -r binaryoption/lib/signal/* "$(REMOTE_USER)@$(REMOTE_HOST):$(MT5_INCLUDE_PATH)/"; \
	else \
		sshpass -p "$(REMOTE_PASSWORD)" ssh -o StrictHostKeyChecking=no $(REMOTE_USER)@$(REMOTE_HOST) "mkdir -p '$(MT5_INCLUDE_PATH)'"; \
		sshpass -p "$(REMOTE_PASSWORD)" scp -o StrictHostKeyChecking=no -r binaryoption/lib/signal/* "$(REMOTE_USER)@$(REMOTE_HOST):$(MT5_INCLUDE_PATH)/"; \
	fi
	@echo "[DONE] All signal files deployed to MetaTrader 5 Include directory."
	@echo "[VERIFY] Checking deployed files...";

deploy-lib:
	@echo "[PROCESS] Deploying all lib files to MetaTrader 5 Include directory...";
	@echo "Target directory: $(MT5_INCLUDE_PATH)";
	@if [ -z "$(REMOTE_PASSWORD)" ]; then \
		ssh -o StrictHostKeyChecking=no $(REMOTE_USER)@$(REMOTE_HOST) "mkdir -p '$(MT5_INCLUDE_PATH)'"; \
		scp -o StrictHostKeyChecking=no -r binaryoption/lib/* "$(REMOTE_USER)@$(REMOTE_HOST):$(MT5_INCLUDE_PATH)/"; \
	else \
		sshpass -p "$(REMOTE_PASSWORD)" ssh -o StrictHostKeyChecking=no $(REMOTE_USER)@$(REMOTE_HOST) "mkdir -p '$(MT5_INCLUDE_PATH)'"; \
		sshpass -p "$(REMOTE_PASSWORD)" scp -o StrictHostKeyChecking=no binaryoption/lib/api.mqh "$(REMOTE_USER)@$(REMOTE_HOST):$(MT5_INCLUDE_PATH)/"; \
		sshpass -p "$(REMOTE_PASSWORD)" scp -o StrictHostKeyChecking=no binaryoption/lib/connector_mt2.mqh "$(REMOTE_USER)@$(REMOTE_HOST):$(MT5_INCLUDE_PATH)/"; \
		sshpass -p "$(REMOTE_PASSWORD)" scp -o StrictHostKeyChecking=no binaryoption/lib/date.mqh "$(REMOTE_USER)@$(REMOTE_HOST):$(MT5_INCLUDE_PATH)/"; \
		sshpass -p "$(REMOTE_PASSWORD)" scp -o StrictHostKeyChecking=no binaryoption/lib/price.mqh "$(REMOTE_USER)@$(REMOTE_HOST):$(MT5_INCLUDE_PATH)/"; \
	fi
	@echo "[DONE] All lib files deployed to MetaTrader 5 Include directory."

deploy-service:
	@echo "[PROCESS] Deploying all service files to MetaTrader 5 Experts directory...";
	@echo "Target directory: $(MT5_EXPERT_PATH)";
	@if [ -z "$(REMOTE_PASSWORD)" ]; then \
		ssh -o StrictHostKeyChecking=no $(REMOTE_USER)@$(REMOTE_HOST) "mkdir -p '$(MT5_EXPERT_PATH)'"; \
		scp -o StrictHostKeyChecking=no -r binaryoption/service/* "$(REMOTE_USER)@$(REMOTE_HOST):$(MT5_EXPERT_PATH)/"; \
	else \
		sshpass -p "$(REMOTE_PASSWORD)" ssh -o StrictHostKeyChecking=no $(REMOTE_USER)@$(REMOTE_HOST) "mkdir -p '$(MT5_EXPERT_PATH)'"; \
		sshpass -p "$(REMOTE_PASSWORD)" scp -o StrictHostKeyChecking=no -r binaryoption/service/* "$(REMOTE_USER)@$(REMOTE_HOST):$(MT5_EXPERT_PATH)/"; \
	fi
	@echo "[DONE] All service files deployed to MetaTrader 5 Experts directory."