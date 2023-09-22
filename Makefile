init:
	docker-compose build

start:
	docker-compose up

stop:
	docker-compose down

get_deps:
	docker-compose run --rm app mix deps.get

setup_db:
	docker-compose up -d db
	docker-compose run --rm app mix ecto.setup

run_test:
	docker-compose run -e MIX_ENV=test --rm app mix test $(filter-out $@,$(MAKECMDGOALS))

credo:
	docker-compose run --rm app mix credo --strict

format:
	docker-compose run --rm app mix format

update:
	docker-compose run --rm app mix deps.update $(filter-out $@,$(MAKECMDGOALS))

mix:
	docker-compose run --rm app mix $(filter-out $@,$(MAKECMDGOALS))

NGROK_HOST := $$(curl --silent http://127.0.0.1:4040/api/tunnels | jq '.tunnels[0].public_url' | tr -d '"' | awk -F/ '{print $$3}')


.PHONY: serve-ngrok
serve-ngrok: ## Start Phoenix bound to ngrok address
	@echo "🌍 Exposing My App @ https://$(NGROK_HOST)"
	env HOST=$(NGROK_HOST) iex -S mix phx.server
