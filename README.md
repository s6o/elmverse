# Elmverse [WIP]

Elm package discovery, documentation and statistics.

## Planned Features

* Better UX e.g. [php.net](http://php.net.manual/en) [hexdocs](https://hexdocs.pm)
* Package discovery: latest new, updated, GitHub stars
* Aggregate into an SQLite database, provide offline/local option

## How it will work

* Regulary look up packages from [https://package.elm-lang.org/search.json](https://package.elm-lang.org/search.json)

Each packages is represented as

```text
  [
    {
      name: <publisher>/<package-name>,
      license: <license>,
      summary: <summary>,
      versions: [<version>]
    }
  ]
```

For each (new) package (version) in the returned JSON array fetch package documentation from
[https://package.elm-lang.org](https://package.elm-lang.org) path

* /packages/<publisher>/<package-name>/README.md

Result: GitHub Markdown

* /packages/<publisher>/<package-name>/releases.json

Result: JSON object where every key is a version and value a unix epoch in seconds, e.g.

```JSON
  {
      "1.0.0": 1492269856,
      "1.0.1": 1542143995
  }
```

* /packages/<publisher>/<package-name>/docs.json

Result a JSON array of module documentation.

```text
  [
    {
      name: <module-name>,
      comment: <module-markdown-doc-order>,
      unions: [
        {
          name: <union-name>,
          comment: <markdown>,
          args: [ <arg> ],
          cases: [
            [ <name>,[] ],
            [ <name>,[] ]
          ]
        }
      ],
      aliases: [
        {
          name: <name>,
          comment: <markdown>,
          args: [ <arg> ],
          type: <type-signature>
        }
      ],
      values: [
        {
          name: <value-name>,
          comment: <markdown>,
          type: <type-signature>
        }
      ],
      binops: [
        {
          name: <name>,
          comment: <markdown>,
          type: <type-signature>,
          associativity: <right-left>,
          precedence: <int>
        }
      ]
    }
  ]
```

## Development

To start your Phoenix server:

* Install dependencies with `mix deps.get`
* Install Node.js dependencies with `cd assets && npm install`
* Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
