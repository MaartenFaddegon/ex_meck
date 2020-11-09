defmodule ExMeck.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_meck,
      version: "0.3.1",
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: []
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [ 
      {:meck, "~> 0.9.0"},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      {:gen_state_machine, "~> 2.0", only: :test},
      {:propcheck, "~> 1.0", only: :test}
    ]
  end

  defp description() do
    "A mocking library particularly suitable for stateful property based testing."
  end

  defp package do
    [
      name: "ex_meck",
      files: ["lib/ex_meck.ex", "mix.exs"],
      maintainers: ["Maarten Faddegon"],
      licenses: ["MIT License"],
      links: %{"GitHub" => "https://github.com/MaartenFaddegon/ex_meck"}
    ]
  end
end
