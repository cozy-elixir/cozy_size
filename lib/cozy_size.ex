defmodule CozySize do
  @moduledoc """
  Provides utilities for sizes.

  Currently, there're three existing standards for prefixing units of sizes:

    * SI (decimal-based)
    * IEC (binary-based)
    * JEDEC (binary-based)

  > Read more about them at <https://en.wikipedia.org/wiki/Binary_prefix>.

  `CozySize` provides support for them via:

    * `CozySize.SI`
    * `CozySize.IEC`
    * `CozySize.JEDEC`

  ## Usage

      iex> # get bytes by following IEC standard
      iex> bytes = CozySize.IEC.to_bytes({1024, :MiB})
      iex> # get a humanized tuple by following IEC standard
      iex> CozySize.IEC.from_bytes(bytes)
      {1, :GiB}
      iex> # get a humanized tuple by following SI standard
      iex> CozySize.SI.from_bytes(bytes)
      {1.07, :GB}
      iex> # get a humanized tuple by following JEDEC standard
      iex> CozySize.JEDEC.from_bytes(bytes)
      {1, :GB}

  If you want to operate on bits, please check the `*_bits` functions in each
  module, which will not be further elaborated here.

  ## Note

  I know there are many repetitive parts in the code, but I don't plan to
  abstract them. The abstracted code might not be as easy to understand,
  so I intend to leave them as they are.

  """

  @type bits :: number()
  @type bytes :: number()

  @type from_opt :: {:as, :bits | :bytes} | {:precision, pos_integer()}
  @type from_opts :: [from_opt()]
end
