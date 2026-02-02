#!/usr/bin/env bash
set -euo pipefail

# Triggers an Ansible Galaxy import for the calling repository.
#
# Inputs (env vars):
#   GALAXY_API_TOKEN  (required)
#   GITHUB_USER       (default: moltimersmith)
#   GITHUB_REPO       (required)
#   INPUT_REF         (optional; if set, import this ref)
#
# Behavior:
#   - If INPUT_REF is set, import that ref.
#   - Else, determine latest git tag in the calling repo; if none, use "main".

: "${GITHUB_USER:=moltimersmith}"

if [[ -z "${GALAXY_API_TOKEN:-}" ]]; then
  echo "GALAXY_API_TOKEN is not set" >&2
  exit 1
fi

if [[ -z "${GITHUB_REPO:-}" ]]; then
  echo "GITHUB_REPO is not set" >&2
  exit 1
fi

REF="${INPUT_REF:-}"

if [[ -z "${REF}" ]]; then
  # Determine the latest tag in the calling repo (the workflow runs in the caller repo context).
  git init -q
  git remote add origin "https://github.com/${GITHUB_REPOSITORY}.git"
  git fetch --tags -q origin
  REF=$(git tag --sort=-v:refname | head -n 1 || true)
  if [[ -z "${REF}" ]]; then
    REF="main"
  fi
fi

echo "Triggering Galaxy import for ${GITHUB_USER}/${GITHUB_REPO} ref=${REF}"

curl -fsS -X POST "https://galaxy.ansible.com/api/v1/imports/" \
  -H "Content-Type: application/json" \
  -H "Authorization: Token ${GALAXY_API_TOKEN}" \
  -d "{\"github_user\":\"${GITHUB_USER}\",\"github_repo\":\"${GITHUB_REPO}\",\"github_reference\":\"${REF}\"}"
