# Contributing guide

Contributions are more than welcome!

This document assumes that you already know how to use GitHub and Git.
If that's not the case, we recommend learning about it first [here](https://docs.github.com/en/get-started/quickstart/hello-world).

## Strict No LLM / No AI Policy

No LLMs for issues.

No LLMs for pull requests.

No LLMs for comments on issues/PRs, including translation. English is encouraged, but not required. You are welcome to post in your native language and rely on others to have their own translation tools of choice to interpret your words.

## First-time contributors

I label issues that I think should be easy for first-time contributors
with [`good-first-issue`](https://github.com/mrcjkb/neotest-haskell/issues?q=is%3Aissue%20state%3Aopen%20label%3A%22good%20first%20issue%22).

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
