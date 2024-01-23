#!/usr/bin/env bash
set -x

# Set up the data
repo_info="$(gh repo view --json name,owner | jq -r '{name: .name, owner: .owner.login}')"
repo_owner="$(jq -r '.owner' <<< "$repo_info")"
repo_name="$(jq -r '.name' <<< "$repo_info")"
#app_slug="${repo_owner,,}-${repo_name}"
app_slug="${repo_owner,,}-tf"
app_username="${app_slug}[bot]"
app_user_id="$(gh api "/users/$app_username" | jq -r .id)"
app_id="$(gh api "/apps/$app_slug" | jq -r .id)"
app_email="${app_user_id}+${app_username}@users.noreply.github.com"
app_slug_upper="${app_slug^^}"
var_name="${app_slug_upper//-/_}"

# Delete the GPG key
fingerprint="$(gpg --fingerprint "$app_email" | sed -n '/^\s/s/\s*//p')"
gpg --batch --yes --delete-secret-and-public-keys "$fingerprint"
rm "${repo_name}.gpg"

# Delete the repo secret holding the encryption key, remove it from 1PW
gh secret delete TF_TFSTATE_PGP_KEY --repo "$repo_owner/$repo_name"
op item delete "TF state file PGP enc key - $repo_name" --vault mirror --account my

# Delete the repo variables holding the app info
gh variable delete GH_APP_APP_ID --repo "$repo_owner/$repo_name"
gh variable delete GH_APP_BOT_EMAIL --repo "$repo_owner/$repo_name"
gh variable delete GH_APP_BOT_USERNAME --repo "$repo_owner/$repo_name"

# Delete the repo variable and 1PW item holding the app private key
gh secret delete GH_APP_PRIVATE_KEY --repo "$repo_owner/$repo_name"
op item delete "GitHub App PK - $app_slug" --vault mirror --account my
