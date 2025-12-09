#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${USERNAME}" ]]; then
  echo "ERROR: USERNAME is required. Set docker username in USERNAME env var." >&2
  exit 2
fi

image="docker.io/${USERNAME}/subscription-api:latest"

script_dir="$(cd "$(dirname "$0")" && pwd)"
context_dir="${script_dir%/scripts}"

echo "Building image: ${image}"
docker build -t "${image}" -f "${context_dir}/Dockerfile" "${context_dir}"

echo "Pushing image: ${image}"
docker push "${image}"

echo "Done."

