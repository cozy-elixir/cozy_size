defmodule CozySize do
  @moduledoc """
  Provides utilities for sizes.

  Read more at:

    * https://en.wikipedia.org/wiki/Binary_prefix

  """

  @type bits :: number()
  @type bytes :: number()

  @type from_opt :: {:as, :bits | :bytes} | {:precision, integer()}
  @type from_opts :: [from_opt()]
end
