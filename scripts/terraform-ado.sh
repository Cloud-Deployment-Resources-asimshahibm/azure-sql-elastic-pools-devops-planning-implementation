#!/usr/bin/env bash
set -euo pipefail

TF_ROOT="${TF_ROOT:-terraform/production}"

require_env() {
  local name
  for name in "$@"; do
    if [[ -z "${!name:-}" ]]; then
      printf 'Required environment variable is not set: %s\n' "$name" >&2
      exit 2
    fi
  done
}

backend_init() {
  require_env \
    AZURE_SUBSCRIPTION_ID AZURE_TENANT_ID \
    TFSTATE_RESOURCE_GROUP TFSTATE_STORAGE_ACCOUNT TFSTATE_CONTAINER TFSTATE_KEY

  terraform -chdir="$TF_ROOT" init \
    -input=false \
    -reconfigure \
    -backend-config="resource_group_name=${TFSTATE_RESOURCE_GROUP}" \
    -backend-config="storage_account_name=${TFSTATE_STORAGE_ACCOUNT}" \
    -backend-config="container_name=${TFSTATE_CONTAINER}" \
    -backend-config="key=${TFSTATE_KEY}" \
    -backend-config="subscription_id=${AZURE_SUBSCRIPTION_ID}" \
    -backend-config="tenant_id=${AZURE_TENANT_ID}" \
    -backend-config="use_oidc=true" \
    -backend-config="use_azuread_auth=true"
}

case "${1:-}" in
  init)
    backend_init
    ;;
  plan)
    require_env TF_VARS_FILE TFPLAN_PATH
    [[ -f "${TF_ROOT}/${TF_VARS_FILE}" ]] || {
      printf 'Approved variable file does not exist: %s/%s\n' "$TF_ROOT" "$TF_VARS_FILE" >&2
      exit 2
    }
    mkdir -p "$(dirname "$TFPLAN_PATH")"
    terraform -chdir="$TF_ROOT" plan \
      -input=false \
      -lock-timeout=5m \
      -parallelism=5 \
      -var-file="$TF_VARS_FILE" \
      -out="$TFPLAN_PATH"
    ;;
  apply)
    require_env TFPLAN_PATH
    [[ -f "$TFPLAN_PATH" ]] || {
      printf 'Reviewed plan artifact does not exist: %s\n' "$TFPLAN_PATH" >&2
      exit 2
    }
    terraform -chdir="$TF_ROOT" apply \
      -input=false \
      -lock-timeout=5m \
      -parallelism=5 \
      "$TFPLAN_PATH"
    ;;
  *)
    printf 'Usage: %s {init|plan|apply}\n' "$0" >&2
    exit 2
    ;;
esac
