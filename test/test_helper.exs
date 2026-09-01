# NOTE: This is needed to keep ElixirLS alive and not crashing all the time
# whenever IDE attempts to render documentation for a PropCheck member/function.
Application.put_env(:propcheck, :counter_examples, Path.expand("./_build/propcheck.ctex"))

ExUnit.start()
