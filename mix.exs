defmodule ExEdst.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_edst,
      version: "0.1.0",
      elixir: "~> 1.7",
      elixirc_options: [
        warninngs_as_errors: true,
      ],
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
    ]
  end
end
