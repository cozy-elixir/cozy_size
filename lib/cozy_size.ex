defmodule CozySize do
  @moduledoc """
  Provides utilities for sizes.

  Currently, there're three existing standards for prefixing
  units of sizes:

    * SI
    * IEC
    * JEDEC

  > Read more about them at <https://en.wikipedia.org/wiki/Binary_prefix>.

  `CozySize` provides support for them via:

    * `CozySize.SI`
    * `CozySize.IEC`
    * `CozySize.JEDEC`

  """

  @type bits :: number()
  @type bytes :: number()

  @type from_opt :: {:as, :bits | :bytes} | {:precision, integer()}
  @type from_opts :: [from_opt()]
end
