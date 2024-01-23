#!/usr/bin/env bash
set -eo pipefail
[[ $RUNNER_DEBUG || $DEBUG ]] && set -x

set +e
release_info="$(gh api /repos/:owner/:repo/releases/latest)"
rc=$?; set -e

if [[ $rc != 0 ]]; then
  error_message="$(jq -r .message <<< "$release_info")"
  if [[ $error_message == "Not Found" ]]; then
    >&2 echo "No state file found, exiting"
    exit 0
  else
    >&2 echo "Other error occurred while trying to obtain the state file:"
    >&2 echo "$error_message"
    exit 1
  fi
fi

state_file_url="$(jq -r '.assets[] | select(.name == "terraform.tfstate.gpg") | .url' <<< "$release_info")"
release_name="$(jq -r '.name' <<< "$release_info")"
echo "Found release: $release_name"
gh api -H 'Accept: application/octet-stream' "$state_file_url" | gpg --out terraform.tfstate --decrypt

echo "Decrypted state file:"
jq -r '.outputs = "<redacted>" | .resources = "<redacted>"' < terraform.tfstate


