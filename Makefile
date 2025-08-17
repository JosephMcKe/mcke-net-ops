SHELL := /bin/bash

.PHONY: up down pull backup test-restore scan

up:
	docker compose up -d

down:
	docker compose down

pull:
	docker compose pull

backup:
	./scripts/restic_backup.sh

test-restore:
	./scripts/test_restore.sh

scan:
	./scripts/trivy_weekly.sh
