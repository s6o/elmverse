defmodule Elmverse.Release.Doc do
  @type t :: %__MODULE__{
          repo_id: pos_integer(),
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

  alias __MODULE__
  alias Sqlitex.Server, as: Db

  @spec save(Doc.t(), atom() | pid()) :: {:ok, Doc.t()} | [{:error, atom()}]
  def save(%Doc{} = d, db \\ :elmverse) do
    query = """
      INSERT INTO release_doc (repo_id, pub_name, pkg_ver,
      item_path, item_name, item_comment, item_type, item_assoc, item_prec)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
    """

    with {:ok, _} <-
           Db.query(db, query,
             bind: [
               d.repo_id,
               d.pub_name,
               d.pkg_ver,
               d.item_path,
               d.item_name,
               d.item_comment,
               d.item_type,
               d.item_assoc,
               d.item_prec
             ]
           ) do
      {:ok, d}
    end
  end
end
