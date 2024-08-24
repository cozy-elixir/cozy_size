defmodule CozySize.IEC do
  @moduledoc """
  Provides utilities for sizes using IEC-prefixed units.
  """

  import CozySize.Helper, only: [exponent: 2, maybe_to_integer: 1]

  @base 2 ** 10
  @unit_prefix [nil, :Ki, :Mi, :Gi, :Ti, :Pi, :Ei, :Zi, :Yi]

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

      iex> CozySize.IEC.to_bits({1, :b})
      1

      iex> CozySize.IEC.to_bits({1, :Kib})
      1024

      iex> CozySize.IEC.to_bits({1.1, :Kib})
      1126.4

      iex> CozySize.IEC.to_bits({1, :B})
      8

      iex> CozySize.IEC.to_bits({1, :KiB})
      8192

      iex> CozySize.IEC.to_bits({1.1, :KiB})
      9011.2

  """
  @spec to_bits({number(), unit()}) :: CozySize.bits()
  def to_bits({n, unit} = _tuple) when is_number(n) and unit in @units do
    ratio =
      @map_units
      |> Map.fetch!(unit)
      |> Map.fetch!(:to_bits)

    maybe_to_integer(n * ratio)
  end

  @doc """
  Converts a `{n, unit}` tuple to a number of bytes.

  ## Examples

      iex> CozySize.IEC.to_bytes({1, :b})
      0.125

      iex> CozySize.IEC.to_bytes({1, :Kib})
      128

      iex> CozySize.IEC.to_bytes({1.1, :Kib})
      140.8

      iex> CozySize.IEC.to_bytes({1, :B})
      1

      iex> CozySize.IEC.to_bytes({1, :KiB})
      1024

      iex> CozySize.IEC.to_bytes({1.1, :KiB})
      1126.4

  """
  @spec to_bytes({number(), unit()}) :: CozySize.bits()
  def to_bytes({n, unit} = _tuple) when is_number(n) and unit in @units do
    ratio =
      @map_units
      |> Map.fetch!(unit)
      |> Map.fetch!(:to_bytes)

    maybe_to_integer(n * ratio)
  end

  @doc """
  Converts a number of bits to a `{n, unit}` tuple.

  ## Examples

      iex> CozySize.IEC.from_bits(8, as: :bits)
      {8, :b}

      iex> CozySize.IEC.from_bits(8192, as: :bits)
      {8, :Kib}

      iex> CozySize.IEC.from_bits(2 ** 100, as: :bits)
      {1048576, :Yib}

      iex> CozySize.IEC.from_bits(1024 * 10 ** 11, as: :bits)
      {93.13, :Tib}

      iex> CozySize.IEC.from_bits(1024 * 10 ** 11, as: :bits, precision: 4)
      {93.1323, :Tib}

      iex> CozySize.IEC.from_bits(8, as: :bytes)
      {1, :B}

      iex> CozySize.IEC.from_bits(8192, as: :bytes)
      {1, :KiB}

      iex> CozySize.IEC.from_bits(2 ** 100, as: :bytes)
      {131072, :YiB}

      iex> CozySize.IEC.from_bits(1024 * 10 ** 11, as: :bytes)
      {11.64, :TiB}

      iex> CozySize.IEC.from_bits(1024 * 10 ** 11, as: :bytes, precision: 4)
      {11.6415, :TiB}

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

      iex> CozySize.IEC.from_bytes(8, as: :bits)
      {64, :b}

      iex> CozySize.IEC.from_bytes(8192, as: :bits)
      {64, :Kib}

      iex> CozySize.IEC.from_bytes(2 ** 100, as: :bits)
      {8388608, :Yib}

      iex> CozySize.IEC.from_bytes(1024 * 10 ** 11, as: :bits)
      {745.06, :Tib}

      iex> CozySize.IEC.from_bytes(1024 * 10 ** 11, as: :bits, precision: 4)
      {745.0581, :Tib}

      iex> CozySize.IEC.from_bytes(8, as: :bytes)
      {8, :B}

      iex> CozySize.IEC.from_bytes(8192, as: :bytes)
      {8, :KiB}

      iex> CozySize.IEC.from_bytes(2 ** 100, as: :bytes)
      {1048576, :YiB}

      iex> CozySize.IEC.from_bytes(1024 * 10 ** 11, as: :bytes)
      {93.13, :TiB}

      iex> CozySize.IEC.from_bytes(1024 * 10 ** 11, as: :bytes, precision: 4)
      {93.1323, :TiB}

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
