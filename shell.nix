# Get CLI attrs, import `default.nix` with those attrs, load its `env`
attrs@{ ... }: (import ./. attrs).env