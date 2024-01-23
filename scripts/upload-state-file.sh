#!/usr/bin/env bash
set -eo pipefail
[[ $RUNNER_DEBUG || $DEBUG ]] && set -x

gpg --encrypt --default-recipient "141457414+steeleco-systems[bot]@users.noreply.github.com" --output terraform.tfstate.gpg terraform.tfstate
