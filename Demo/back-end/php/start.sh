#!/bin/bash
# DSPay mock merchant (PHP) — foreground start script

set -eu

ROOT="$(cd "$(dirname "$0")" && pwd)"

prompt_required() {
    local name="$1" description="$2" value
    value="${!name-}"
    if [ -n "$value" ]; then
        return
    fi
    if [ ! -t 0 ]; then
        echo "Missing $name ($description). Set it as an environment variable." >&2
        exit 1
    fi
    while [ -z "$value" ]; do
        read -r -p "$description ($name): " value || exit 1
        [ -n "$value" ] || echo "$name cannot be empty." >&2
    done
    printf -v "$name" '%s' "$value"
}

prompt_secret() {
    if [ -n "${API_SECRET:-}" ]; then
        return
    fi
    if [ ! -t 0 ]; then
        echo "Missing API_SECRET. Set it as an environment variable." >&2
        exit 1
    fi
    while [ -z "${API_SECRET:-}" ]; do
        read -r -s -p "API secret (API_SECRET, hidden): " API_SECRET || exit 1
        echo
        [ -n "$API_SECRET" ] || echo "API_SECRET cannot be empty." >&2
    done
}

echo "Required configuration (preset environment variables are reused):"
echo "  DSPAY_BASE_URL   DSPay API base URL"
echo "  PUBLIC_BASE_URL  public URL of this demo"
echo "  MERCHANT_NO      merchant number"
echo "  API_SECRET       API secret (hidden input)"
echo "  PORT             optional; default 3000"
echo "  FRONT_END_DIR    optional; default ../../front-end (relative to this script)"
prompt_required DSPAY_BASE_URL "DSPay API base URL"
prompt_required PUBLIC_BASE_URL "Public demo URL"
prompt_required MERCHANT_NO "Merchant number"
prompt_secret

PORT="${PORT:-3000}"
if ! [[ "$PORT" =~ ^[1-9][0-9]*$ ]] || (( PORT > 65535 )); then
    echo "Invalid PORT: expected an integer from 1 to 65535." >&2
    exit 1
fi
export DSPAY_BASE_URL PUBLIC_BASE_URL MERCHANT_NO API_SECRET PORT

cd "$ROOT"
echo "Demo page: ${PUBLIC_BASE_URL%/}/"
exec php -S "localhost:$PORT" server.php
