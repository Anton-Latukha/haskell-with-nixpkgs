#!/usr/bin/env bash

# Overall it is useful to have in CI test builds the latest stable Nix
# 2020-06-24: HACK: Do not ask why different commands on Linux and macOS. IDK, wished they we the same. These are the only commands that worked on according platforms right after the fresh Nix installer rollout.
# 2020-07-06: HACK: GitHub Actions CI shown that nix-channel or nix-upgrade-nix do not work, there is probably some new rollout, shortcircuting for the time bing with || true
(nix-channel --update && nix-env -u) || (sudo nix upgrade-nix) || true


# Report the Nixpkgs channel revision
nix-instantiate --eval -E 'with import <nixpkgs> {}; lib.version or lib.nixpkgsVersion'
