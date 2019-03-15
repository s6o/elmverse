defmodule Elmverse.Release.Doc do
  @type t :: %__MODULE__{
          pub_name: String.t(),
          pkg_ver: String.t(),
          repo_id: pos_integer(),
          item_path: String.t(),
          item_index: non_neg_integer(),
          item_name: String.t(),
          item_comment: String.t() | nil,
          item_type: String.t() | nil,
          item_assoc: String.t() | nil,
          item_prec: String.t() | nil
        }

  defstruct [
    :pub_name,
    :pkg_ver,
    :repo_id,
    :item_path,
    :item_index,
    :item_name,
    :item_comment,
    :item_type,
    :item_assoc,
    :item_prec
  ]
end
