#!/usr/bin/env bash

# NOTE: Script to easy import nix-build settings from env, useful for tooling env replication and the CI builds, relies on `default.nix` interface, which exposes Nixpkgs Haskell Lib interface

# The most strict error checking requirements
set -Eexuo pipefail

export compiler=${compiler:-'ghcjs'}
export rev=${rev:-'default'}

export packageRoot=${packageRoot:-'pkgs.nix-gitignore.gitignoreSource [ ] ./.'}
export cabalName=${cabalName:-'replace'}

export cachixAccount=${cachixAccount:-'replaceWithProjectNameInCachix'}
export CACHIX_SIGNING_KEY=${CACHIX_SIGNING_KEY:-""}

export allowInconsistentDependencies=${allowInconsistentDependencies:-'false'}
export doJailbreak=${doJailbreak:-'false'}
export doCheck=${doCheck:-'true'}

export sdistTarball=${sdistTarball:-'false'}
export buildFromSdist=${buildFromSdist:-'false'}

export failOnAllWarnings=${failOnAllWarnings:-'false'}
export buildStrictly=${buildStrictly:-'false'}

export enableDeadCodeElimination=${enableDeadCodeElimination:-'false'}
export disableOptimization=${disableOptimization:-'true'}
export linkWithGold=${linkWithGold:-'false'}

export enableLibraryProfiling=${enableLibraryProfiling:-'false'}
export enableExecutableProfiling=${enableExecutableProfiling:-'false'}
export doTracing=${doTracing:-'false'}
export enableDWARFDebugging=${enableDWARFDebugging:-'false'}
export doStrip=${doStrip:-'false'}

export enableSharedLibraries=${enableSharedLibraries:-'true'}
export enableStaticLibraries=${enableStaticLibraries:-'false'}
export enableSharedExecutables=${enableSharedExecutables:-'false'}
export justStaticExecutables=${justStaticExecutables:-'false'}
export enableSeparateBinOutput=${enableSeparateBinOutput:-'false'}

export checkUnusedPackages=${checkUnusedPackages:-'false'}
export doHaddock=${doHaddock:-'false'}
export doHyperlinkSource=${doHyperlinkSource:-'false'}
export doCoverage=${doCoverage:-'false'}
export doBenchmark=${doBenchmark:-'false'}
export generateOptparseApplicativeCompletions=${generateOptparseApplicativeCompletions:-'false'}
export executableNamesToShellComplete=${executableNamesToShellComplete:-'[ "replaceWithExecutableName" ]'}


export withHoogle=${withHoogle:-'false'}

# Log file to dump GHCJS build into
ghcjsTmpLogFile=${ghcjsTmpLogFile:-'/tmp/ghcjsTmpLogFile.log'}
# Length of the GHCJS log tail (<40000)
ghcjsLogTailLength=${ghcjsLogTailLength:-'10000'}


GHCJS_BUILD(){
# NOTE: Function for GHCJS build that outputs its huge log into a file

  # Run the build into Log (log is too long for Travis)
  "$@" &> "$ghcjsTmpLogFile"

}

SILENT(){
# NOTE: Function that silences the build process
# In normal mode outputs only the /nix/store paths

  echo "Log: $ghcjsTmpLogFile"
  # Pass into the ghcjsbuild function the build command
  if GHCJS_BUILD "$@"
  then

    # Output log lines for stdout -> cachix caching
    grep '^/nix/store/' "$ghcjsTmpLogFile"

  else

    # Output log lines for stdout -> cachix caching
    grep '^/nix/store/' "$ghcjsTmpLogFile"

    # Propagate the error state, fail the CI build
    exit 1

  fi

}

BUILD_PROJECT(){


IFS=$'\n\t'

if [ "$compiler" = "ghcjs" ]
  then

    # GHCJS build
    # By itself, GHCJS creates >65000 lines of log that are >4MB in size, so Travis terminates due to log size quota.
    # nixbuild --quiet (x5) does not work on GHC JS build
    # So there was a need to make it build.
    # The solution is to silence the stdout
    # But Travis then terminates on 10 min no stdout timeout
    # so HACK: SILENT wrapper allows to surpress the huge log, while still preserves the Cachix caching ability in any case of the build
    # On build failure outputs the last 10000 lines of log (that should be more then enough), and terminates
    SILENT ./ghcjs-build.sh

fi
}

MAIN() {


# Overall it is useful to have in CI test builds the latest stable Nix
(nix-channel --update && nix-env -u) || (sudo nix upgrade-nix) || true


# Report the Nixpkgs channel revision
nix-instantiate --eval -E 'with import <nixpkgs> {}; lib.version or lib.nixpkgsVersion'


# Secrets are not shared to PRs from forks
# nix-build | cachix push <account> - uploads binaries, runs&works only in the branches of the main repository, so for PRs - else case runs

  if [ ! "$CACHIX_SIGNING_KEY" = "" ]

    then

      # Build of the inside repo branch - enable push Cachix cache
      BUILD_PROJECT | cachix push "$cachixAccount"

    else

      # Build of the side repo/PR - can not push Cachix cache
      BUILD_PROJECT

  fi

}

# Run the entry function of the script
MAIN
