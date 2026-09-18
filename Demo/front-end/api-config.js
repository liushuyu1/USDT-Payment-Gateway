// Demo API 地址配置 —— 由 start.sh 启动时按 PUBLIC_BASE_URL 自动覆盖；本文件提供默认值。
// 优先级：window.DEMO_API_BASE > file:// 回退 localhost:3000 > 页面同源。
// 本地直接双击 index.html 时用默认 localhost:3000；
// 服务器部署时 start.sh 会把它改写为后端对外地址（如 http://<server-ip>:3000）。
window.DEMO_API_BASE = "http://localhost:3000";
