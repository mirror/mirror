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

# Generate the state file encryption key
gpg --yes --batch --passphrase '' --quick-gen-key "$app_username <$app_email>" default default
gpg --yes --output "${repo_name}.gpg" --armor --export-secret-key "$app_email"

# Add the encryption key as a repo secret, save it in 1PW
gh secret set TF_TFSTATE_PGP_KEY --repo "$repo_owner/$repo_name" < "${repo_name}.gpg"
op document create "${repo_name}.gpg" --title "TF state file PGP enc key - $repo_name" --vault mirror --account my

# Add the app info as repo variables
gh variable set GH_APP_APP_ID --body "$app_id" --repo "$repo_owner/$repo_name"
gh variable set GH_APP_BOT_EMAIL --body "$app_email" --repo "$repo_owner/$repo_name"
gh variable set GH_APP_BOT_USERNAME --body "$app_username" --repo "$repo_owner/$repo_name"

# Add the app private key as a repo secret, save it in 1PW
gh secret set GH_APP_PRIVATE_KEY --repo "$repo_owner/$repo_name" < "${app_slug}.private-key.pem"
op document create "${app_slug}.private-key.pem" --title "GitHub App PK - $app_slug" --vault mirror --account my
op item edit "GitHub App PK - $app_slug" "app id[text]=$app_id" --vault mirror --account my

