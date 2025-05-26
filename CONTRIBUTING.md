# Contributing guide

Contributions are more than welcome!

Please don't forget to add your changes to the "Unreleased" section of [the changelog](./CHANGELOG.md)
(if applicable).

## Commit messages

This project uses [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).
Please make sure your commits/PR titles have appropriate prefixes
and scopes.

## Development

I use

- [`nix`](https://nixos.org/download.html#download-nix) for development and testing.
- [`stylua`](https://github.com/JohnnyMorganz/StyLua).
  [`.editorconfig`](https://editorconfig.org/),
  and [`alejandra`](https://github.com/kamadorueda/alejandra)
  for formatting.
- [`luacheck`](https://github.com/mpeterv/luacheck),
  and [`markdownlint`](https://github.com/DavidAnson/markdownlint),
  for linting.

You don't need to use Nix, but I recommend it if you want to
easily reproduce CI.

To enter a development shell:

```console
nix-shell
```

or (with flakes enabled)

```console
nix develop
```

To apply formatting, while in a devShell, run

```console
pre-commit run --all
```

If you use [`direnv`](https://direnv.net/),
just run `direnv allow` and you will be dropped in this devShell.

## Tests

To run tests locally

```console
nix-build -A ci
```

Or (with flakes enabled)

```console
nix build .#checks.<your-system>.ci --print-build-logs
```

For formatting:

```console
nix-build -A formatting
```

Or (with flakes enabled)

```console
nix build .#checks.<your-system>.formatting --print-build-logs
```

If you have flakes enabled and just want to run all checks that are available, run:

```console
nix flake check --print-build-logs
```

## Type safety

Lua is incredibly responsive, giving immediate feedback for configuration.
But its dynamic typing makes Neovim plugins susceptible to unexpected bugs
at the wrong time.
To mitigate this, I rely on [LuaCATS annotations](https://luals.github.io/wiki/annotations/),
which are checked in CI.
