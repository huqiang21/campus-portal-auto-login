# Campus Portal Auto Login 校园网自动认证

Windows 下自动完成“网页认证型”校园网 / 公共 WiFi 登录的轻量脚本（Dr.COM 及同类型门户）。
连接目标 WiFi 的瞬间自动完成认证：**日常零活动、无常驻进程、无弹窗**。

## 原理

未认证时，任何上网请求都会被劫持到认证门户页。本脚本做三件事：

1. **探测**：能否访问一个“只有联网才能打开”的页面（默认百度，可配）；
2. **登录**：按配置调用门户的登录接口（POST 表单或 GET 参数均可）；
3. **回验**：3 秒后再探测一次，确认已联网。

三种运行方式任选：

| 方式 | 特点 |
|---|---|
| **WiFi 事件触发**（推荐） | 连上目标 WiFi 的那一瞬执行一次；平时零进程、零轮询 |
| 常驻监听 `-Watch` | 一个隐藏进程每 30 秒轻量探测，掉线即重登（能兜住“静默失效”，但始终占一个进程） |
| 定时任务 | 每隔 N 分钟跑一次，简单粗暴（会留下可见/半可见窗口，需配合隐藏启动器） |

## 快速开始（以北京邮电大学 BUPT-portal 为例）

```powershell
# 1) 复制示例配置为 config.ps1 并编辑（学号、密码、门户地址）
copy config.example.ps1 config.ps1

# 2) 手动测试一次
powershell -NoProfile -ExecutionPolicy Bypass -File auto-login.ps1
#    期望: already online 或离线时自动登录后 [OK] login successful

# 3) 配置 WiFi 事件触发（推荐）
#    a. 把 launch-hidden.vbs 与 auto-login.ps1 放在同一目录（vbs 会自动找到它）
#    b. 编辑 wifi-event-task.xml 两处占位符：
#         <UserId>DOMAIN\User</UserId>          -> 你的 Windows 账户
#         <Arguments>"C:\YourPath\launch-hidden.vbs"</Arguments> -> vbs 的实际路径
#    c. 导入：
schtasks /create /tn "Campus Auto Login" /xml wifi-event-task.xml /f
```

之后：连上 BUPT-portal → 约 5~10 秒自动认证完成，全程无窗口。
连其他 WiFi 时脚本会在 1 秒内直接退出（`config.ps1` 里的 `OnlineSSIDs` 过滤）。

## 适配其他学校（5 分钟）

技术原理通用，但每个学校的门户细节不同，用 F12 抓一次包即可：

1. **抓包**：连上校园网（不认证），浏览器 F12 → Network（勾选 Preserve log）→ 在认证页输入账号密码点登录；
2. **记录四件事**：
   - 认证门户地址（`Portal`）；
   - 登录接口形态：POST → 记下 `LoginPath`（即 `<form action>`）和表单字段名；GET → 记下带参数的完整 URL 模板；
   - 账号格式：裸学号还是带后缀（如 `学号@bupt`、`学号@cmcc`）——后缀直接拼进 `User` 字段即可；
   - 在线检测页：找一个“登录后才能打开”的稳定页面及其特征文字（`CheckUrl` / `CheckNeedle`）；
3. 填进 `config.ps1`，手动测试，确认 `[OK]`。

常见门户形态示例：

```powershell
# Dr.COM 新版（北邮当前）：POST 表单
Portal    = "http://10.3.8.211"
LoginPath = "/login"
LoginFields = @{ user = "{user}"; pass = "{pass}" }
LoginMethod = "POST"

# Dr.COM 老版：GET 带参
LoginMethod = "GET"
LoginUrl = "http://10.3.8.211/drcom/login?callback=dr1003&DDDDD={user}&upass={pass}&R1=0&R2=&R3=0&R6=0&para=00&0MKKey=123456"

# 另一种常见 POST：userid/passwd 字段名
LoginFields = @{ userid = "{user}"; passwd = "{pass}" }
```

> 说明：802.1X（RasDrCOM 类）与 WISPr（运营商 WiFi）是另一类技术，本脚本不适用，相关项目可搜 `drcom-generic` 等关键词。

## 常见问题

- **登录失败 `[x]`**：看日志 `[log]` 行；若显示“auth page re-rendered”多为账号密码错误或字段名变化；对照 F12 抓包核对该请求的 URL 与表单字段。
- **在线检测误判**：校园网可能劫持 HTTP，请优先用 HTTPS 站点做 `CheckUrl`；`CheckNeedle` 取页面独有文字。
- **睡眠唤醒后断网**：事件触发不会在“无声失效”时补登；在意的话改用 `-Watch` 常驻，或加开机/唤醒任务。
- **多设备互顶**：校园网账号一般限制同时在线终端数，手机与电脑同号会自动互相顶下线，去学校自服务系统管理设备。

## 安全

- `config.ps1` 以明文存放密码，**已被 .gitignore 排除，切勿提交**；
- 建议收紧文件权限：`icacls config.ps1 /inheritance:r /grant:r "%USERNAME%:RX"`；
- 密码泄露过（如误推仓库）请立即到学校自服务系统改密；
- 可选：改用环境变量 `CAMPUS_USER` / `CAMPUS_PASS` 注入凭据（脚本会自动读取并覆盖配置）。

## License

[MIT](LICENSE)
