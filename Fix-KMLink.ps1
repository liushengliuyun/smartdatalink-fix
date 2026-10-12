# Fix-KMLink.ps1 v3 - OTi 互联线一键修复
# 适用: 键盘/鼠标切换失灵、软件栈卡死
# 重要教训: 默认【不】重启 USB 设备节点 -- 实测 pnputil /restart-device 会让线缆固件挂死
#          (复合设备卡 ProblemCode 21 "正在删除设备"), 只能物理重插恢复!
param([switch]$RestartDevice)
$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "=== OTi 互联线一键修复 v3 ===" -ForegroundColor Cyan
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if(-not $admin){
  Write-Host "需要管理员权限 (LinkEngKM 旧实例可能杀不掉)。请右键 Fix-KMLink.cmd -> 以管理员身份运行" -ForegroundColor Red
  Read-Host "按回车键关闭"
  exit 1
}

# 1) 停软件栈 (先杀 LEWD 看门狗防拉起, 四个进程一个不漏)
foreach($n in "LEWD","SmartData","LinkEngKM","SDLStarter"){
  Stop-Process -Name $n -Force -ErrorAction SilentlyContinue
}
Write-Host "[1/3] OTi 软件栈已全部停止"
Start-Sleep -Seconds 2

# 2) 设备节点重启 -- 默认跳过! (实测会让固件挂死, 必须物理重插)
if($RestartDevice){
  Write-Host "[2/3] 警告: 你指定了 -RestartDevice。实测重启设备节点会让线缆固件挂死," -ForegroundColor Yellow
  Write-Host "      之后只能物理重插线缆恢复。5 秒后执行..." -ForegroundColor Yellow
  Start-Sleep -Seconds 5
  $dev = Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object { $_.InstanceId -match "VID_0EA0&PID_7301\\" -and $_.InstanceId -notmatch "&MI_" } | Select-Object -First 1
  if($dev){ pnputil /restart-device "$($dev.InstanceId)" 2>$null | Out-Null; Start-Sleep -Seconds 8 }
} else {
  Write-Host "[2/3] 跳过设备节点重启 (默认; 实测会挂死固件, 需物理重插才能恢复)"
}

# 3) 重新拉起软件栈 (与注册表自启动同款参数)
$sd = Get-ChildItem "$env:APPDATA\OTi\*\FunctModules\*\SmartData.exe" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if($sd){
  Start-Process -FilePath $sd.FullName -WorkingDirectory $sd.DirectoryName -ArgumentList "-GN:RunFromRegistry","-GS:HWID:VID_0EA0&PID_7301","-GS:AppLoaderExeName:SmartDataLink.exe"
  Write-Host ("[3/3] 已拉起: " + $sd.FullName)
} else {
  Write-Host "[3/3] 未找到 SmartData.exe, 请插线运行 D:\SmartDataLink.exe 安装" -ForegroundColor Red
}
Start-Sleep -Seconds 8

# 状态汇报
Write-Host ""
Write-Host "=== 当前状态 ==="
foreach($n in "SmartData","LinkEngKM","SDLStarter","LEWD"){
  $p = Get-Process -Name $n -ErrorAction SilentlyContinue
  Write-Host ("  进程 " + $n + " : " + $(if($p){"运行中 PID=" + $p.Id}else{"未运行 (设备接入后会自动拉起)"}) )
}
Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object { $_.InstanceId -match "VID_0EA0&PID_7301" } | ForEach-Object {
  Write-Host ("  设备 [" + $_.Status + "] " + $_.FriendlyName)
}
$v = Get-Volume -DriveLetter D -ErrorAction SilentlyContinue
Write-Host ("  D盘: " + $(if($v){$v.FileSystemLabel + " 正常"}else{"未出现"}))
Write-Host ""
Write-Host "完成。若仍连不上对方电脑, 在对方电脑上做同样操作 (双击 Fix-KMLink.cmd)" -ForegroundColor Green
Read-Host "按回车键关闭"