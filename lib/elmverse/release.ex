defmodule Elmverse.Release do
  @type t :: %__MODULE__{
          repo_id: pos_integer(),
          pub_name: String.t(),
          pkg_ver: String.t(),
          released: pos_integer()
        }

  defstruct [
    :repo_id,
    :pub_name,
    :pkg_ver,
    :released
  ]

  alias __MODULE__
  alias Sqlitex.Server, as: Db
  alias Elmverse.Release.Dep
  alias Elmverse.Release.Doc
  alias Elmverse.Release.Readme

  defimpl Collectable, for: Elmverse.Release do
    def into(original) do
      collector_fn = fn s, cmd ->
        case cmd do
          {:cont, {key, value}} ->
            Map.put(s, key, value)

          :done ->
            s

          :halt ->
            :ok
        end
      end

      {original, collector_fn}
    end
  end

  @spec list(atom() | pid()) :: {:ok, [Release.t()]} | {:error, any()}
  def list(db \\ :elmverse) do
    query = "SELECT * FROM package_release ORDER BY repo_id, pub_name"

    with {:ok, results} <- Db.query(db, query, into: %Release{}) do
      {:ok, results}
    end
  end

  @spec fetch_deps(Release.t(), String.t(), String.t()) ::
          {:ok, [Dep.t()]}
          | {:error, HTTPoison.Error.t()}
          | {:error, Jason.DecodeError.t()}
          | {:error, String.t()}
  def fetch_deps(%Release{} = r, dep_url, dep_json) do
    req_url = dep_url <> "/" <> r.pub_name <> "/" <> r.pkg_ver <> "/" <> dep_json

    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <- HTTPoison.get(req_url),
         {:ok, json_deps} <- Jason.decode(body) do
      {:ok, to_release_dep(r, json_deps)}
    else
      {:ok, %HTTPoison.Response{} = r} ->
        {:error, "Unexpected HTTP response | #{inspect(r)}"}

      error ->
        error
    end
  end

  defp to_release_dep(%Release{} = r, %{"dependencies" => deps}) do
    deps
    |> Enum.map(fn {dep_pub, dep_guard} ->
      %Dep{
        repo_id: r.repo_id,
        pub_name: r.pub_name,
        pkg_ver: r.pkg_ver,
        dep_pub: dep_pub,
        dep_guard: dep_guard
      }
    end)
  end

  @spec fetch_docs(Release.t(), String.t()) ::
          {:ok, [Doc.t()]}
          | {:error, HTTPoison.Error.t()}
          | {:error, Jason.DecodeError.t()}
          | {:error, String.t()}
  def fetch_docs(%Release{} = r, meta_url) do
    req_url = meta_url <> "/" <> r.pub_name <> "/" <> r.pkg_ver <> "/docs.json"

    with {:ok, %HTTPoison.Response{status_code: 200, body: body}} <- HTTPoison.get(req_url),
         {:ok, json_docs} <- Jason.decode(body) do
      {:ok,
       json_docs
       |> Enum.map(fn item -> to_module_doc(r, item) end)
       |> Enum.reduce(%{}, fn m, acc -> Map.merge(acc, m) end)}
    else
      {:ok, %HTTPoison.Response{} = r} ->
        {:error, "Unexpected HTTP response | #{inspect(r)}"}

      error ->
        error
    end
  end

  defp to_module_doc(
         %Release{} = r,
         %{
           "name" => module_name,
           "comment" => module_comment,
           "aliases" => aliases,
           "binops" => binops,
           "unions" => unions,
           "values" => values
         }
       ) do
    %{
      "/#{module_name}" => %Doc{
        repo_id: r.repo_id,
        pub_name: r.pub_name,
        pkg_ver: r.pkg_ver,
        item_path: "/#{module_name}",
        item_index: 0,
        item_name: module_name,
        item_comment: module_comment
      }
    }
    |> to_module_alias(r, module_name, aliases)
    |> to_module_binop(r, module_name, binops)
    |> to_module_union(r, module_name, unions)
    |> to_module_value(r, module_name, values)
  end

  defp to_module_alias(doc_map, %Release{} = r, module_name, aliases) do
    aliases
    |> Enum.reduce(doc_map, fn %{"name" => name, "comment" => c, "type" => t, "args" => args},
                               acc ->
      arg_map = to_module_item_arg(acc, r, "/#{module_name}/aliases/#{name}", args)

      key = "/#{module_name}/aliases/#{name}"

      doc = %Doc{
        repo_id: r.repo_id,
        pub_name: r.pub_name,
        pkg_ver: r.pkg_ver,
        item_path: key,
        item_index: 0,
        item_name: name,
        item_comment: c,
        item_type: t
      }

      Map.merge(acc, arg_map)
      |> Map.put(key, doc)
    end)
  end

  defp to_module_binop(doc_map, %Release{} = r, module_name, binops) do
    binops
    |> Enum.reduce(doc_map, fn %{
                                 "name" => name,
                                 "comment" => c,
                                 "type" => t,
                                 "associativity" => assoc,
                                 "precedence" => prec
                               },
                               acc ->
      key = "/#{module_name}/binops/#{name}"

      doc = %Doc{
        repo_id: r.repo_id,
        pub_name: r.pub_name,
        pkg_ver: r.pkg_ver,
        item_path: key,
        item_index: 0,
        item_name: name,
        item_comment: c,
        item_type: t,
        item_assoc: assoc,
        item_prec: prec
      }

      Map.put(acc, key, doc)
    end)
  end

  defp to_module_union(doc_map, %Release{} = r, module_name, unions) do
    unions
    |> Enum.reduce(doc_map, fn %{"name" => name, "comment" => c, "args" => args, "cases" => cases},
                               acc ->
      arg_map = to_module_item_arg(acc, r, "/#{module_name}/unions/#{name}", args)

      case_map =
        cases
        |> Enum.reduce(acc, fn [cs | [cs_args | _]], a ->
          cs_arg_map =
            to_module_item_arg(a, r, "/#{module_name}/unions/#{name}/cases/#{cs}", cs_args)

          k = "/#{module_name}/unions/#{name}/cases/#{cs}"

          d = %Doc{
            repo_id: r.repo_id,
            pub_name: r.pub_name,
            pkg_ver: r.pkg_ver,
            item_path: k,
            item_index: 0,
            item_name: cs
          }

          Map.merge(a, cs_arg_map)
          |> Map.put(k, d)
        end)

      key = "/#{module_name}/unions/#{name}"

      doc = %Doc{
        repo_id: r.repo_id,
        pub_name: r.pub_name,
        pkg_ver: r.pkg_ver,
        item_path: key,
        item_index: 0,
        item_name: name,
        item_comment: c
      }

      Map.merge(acc, arg_map)
      |> Map.merge(case_map)
      |> Map.put(key, doc)
    end)
  end

  defp to_module_value(doc_map, %Release{} = r, module_name, values) do
    values
    |> Enum.reduce(doc_map, fn %{"name" => name, "comment" => c, "type" => t}, acc ->
      key = "/#{module_name}/values/#{name}"

      doc = %Doc{
        repo_id: r.repo_id,
        pub_name: r.pub_name,
        pkg_ver: r.pkg_ver,
        item_path: key,
        item_index: 0,
        item_name: name,
        item_comment: c,
        item_type: t
      }

      Map.put(acc, key, doc)
    end)
  end

  defp to_module_item_arg(doc_map, %Release{} = r, parent_path, args) do
    args
    |> Enum.reduce(doc_map, fn arg, acc ->
      k = "#{parent_path}/args/#{arg}"

      d = %Doc{
        repo_id: r.repo_id,
        pub_name: r.pub_name,
        pkg_ver: r.pkg_ver,
        item_path: k,
        item_index: 0,
        item_name: arg
      }

      Map.put(acc, k, d)
    end)
  end

  @spec fetch_readme(Release.t(), String.t()) ::
          {:ok, [Readme.t()]}
          | {:error, HTTPoison.Error.t()}
          | {:error, String.t()}
  def fetch_readme(%Release{} = r, meta_url) do
    req_url = meta_url <> "/" <> r.pub_name <> "/" <> r.pkg_ver <> "/README.md"

    with {:ok, %HTTPoison.Response{status_code: 200, body: readme}} <- HTTPoison.get(req_url) do
      {:ok,
       %Readme{
         repo_id: r.repo_id,
         pub_name: r.pub_name,
         pkg_ver: r.pkg_ver,
         readme: readme
       }}
    else
      {:ok, %HTTPoison.Response{} = r} ->
        {:error, "Unexpected HTTP response | #{inspect(r)}"}

      error ->
        error
    end
  end

  @spec save(Release.t(), atom() | pid()) :: {:ok, Release.t()} | [{:error, atom()}]
  def save(%Release{} = r, db \\ :elmverse) do
    query = """
      INSERT INTO package_release (repo_id, pub_name, pkg_ver, released)
        VALUES ($1, $2, $3, $4)
    """

    with {:ok, _} <-
           Db.query(db, query,
             bind: [
               r.repo_id,
               r.pub_name,
               r.pkg_ver,
               r.released
             ]
           ) do
      {:ok, r}
    end
  end
end
