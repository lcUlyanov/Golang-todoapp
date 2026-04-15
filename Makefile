include .env
export

export PROJECT_ROOT=${CURDIR}

env-up:
	@docker compose up -d todoapp-postgres

env-down:
	@docker compose down todoapp-postgres

env-cleanup:
	@setlocal enabledelayedexpansion && \
	echo This will remove the database volume. Are you sure? (y/n) && \
	set /p confirm= && \
	if "!confirm!"=="y" ( \
		docker compose down todoapp-postgres port-forwarder && \
		if exist $(PROJECT_ROOT)\out\pgdata rmdir /S /Q $(PROJECT_ROOT)\out\pgdata && \
		echo Database volume cleaned up. \
	) else ( \
		echo Cleanup cancelled. \
	)


migrate-create:
	@if "$(seq)"=="" ( \
		echo Error: Migration name is required. Usage: make migrate-create seq=your_migration_name && \
		exit 1 \
	) else ( \
		docker compose run --rm todoapp-postgres-migrate create -ext sql -dir /migrations -seq "$(seq)" \
	)

migrate-up:
	@make migrate-action action=up

migrate-down:
	@make migrate-action action=down

migrate-action:
	@if "$(action)"=="" ( \
		echo Error: Migration action is required. Usage: make migrate-action action=up/down && exit 1 \
	) else ( \
		docker compose run --rm todoapp-postgres-migrate -path /migrations -database postgres://$(POSTGRES_USER):$(POSTGRES_PASSWORD)@todoapp-postgres:5432/$(POSTGRES_DB)?sslmode=disable "$(action)" \
	)
	

env-port-forward:
	@docker compose up -d port-forwarder

env-port-close:
	@docker compose down port-forwarder

todoapp-run:
	@go mod tidy
	@set LOGGER_FOLDER=$(PROJECT_ROOT)/out/logs&& \
	set POSTGRES_HOST=localhost&& \
	go run $(PROJECT_ROOT)/cmd/todoapp/main.go