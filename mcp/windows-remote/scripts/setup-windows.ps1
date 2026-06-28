# Windows 远程控制 - 一键配置脚本
# 以管理员权限运行：右键 PowerShell → "以管理员身份运行"
# 用法：Set-ExecutionPolicy Bypass -Scope Process -Force; .\setup-windows.ps1

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Windows 远程控制 - 一键配置" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ----- 1. 检查管理员权限 -----
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[错误] 请以管理员身份运行此脚本！" -ForegroundColor Red
    Write-Host "  右键 PowerShell → '以管理员身份运行'" -ForegroundColor Yellow
    exit 1
}
Write-Host "[OK] 管理员权限" -ForegroundColor Green

# ----- 2. 安装 OpenSSH Server -----
Write-Host ""
Write-Host "--- 安装 OpenSSH Server ---" -ForegroundColor Yellow
$sshCap = Get-WindowsCapability -Online | Where-Object Name -like "OpenSSH.Server*"
if ($sshCap.State -eq "Installed") {
    Write-Host "[OK] OpenSSH Server 已安装" -ForegroundColor Green
} else {
    Write-Host "正在安装 OpenSSH Server..." -ForegroundColor White
    Add-WindowsCapability -Online -Name "OpenSSH.Server~~~~0.0.1.0"
    Write-Host "[OK] OpenSSH Server 安装完成" -ForegroundColor Green
}

# ----- 3. 启动服务 + 开机自启 -----
Write-Host ""
Write-Host "--- 配置 SSH 服务 ---" -ForegroundColor Yellow
Start-Service sshd -ErrorAction SilentlyContinue
Set-Service -Name sshd -StartupType Automatic
$svc = Get-Service sshd
if ($svc.Status -eq "Running") {
    Write-Host "[OK] SSH 服务运行中 (开机自启)" -ForegroundColor Green
} else {
    Write-Host "[错误] SSH 服务启动失败，请手动检查" -ForegroundColor Red
    exit 1
}

# ----- 4. 防火墙放行 22 端口 -----
Write-Host ""
Write-Host "--- 配置防火墙 ---" -ForegroundColor Yellow
$rule = Get-NetFirewallRule -Name *sshd* -ErrorAction SilentlyContinue
if ($rule) {
    Write-Host "[OK] 防火墙规则已存在" -ForegroundColor Green
} else {
    New-NetFirewallRule -Name sshd -DisplayName "OpenSSH Server (sshd)" `
        -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22 | Out-Null
    Write-Host "[OK] 已创建防火墙规则（放行 TCP 22）" -ForegroundColor Green
}

# ----- 5. 设置默认 shell 为 PowerShell -----
Write-Host ""
Write-Host "--- 设置默认 Shell ---" -ForegroundColor Yellow
$regPath = "HKLM:\SOFTWARE\OpenSSH"
if (-not (Test-Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
}
$currentShell = (Get-ItemProperty -Path $regPath -Name DefaultShell -ErrorAction SilentlyContinue).DefaultShell
$psPath = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
if ($currentShell -ne $psPath) {
    New-ItemProperty -Path $regPath -Name DefaultShell -Value $psPath `
        -PropertyType String -Force | Out-Null
    Write-Host "[OK] 默认 Shell 已设为 PowerShell" -ForegroundColor Green
} else {
    Write-Host "[OK] 默认 Shell 已是 PowerShell" -ForegroundColor Green
}

# ----- 6. 修改 sshd_config AuthorizedKeysFile -----
# Windows 默认对管理员用户读取 __PROGRAMDATA__/ssh/administrators_authorized_keys
# 改为读取用户目录下的 .ssh/authorized_keys，与 Linux 习惯一致
Write-Host ""
Write-Host "--- 配置 AuthorizedKeysFile ---" -ForegroundColor Yellow
$sshdConfig = "C:\ProgramData\ssh\sshd_config"
if (Test-Path $sshdConfig) {
    $content = Get-Content $sshdConfig -Raw
    if ($content -match "AuthorizedKeysFile\s+__PROGRAMDATA__") {
        $content = $content -replace "AuthorizedKeysFile\s+__PROGRAMDATA__/ssh/administrators_authorized_keys", "AuthorizedKeysFile .ssh/authorized_keys"
        Set-Content -Path $sshdConfig -Value $content -NoNewline
        Restart-Service sshd
        Write-Host "[OK] 已修改 AuthorizedKeysFile → .ssh/authorized_keys 并重启 sshd" -ForegroundColor Green
    } else {
        Write-Host "[OK] AuthorizedKeysFile 配置正确，无需修改" -ForegroundColor Green
    }
} else {
    Write-Host "[!!] 未找到 $sshdConfig，请手动检查" -ForegroundColor Yellow
}

# ----- 7. 检查 adb / fastboot -----
Write-Host ""
Write-Host "--- 检查 adb / fastboot ---" -ForegroundColor Yellow
$adbOk = $false
$fastbootOk = $false

try { $null = adb version 2>$null; $adbOk = $true } catch {}
try { $null = fastboot --version 2>$null; $fastbootOk = $true } catch {}

if ($adbOk) {
    Write-Host "[OK] adb 可用" -ForegroundColor Green
} else {
    Write-Host "[!!] adb 未找到，请安装 Android SDK Platform Tools 并加入 PATH" -ForegroundColor Yellow
}

if ($fastbootOk) {
    Write-Host "[OK] fastboot 可用" -ForegroundColor Green
} else {
    Write-Host "[!!] fastboot 未找到，请安装 Android SDK Platform Tools 并加入 PATH" -ForegroundColor Yellow
}

# ----- 8. 输出连接信息 -----
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  配置完成！" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {
    $_.InterfaceAlias -notmatch "Loopback" -and $_.IPAddress -notmatch "^169\."
} | Select-Object -First 1).IPAddress

$user = $env:USERNAME
Write-Host "  IP 地址:   $ip" -ForegroundColor White
Write-Host "  用户名:    $user" -ForegroundColor White
Write-Host "  SSH 端口:  22" -ForegroundColor White
Write-Host ""
Write-Host "远程端请运行:" -ForegroundColor Yellow
Write-Host "  bash setup-remote.sh $ip $user" -ForegroundColor White
Write-Host ""

# ----- 9. 配置 SSH 密钥目录 -----
Write-Host "--- 配置 SSH 密钥目录 ---" -ForegroundColor Yellow
$sshDir = "C:\Users\$user\.ssh"
if (-not (Test-Path $sshDir)) {
    New-Item -Path $sshDir -ItemType Directory -Force | Out-Null
    Write-Host "[OK] 已创建 $sshDir" -ForegroundColor Green
}

# 确保 authorized_keys 文件存在
$authKeys = "$sshDir\authorized_keys"
if (-not (Test-Path $authKeys)) {
    New-Item -Path $authKeys -ItemType File -Force | Out-Null
    Write-Host "[OK] 已创建 $authKeys" -ForegroundColor Green
}

Write-Host ""
Write-Host "下一步: 将远程端生成的公钥内容追加到 $authKeys" -ForegroundColor Yellow
Write-Host ""
