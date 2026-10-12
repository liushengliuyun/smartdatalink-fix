# Stop-KMLink.ps1 v1 - OTi 互联线软件栈完全停止 (不留活口, 不拉起)
# 用途: 软件栈进入自愈死锁循环 (SmartData 几秒一重启、鼠标不停转圈) 时, 彻底停掉它
# 注意: 需管理员权限; 重启电脑后栈会按自启动恢复
$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "=== OTi 软件栈完全停止 ===" -ForegroundColor Cyan
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if(-not $admin){
  Write-Host "需要管理员权限 (LEWD/LinkEngKM 提权运行, 非管理员杀不掉)。请右键 Stop-KMLink.cmd -> 以管理员身份运行" -ForegroundColor Red
  Read-Host "按回车键关闭"
  exit 1
}

# LEWD 是看门狗会拉起其他进程, 必须先杀; 多扫几轮防竞态拉起
1..3 | ForEach-Object {
  foreach($n in "LEWD","SmartData","LinkEngKM","SDLStarter"){
    Stop-Process -Name $n -Force -ErrorAction SilentlyContinue
  }
  Start-Sleep -Seconds 2
}

# 验收
$left = @()
foreach($n in "LEWD","SmartData","LinkEngKM","SDLStarter"){
  if(Get-Process -Name $n -ErrorAction SilentlyContinue){ $left += $n }
}
if($left){
  Write-Host ("仍存活: " + ($left -join ", ") + " (请再运行一次本脚本)") -ForegroundColor Red
} else {
  Write-Host "四个进程已全部停止, 转圈圈应立即消失" -ForegroundColor Green
}
Write-Host ""
Write-Host "提示: 重启电脑后 OTi 栈会随自启动恢复; 线缆的 D 盘 (SMARTLINK) 是固件提供的, 不受影响"
Read-Host "按回车键关闭"
