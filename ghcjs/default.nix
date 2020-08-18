{ rpRef ? "df0bdcca5eb2a3236ec0496e4430d91876b29cf5" }:

let rp = builtins.fetchTarball "https://github.com/reflex-frp/reflex-platform/archive/${rpRef}.tar.gz";

in
  (import rp {}).project ({ pkgs, ... }:
  {
    name = "replaceWithPackageName";
    overrides = pkgs.lib.foldr pkgs.lib.composeExtensions (_: _: {})
                [
                ];
    packages = {
      hnix = ../.;
    };

    shells = {
      ghcjs = [ "hnix" ];
    };

  })
