defmodule Elmverse.Release.Doc do
  @type t :: %__MODULE__{
          repo_id: pos_integer(),
          rel_id: pos_integer(),
          pub_name: String.t(),
          pkg_ver: String.t(),
          item_path: String.t(),
          item_index: non_neg_integer(),
          item_name: String.t(),
          item_comment: String.t() | nil,
          item_type: String.t() | nil,
          item_assoc: String.t() | nil,
          item_prec: String.t() | nil
        }

  defstruct [
    :repo_id,
    :rel_id,
    :pub_name,
    :pkg_ver,
    :item_path,
    :item_index,
    :item_name,
    :item_comment,
    :item_type,
    :item_assoc,
    :item_prec
  ]
end
