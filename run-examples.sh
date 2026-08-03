#!/usr/bin/env bash
# Run all plclib-cl examples
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Loading plclib-cl and running all examples..."
sbcl --non-interactive \
  --eval "(push #p\"${SCRIPT_DIR}/\" asdf:*central-registry*)" \
  --eval '(asdf:load-system :plclib-cl)' \
  --eval '(plclib-cl:run-all-examples)'