[English](README.md) | [中文](README.zh-CN.md)

# DSPay Mock Merchant

This demo implements the merchant integration flow: the browser calls the merchant backend; the backend signs and calls DSPay create-order; only after receiving `checkoutUrl` does it redirect the customer. `apiSecret` and signed order fields are never exposed in the Checkout URL.

## Tested runtimes

| Demo | Minimum | Tested versions | Dependencies |
|------|---------|-----------------|--------------|
| Node.js | Node.js `18.20.8` | Node.js `18.20.8` + npm `10.8.2` | No npm dependencies; `.nvmrc` included |
| Java | JDK 8 | Verified on Corretto `1.8.0_504` and Temurin `21.0.11` | No Maven/Gradle dependencies |
| PHP | PHP 5.6 | PHP CLI `5.6.40` and `8.5.10` | No Composer dependency |
| Frontend | A modern browser with `crypto.randomUUID()` | Chrome `151.0.7922.175` | One HTML file; no build step |

Tests were run on macOS `15.1` and Docker Linux. “Minimum” is the source compatibility baseline; “Tested versions” lists runtimes actually used to execute repository tests.

Check local versions before running a demo:

```bash
node --version && npm --version
java -version && javac -version
php --version
```

Versions below the listed minimum are unsupported. The demos do not use frameworks such as Express, Spring Boot, or Laravel, so there are no framework-version requirements.

All Node.js documentation and code use one baseline; multiple Node.js installations are not required:

```bash
cd Demo/back-end/nodejs
nvm install
nvm use
npm test
```

## Run Node.js

> The start script interactively prompts for the DSPay API URL, public demo URL, `merchantNo`, and `apiSecret`. Obtain the credentials from the DSPay Merchant Portal; entered values are not written to disk.

```bash
cd Demo/back-end/nodejs
./start.sh
```

Every backend version also serves the store page itself: after `./start.sh`, open `http://localhost:3000` (or your `PUBLIC_BASE_URL`) and click Pay Now — page and API share the same origin, no extra static hosting needed. Opening `Demo/front-end/index.html` directly from disk also works locally (it falls back to `http://localhost:3000`). Expose port 3000 through ngrok or similar when testing webhooks, then configure the public `/notify/success` or `/notify/fail` URL in the merchant portal. `FRONT_END_DIR` optionally points the backend at a different front-end directory (default: `../../front-end`).

The front end displays an editable Order ID (`outOrderNo`). The refresh button generates a new ID each time; Pay Now submits the displayed ID. Use a new ID for each new order. Reuse the original ID and identical business fields only when retrying the same order. The backend uses the supplied value, or generates one when none is supplied.

## Run Java

```bash
cd Demo/back-end/java
./start.sh
```

## Run PHP

> The start script interactively prompts for missing configuration and hides `apiSecret` input. Environment variables remain available for non-interactive startup.

```bash
cd Demo/back-end/php
./start.sh
```

All three `start.sh` scripts use the same interactive flow: DSPay API URL, public demo URL, merchant number, and hidden API secret, with port `3000` as the default. Run `./stop.sh` in the same directory to stop the service.

## Demo endpoints

| Method | Path | Purpose |
|---|---|---|
| GET | `/create` | Create DSPay order server-to-server, then 302 to returned `checkoutUrl` |
| GET | `/query?orderNo=...` | Node/PHP demo: signed authoritative order query |
| POST | `/notify/success` | Verify the webhook, return `{"code":"SUCCESS","msg":"ok"}`, and stop DSPay retries |
| POST | `/notify/fail` | Verify the webhook, return `{"code":"FAIL","msg":"mock merchant failure"}`, and trigger DSPay error logging/retry |
| POST | `/notify` | Backward-compatible alias of `/notify/success` |
| GET | `/payment/return` | Timeout landing; Node/PHP demo queries DSPay |
| GET | `/payment/success` | Success landing; Node/PHP demo queries DSPay |

All three language demos expose the same notification URLs and retain their existing `./start.sh` workflow. Expose the selected backend through ngrok or a similar tunnel, then configure one of these merchant-portal URLs:

```text
Success scenario: https://your-public-host/notify/success
Failure scenario: https://your-public-host/notify/fail
```

The failure scenario deliberately returns HTTP 200 with top-level `code=FAIL`, allowing you to test DSPay's merchant-failure error log and retry path rather than a network failure.

Notification logs include both the verified request and the actual response, for example: `[NOTIFY response] path=/notify/success status=200 body={"code":"SUCCESS","msg":"ok"}`. The API secret is never logged.

In production, store the secret in KMS and assign a fresh `outOrderNo` to every new order. Only a network retry of the same logical create request should reuse its original `outOrderNo` and identical business fields. Add HTTP timeouts and bounded retries, process webhooks idempotently, and fulfill only after a verified webhook or server-side query reports `COMPLETED`. A browser redirect is never proof of payment. Both URLs are optional: `returnUrl` is used only when the order times out, while `successRedirectUrl` is used only after completion. Checkout becomes unviewable 180 days after order creation and must not be used as a permanent order-details URL.
