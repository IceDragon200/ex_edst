defmodule EDST.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_edst,
      version: "0.4.0",
      description: description(),
      elixir: "~> 1.12",
      elixirc_options: [
        warninngs_as_errors: true,
      ],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      source_url: "https://github.com/IceDragon200/ex_edst",
      homepage_url: "https://github.com/IceDragon200/ex_edst",
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp description do
    """
    EDST Library for Elixir
    """
  end

  defp deps do
    [
    ]
  end

  defp package do
    [
      maintainers: ["Corey Powell"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/IceDragon200/ex_edst"
      },
    ]
  end
end
