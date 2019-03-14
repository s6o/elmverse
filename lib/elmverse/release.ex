defmodule Elmverse.Release do
  @type t :: %__MODULE__{
          pub_name: String.t(),
          pkg_ver: String.t(),
          released: pos_integer(),
          repo_id: pos_integer()
        }

  defstruct [
    :pub_name,
    :pkg_ver,
    :released,
    :repo_id
  ]
end
