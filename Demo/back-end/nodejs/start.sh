#!/bin/bash
# DSPay mock merchant — 后台启动脚本

set -e

ROOT="$(cd "$(dirname "$0")" && pwd)"
PID_FILE="$ROOT/server.pid"
LOG_DIR="$ROOT/logs"
LOG_FILE="$LOG_DIR/server.log"

# 已运行则跳过
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        echo "服务已在运行 (PID=$PID)，如需重启请先执行 ./stop.sh"
        exit 1
    fi
    rm -f "$PID_FILE"
fi

prompt_required() {
    local name="$1" description="$2" value
    value="${!name}"
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
    if [ -n "$API_SECRET" ]; then
        return
    fi
    if [ ! -t 0 ]; then
        echo "缺少 API_SECRET，请通过环境变量提供。" >&2
        exit 1
    fi
    while [ -z "$API_SECRET" ]; do
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
echo "  FRONT_END_DIR    可选，默认 ../../front-end（相对脚本目录）"
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

echo "启动服务..."

cd "$ROOT"
mkdir -p "$LOG_DIR"
printf '\n=== 启动于 %s ===\n' "$(date)" >> "$LOG_FILE"
LOG_START_LINE=$(wc -l < "$LOG_FILE")
nohup node src/server.js >> "$LOG_FILE" 2>&1 &
PID=$!
echo $PID > "$PID_FILE"

for ((attempt = 0; attempt < 30; attempt++)); do
    if tail -n +"$((LOG_START_LINE + 1))" "$LOG_FILE" | grep -q '^Mock merchant:' && kill -0 "$PID" 2>/dev/null; then
        echo "服务启动成功 (PID=$PID)"
        echo "日志文件: $LOG_FILE"
        echo "监听端口: $PORT"
        echo "查看日志: tail -f '$LOG_FILE'"
        echo "停止服务: ./stop.sh"
        exit 0
    fi
    if ! kill -0 "$PID" 2>/dev/null; then
        break
    fi
    sleep 1
done

echo "服务启动失败，最近日志：" >&2
tail -n +"$((LOG_START_LINE + 1))" "$LOG_FILE" >&2
if kill -0 "$PID" 2>/dev/null; then
    kill "$PID" 2>/dev/null || true
fi
rm -f "$PID_FILE"
exit 1
