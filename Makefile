REMOTE_USER ?= lertumpai
REMOTE_HOST ?= 192.168.1.99
REMOTE_DIR ?= /home/lertumpai/applications/gold-price-alert
REMOTE_PASSWORD ?= S@rawit5171718

DOCKER_COMPOSE_FILE ?= api.docker-compose.yml
DOCKER_COMPOSE_TEMPLATE ?= template.docker-compose.yml
DOCKER_IMAGE_NAME ?= gold-price-alert-api
APP_TAR := api.tar

VERSION := $(shell node -p "require('./package.json').version")

deploy-mql5:
	@echo "[PROCESS] Deploying MQ5 file..."
	sshpass -p $(REMOTE_PASSWORD) scp binaryoption/lib/candle/v2.mqh $(REMOTE_USER)@$(REMOTE_HOST):$(REMOTE_DIR)
	@echo "[PROCESS] MQ5 file deployed!"