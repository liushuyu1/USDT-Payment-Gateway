[English](README.md) | [中文](README.zh-CN.md)

# Java Mock Merchant

JDK 8+，零外部依赖。该服务真实调用 `POST /dspay/public/order/create`，并使用响应中的 `checkoutUrl` 跳转收银台。

版本基线：最低 JDK 8；已在 Amazon Corretto `1.8.0_504`（真实 JDK 8）和 Eclipse Temurin `21.0.11` 上端到端验证。无需 Maven/Gradle，源码只使用 JDK 标准库。`./start.sh` 会先编译到 `build/` 再以 `java -cp build DspayMockMerchant` 运行（兼容不支持单文件源码启动的 JDK 8）。

> 以下命令中的 `REPLACE_WITH_REAL_MERCHANT_NO`、`REPLACE_WITH_REAL_API_SECRET` 和 `REPLACE_WITH_REAL_DSPAY_API_HOST` 是占位值，执行前必须替换为真实参数。`merchantNo` 和 `apiSecret` 从DSPay商户后台获取。

```bash
mkdir -p build && javac -d build src/DspayMockMerchant.java
java -DmerchantNo="REPLACE_WITH_REAL_MERCHANT_NO" -DapiSecret="REPLACE_WITH_REAL_API_SECRET" \
  -DdspayBase="https://REPLACE_WITH_REAL_DSPAY_API_HOST" \
  -DpublicBase="http://localhost:3000" -cp build DspayMockMerchant
```

后台运行可执行 `./start.sh`。脚本会交互询问 `DSPAY_BASE_URL`、`PUBLIC_BASE_URL`、`MERCHANT_NO` 和 `API_SECRET`，密钥输入不回显。提前设置对应环境变量可跳过询问。监听端口优先使用环境变量 `PORT`，否则使用 `PUBLIC_BASE_URL` 中的端口；URL 不写端口时默认 `80`。Demo 不支持 HTTPS，`PUBLIC_BASE_URL` 必须使用 `http://`。`FRONT_END_DIR` 可选，可指定其他前端目录（默认 `../../front-end`）。输入值不会保存；下次启动需重新输入或通过环境变量提供。非交互运行必须提供上述四项环境变量。

- `GET /create`：签名预下单并 302 到响应中的 `checkoutUrl`
- `GET /query?orderNo=...` 或 `?outOrderNo=...`：签名主动查询
- `POST /notify/success`：回调验签通过后返回 `SUCCESS`
- `POST /notify/fail`：回调验签通过后固定返回 HTTP 200 + `FAIL`，模拟商户处理失败和 DSPay 重试
- `POST /notify`：兼容旧配置，等同 `/notify/success`
- `GET /` 托管前端商店页（与接口同源；可用 `FRONT_END_DIR` 指定其他目录）
- `returnUrl` 跳回商店首页；`successRedirectUrl` 跳到 `/query` 展示真实订单状态——浏览器跳转不能作为发货依据

完整说明见 [../../README.zh-CN.md](../../README.zh-CN.md)。
