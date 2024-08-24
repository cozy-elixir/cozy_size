defmodule CozySize.SI do
  @moduledoc """
  Provides utilities for the SI-prefixed units.
  """

  import CozySize.Helper, only: [exponent: 2, maybe_to_integer: 1]

  @base 1000
  @unit_prefix [nil, :k, :M, :G, :T, :P, :E, :Z, :Y, :R, :Q]

  @exponent_limit length(@unit_prefix) - 1

  @table_bit_units @unit_prefix
                   |> Enum.with_index()
                   |> Enum.map(fn {prefix, index} ->
                     {:"#{prefix}b",
                      %{
                        to_bits: @base ** index,
                        to_bytes: @base ** index / 8
                      }}
                   end)

  @table_byte_units @unit_prefix
                    |> Enum.with_index()
                    |> Enum.map(fn {prefix, index} ->
                      {:"#{prefix}B",
                       %{
                         to_bits: 8 * @base ** index,
                         to_bytes: @base ** index
                       }}
                    end)

  @table_units []
               |> Keyword.merge(@table_bit_units)
               |> Keyword.merge(@table_byte_units)

  @map_units Enum.into(@table_units, %{})

  @bit_units Enum.map(@table_bit_units, &elem(&1, 0))
  @byte_units Enum.map(@table_byte_units, &elem(&1, 0))
  @units Enum.map(@table_units, &elem(&1, 0))

  # Generates @type unit :: :b | ... from the `@units` module attribute.
  @type unit ::
          unquote(
            Enum.reduce(
              Enum.reverse(@units),
              &quote(do: unquote(&1) | unquote(&2))
            )
          )

  @spec to_bits({number(), unit()}) :: CozySize.bits()
  def to_bits({n, unit}) when is_number(n) and unit in @units do
    ratio =
      @map_units
      |> Map.fetch!(unit)
      |> Map.fetch!(:to_bits)

    n * ratio
  end

  @spec to_bytes({number(), unit()}) :: CozySize.bits()
  def to_bytes({n, unit}) when is_number(n) and unit in @units do
    ratio =
      @map_units
      |> Map.fetch!(unit)
      |> Map.fetch!(:to_bytes)

    n * ratio
  end

  @spec from_bits(CozySize.bits(), CozySize.from_opts()) :: {number(), unit()}
  def from_bits(n, opts \\ []) when is_number(n) do
    as = Keyword.get(opts, :as, :bytes)
    precision = Keyword.get(opts, :precision, 2)

    {n, units} =
      case as do
        :bits -> {n, @bit_units}
        :bytes -> {n / 8, @byte_units}
      end

    exponent = exponent(n, @base) |> min(@exponent_limit) |> max(0)
    unit = Enum.at(units, exponent)

    n =
      (n / :math.pow(@base, exponent))
      |> Float.round(precision)
      |> maybe_to_integer()

    {n, unit}
  end

  @spec from_bytes(CozySize.bytes(), CozySize.from_opts()) :: {number(), unit()}
  def from_bytes(n, opts \\ []) when is_number(n) do
    as = Keyword.get(opts, :as, :bytes)
    precision = Keyword.get(opts, :precision, 2)

    {n, units} =
      case as do
        :bits -> {n * 8, @bit_units}
        :bytes -> {n, @byte_units}
      end

    exponent = exponent(n, @base) |> min(@exponent_limit) |> max(0)
    unit = Enum.at(units, exponent)

    n =
      (n / :math.pow(@base, exponent))
      |> Float.round(precision)
      |> maybe_to_integer()

    {n, unit}
  end
end
