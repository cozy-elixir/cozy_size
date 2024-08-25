defmodule CozySize.SI do
  @moduledoc """
  Provides utilities for sizes using SI-prefixed units.
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

  @doc """
  Converts a `{n, unit}` tuple to a number of bits.

  ## Examples

      iex> CozySize.SI.to_bits({0, :b})
      0

      iex> CozySize.SI.to_bits({1, :b})
      1

      iex> CozySize.SI.to_bits({1, :kb})
      1000

      iex> CozySize.SI.to_bits({1.1, :kb})
      1100

      iex> CozySize.SI.to_bits({0, :B})
      0

      iex> CozySize.SI.to_bits({1, :B})
      8

      iex> CozySize.SI.to_bits({1, :kB})
      8000

      iex> CozySize.SI.to_bits({1.1, :kB})
      8800

  """
  @spec to_bits({number(), unit()}) :: CozySize.bits()
  def to_bits({n, unit} = _tuple) when is_number(n) and unit in @units do
    factor =
      @map_units
      |> Map.fetch!(unit)
      |> Map.fetch!(:to_bits)

    maybe_to_integer(n * factor)
  end

  @doc """
  Converts a `{n, unit}` tuple to a number of bytes.

  ## Examples

      iex> CozySize.SI.to_bytes({0, :b})
      0

      iex> CozySize.SI.to_bytes({1, :b})
      0.125

      iex> CozySize.SI.to_bytes({1, :kb})
      125

      iex> CozySize.SI.to_bytes({1.1, :kb})
      137.5

      iex> CozySize.SI.to_bytes({0, :B})
      0

      iex> CozySize.SI.to_bytes({1, :B})
      1

      iex> CozySize.SI.to_bytes({1, :kB})
      1000

      iex> CozySize.SI.to_bytes({1.1, :kB})
      1100

  """
  @spec to_bytes({number(), unit()}) :: CozySize.bits()
  def to_bytes({n, unit} = _tuple) when is_number(n) and unit in @units do
    factor =
      @map_units
      |> Map.fetch!(unit)
      |> Map.fetch!(:to_bytes)

    maybe_to_integer(n * factor)
  end

  @doc """
  Converts a number of bits to a `{n, unit}` tuple.

  ## Examples

      iex> CozySize.SI.from_bits(0, as: :bits)
      {0, :b}

      iex> CozySize.SI.from_bits(8, as: :bits)
      {8, :b}

      iex> CozySize.SI.from_bits(8192, as: :bits)
      {8.19, :kb}

      iex> CozySize.SI.from_bits(2 ** 120, as: :bits)
      {1329228, :Qb}

      iex> CozySize.SI.from_bits(1024 * 10 ** 11, as: :bits)
      {102.4, :Tb}

      iex> CozySize.SI.from_bits(1024 * 10 ** 11, as: :bits, precision: 4)
      {102.4, :Tb}

      iex> CozySize.SI.from_bits(0, as: :bytes)
      {0, :B}

      iex> CozySize.SI.from_bits(8, as: :bytes)
      {1, :B}

      iex> CozySize.SI.from_bits(8192, as: :bytes)
      {1.02, :kB}

      iex> CozySize.SI.from_bits(2 ** 120, as: :bytes)
      {166153.5, :QB}

      iex> CozySize.SI.from_bits(1024 * 10 ** 11, as: :bytes)
      {12.8, :TB}

      iex> CozySize.SI.from_bits(1024 * 10 ** 11, as: :bytes, precision: 4)
      {12.8, :TB}

  """
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

  @doc """
  Converts a number of bytes to a `{n, unit}` tuple.

  ## Examples

      iex> CozySize.SI.from_bytes(0, as: :bits)
      {0, :b}

      iex> CozySize.SI.from_bytes(8, as: :bits)
      {64, :b}

      iex> CozySize.SI.from_bytes(8192, as: :bits)
      {65.54, :kb}

      iex> CozySize.SI.from_bytes(2 ** 120, as: :bits)
      {10633823.97, :Qb}

      iex> CozySize.SI.from_bytes(1024 * 10 ** 11, as: :bits)
      {819.2, :Tb}

      iex> CozySize.SI.from_bytes(1024 * 10 ** 11, as: :bits, precision: 4)
      {819.2, :Tb}

      iex> CozySize.SI.from_bytes(0, as: :bytes)
      {0, :B}

      iex> CozySize.SI.from_bytes(8, as: :bytes)
      {8, :B}

      iex> CozySize.SI.from_bytes(8192, as: :bytes)
      {8.19, :kB}

      iex> CozySize.SI.from_bytes(2 ** 120, as: :bytes)
      {1329228, :QB}

      iex> CozySize.SI.from_bytes(1024 * 10 ** 11, as: :bytes)
      {102.4, :TB}

      iex> CozySize.SI.from_bytes(1024 * 10 ** 11, as: :bytes, precision: 4)
      {102.4, :TB}

  """
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
