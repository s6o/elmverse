defmodule Elmverse.Package do
  @type t :: %__MODULE__{
          pub_name: String.t(),
          repo_id: pos_integer(),
          publisher: String.t(),
          pkg_name: String.t(),
          license: String.t(),
          summary: String.t()
        }

  defstruct [
    :pub_name,
    :repo_id,
    :publisher,
    :pkg_name,
    :license,
    :summary
  ]

  alias __MODULE__
  alias Sqlitex.Server, as: Db

  @spec from_map!(pos_integer(), map()) :: Package.t()
  def from_map!(repo_id, %{"license" => license, "name" => pub_name, "summary" => summary}) do
    [publisher | [pkg_name | _]] = String.split(pub_name, "/")

    %Package{
      pub_name: pub_name,
      repo_id: repo_id,
      publisher: publisher,
      pkg_name: pkg_name,
      license: license,
      summary: summary
    }
  end

  @spec save(Package.t()) :: {:ok, Package.t()} | [{:error, atom()}]
  def save(%Package{} = pkg) do
    query = """
      INSERT INTO package (pub_name, repo_id, publisher, pkg_name, license, summary)
        VALUES ($1, $2, $3, $4, $5, $6)
        ON CONFLICT (pub_name, repo_id) DO UPDATE SET
          license = $5, summary = $6
    """

    with {:ok, _} <-
           Db.query(:elmverse, query,
             bind: [
               pkg.pub_name,
               pkg.repo_id,
               pkg.publisher,
               pkg.pkg_name,
               pkg.license,
               pkg.summary
             ]
           ) do
      {:ok, pkg}
    end
  end
end
