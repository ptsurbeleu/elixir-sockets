defmodule Socket.MixProject do
  use Mix.Project

  def project do
    [
      app: :sockets,
      elixir: "~> 1.12",
      version: "2.1.4",
      deps: deps(),
      package: package(),
      description: "Socket handling library for Elixir, updated for OTP20+"
    ]
  end

  # Configuration for the OTP application
  def application do
    [extra_applications: [:crypto, :ssl, :logger]]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.30", only: [:dev, :docs], runtime: false},
      {:credo, "~> 1.7", only: [:dev]},
      {:dialyxir, github: "jeremyjh/dialyxir", only: [:dev, :test], runtime: false},
      {:version_tasks, "~> 0.12.0", only: [:dev], runtime: false}
    ]
  end

  defp package do
    [
      name: :sockets,
      maintainers: ["ptsurbeleu"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/ptsurbeleu/elixir-sockets"}
    ]
  end
end
