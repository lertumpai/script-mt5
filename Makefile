REMOTE_USER ?= lertumpai
REMOTE_HOST ?= 192.168.1.99
REMOTE_DIR  ?= /home/$(REMOTE_USER)/applications
REMOTE_PASSWORD ?= S@rawit5171718

DOCKER_COMPOSE_FILE ?= api.docker-compose.yml
DOCKER_COMPOSE_TEMPLATE ?= template.docker-compose.yml
DOCKER_IMAGE_NAME ?= gold-price-alert-api
APP_TAR := api.tar

VERSION := $(shell node -p "require('./package.json').version" 2>/dev/null || echo "0.0.0")

.PHONY: deploy-mql5 deploy-signal deploy-signal-mt5 deploy-lib deploy-service

# Source file to deploy (override with `make deploy-mql5 MQL_FILE=path/to/file`)
MQL_FILE ?= binaryoption/lib/connector_martingale.mqh

deploy:
	make deploy-signal
	make deploy-lib
	make deploy-service

deploy-signal:
	@echo "[PROCESS] Deploying all signal files to MetaTrader 5 Include directory...";
	@echo "Target directory: $(MT5_INCLUDE_PATH)";
	sshpass -p "$(REMOTE_PASSWORD)" ssh -o StrictHostKeyChecking=no $(REMOTE_USER)@$(REMOTE_HOST) "mkdir -p '/home/$(REMOTE_USER)/.wine/drive_c/Program Files/MetaTrader 5 EXNESS/MQL5/Include/Lertumpai/signal'";
	sshpass -p "$(REMOTE_PASSWORD)" scp -o StrictHostKeyChecking=no -r binaryoption/lib/signal/* "$(REMOTE_USER)@$(REMOTE_HOST):/home/$(REMOTE_USER)/.wine/drive_c/Program Files/MetaTrader 5 EXNESS/MQL5/Include/Lertumpai/signal/";
	@echo "[DONE] All signal files deployed to MetaTrader 5 Include directory."

deploy-lib:
	@echo "[PROCESS] Deploying all lib files to MetaTrader 5 Include directory...";
	@echo "Target directory: $(MT5_INCLUDE_PATH)";
	sshpass -p "$(REMOTE_PASSWORD)" ssh -o StrictHostKeyChecking=no $(REMOTE_USER)@$(REMOTE_HOST) "mkdir -p /home/$(REMOTE_USER)/.wine/drive_c/Program Files/MetaTrader 5 EXNESS/MQL5/Include/Lertumpai";
	sshpass -p "$(REMOTE_PASSWORD)" scp -o StrictHostKeyChecking=no binaryoption/lib/api.mqh "$(REMOTE_USER)@$(REMOTE_HOST):/home/$(REMOTE_USER)/.wine/drive_c/Program Files/MetaTrader 5 EXNESS/MQL5/Include/Lertumpai/";
	sshpass -p "$(REMOTE_PASSWORD)" scp -o StrictHostKeyChecking=no binaryoption/lib/date.mqh "$(REMOTE_USER)@$(REMOTE_HOST):/home/$(REMOTE_USER)/.wine/drive_c/Program Files/MetaTrader 5 EXNESS/MQL5/Include/Lertumpai/";
	sshpass -p "$(REMOTE_PASSWORD)" scp -o StrictHostKeyChecking=no binaryoption/lib/price.mqh "$(REMOTE_USER)@$(REMOTE_HOST):/home/$(REMOTE_USER)/.wine/drive_c/Program Files/MetaTrader 5 EXNESS/MQL5/Include/Lertumpai/";
	@echo "[DONE] All lib files deployed to MetaTrader 5 Include directory."

deploy-service:
	@echo "[PROCESS] Deploying all service files to MetaTrader 5 Experts directory...";
	@echo "Target directory: $(MT5_EXPERT_PATH)";
	sshpass -p "$(REMOTE_PASSWORD)" ssh -o StrictHostKeyChecking=no $(REMOTE_USER)@$(REMOTE_HOST) "mkdir -p /home/$(REMOTE_USER)/.wine/drive_c/Program Files/MetaTrader 5 EXNESS/MQL5/Experts";
	sshpass -p "$(REMOTE_PASSWORD)" scp -o StrictHostKeyChecking=no -r binaryoption/service/* "$(REMOTE_USER)@$(REMOTE_HOST):/home/$(REMOTE_USER)/.wine/drive_c/Program Files/MetaTrader 5 EXNESS/MQL5/Experts/";
	@echo "[DONE] All service files deployed to MetaTrader 5 Experts directory."