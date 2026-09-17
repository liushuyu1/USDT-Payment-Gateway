#!/bin/bash

set -eu

ROOT="$(cd "$(dirname "$0")" && pwd)"

prompt_required() {
    local name="$1" description="$2" value
    value="${!name-}"
    if [ -n "$value" ]; then
        return
    fi
    if [ ! -t 0 ]; then
        echo "缺少 $name（$description），请通过环境变量提供。" >&2
        exit 1
    fi
    while [ -z "$value" ]; do
        read -r -p "$description ($name): " value || exit 1
        [ -n "$value" ] || echo "$name 不能为空。" >&2
    done
    printf -v "$name" '%s' "$value"
}

prompt_secret() {
    if [ -n "${API_SECRET:-}" ]; then
        return
    fi
    if [ ! -t 0 ]; then
        echo "缺少 API_SECRET，请通过环境变量提供。" >&2
        exit 1
    fi
    while [ -z "${API_SECRET:-}" ]; do
        read -r -s -p "API 密钥 (API_SECRET，输入不回显): " API_SECRET || exit 1
        echo
        [ -n "$API_SECRET" ] || echo "API_SECRET 不能为空。" >&2
    done
}

echo "启动配置（已设置的环境变量直接使用）："
echo "  DSPAY_BASE_URL   DSPay API 基础地址"
echo "  PUBLIC_BASE_URL  Demo 对外访问地址"
echo "  MERCHANT_NO      商户号"
echo "  API_SECRET       API 密钥（输入不回显）"
echo "  PORT             可选，默认 3000"
prompt_required DSPAY_BASE_URL "DSPay API 基础地址"
prompt_required PUBLIC_BASE_URL "Demo 对外访问地址"
prompt_required MERCHANT_NO "商户号"
prompt_secret

PORT="${PORT:-3000}"
if ! [[ "$PORT" =~ ^[1-9][0-9]*$ ]] || (( PORT > 65535 )); then
    echo "PORT 无效：请输入 1 到 65535 的整数。" >&2
    exit 1
fi
export DSPAY_BASE_URL PUBLIC_BASE_URL MERCHANT_NO API_SECRET PORT

cd "$ROOT"
exec php -S "localhost:$PORT" server.php
