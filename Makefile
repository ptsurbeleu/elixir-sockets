# NOTES:
# - Removing cache.ets has been added to fix up annoying issue with the following error occasionally surfacing to stdout:
#   > "Error opening ETS file $HOME/.hex/cache.ets: :badfile"
restore :
	@printf "\033[36m~> mix deps.get\033[0m\n"
	@rm -f ~/.hex/cache.ets && mix deps.get

compile : restore
	@printf "\033[36m~> mix compile --warnings-as-errors\033[0m\n"
	@mix compile --warnings-as-errors

test-me:
	@read -p "~> " PARAMS; iex --dbg pry -S mix test --trace $$PARAMS

test : restore
	@printf "\033[36m~> mix test\033[0m\n"
	@mix test

format : restore
	@printf "\033[36m~> mix format\033[0m\n"
	@mix format

check-formatted : restore
	@printf "\033[36m~> mix format --check-formatted\033[0m\n"
	@mix format --check-formatted

lint : restore
	@printf "\033[36m~> mix credo --strict\033[0m\n"
	@mix credo --strict

build-plt : restore
	@printf "\033[36m~> mix dialyzer --plt\033[0m\n"
	@mix dialyzer --plt

dialyzer : restore
	@printf "\033[36m~> mix dialyzer --format github --format dialyxir\033[0m\n"
	@mix dialyzer --format github --format dialyxir

docs : restore
	@printf "\033[36m~> mix docs\033[0m\n"
	@MIX_ENV=docs mix docs

clean:
	@printf "\033[36m~> mix docs\033[0m\n"
	@mix deps.clean --unlock --unused

# WARNING: Keep this task in sync with pr_validation.yml for parity
validate : check-formatted clean lint compile test build-plt dialyzer docs

.PHONY : compile test format lint validate restore docs build-plt dialyzer clean