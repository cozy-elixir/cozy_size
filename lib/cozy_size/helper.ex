defmodule CozySize.Helper do
  @moduledoc false

  @doc false
  def maybe_to_integer(n) when is_number(n) do
    rounded_n = round(n)
    if rounded_n == n, do: rounded_n, else: n
  end

  @doc false
  def exponent(0, _base), do: 0
  def exponent(+0.0, _base), do: 0
  def exponent(-0.0, _base), do: 0

  def exponent(n, base) do
    (:math.log(abs(n)) / :math.log(base))
    |> Float.floor()
    |> round()
  end
end
