# Fix-KMLink.ps1 - OTi 互联线(U3 KM Link)一键修复
# 适用: 键盘/鼠标切换失灵、拔插无效、D盘消失、软件栈卡死
# 原理: 停软件栈(含看门狗) -> 重启线缆USB设备节点 -> 重新拉起软件栈 (等效免重启的"重启+重插")
# 注意: 需管理员权限运行 (pnputil 重启设备节点用)
$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "=== OTi 互联线一键修复 v2 ===" -ForegroundColor Cyan

# 1) 停软件栈 (先杀 LEWD 看门狗, 防它把 SmartData 拉起来)
foreach($n in "LEWD","SmartData","LinkEngKM","SDLStarter"){
  Stop-Process -Name $n -Force -ErrorAction SilentlyContinue
}
Write-Host "[1/4] OTi 软件栈已停止"
Start-Sleep -Seconds 2

# 2) 重启线缆 USB 设备节点 (设备整体掉线时自动跳过)
$devs = Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object { $_.InstanceId -match "VID_0EA0&PID_7301" -and $_.InstanceId -notmatch "&MI_" }
if($devs){
  foreach($d in $devs){
    Write-Host ("[2/4] 重启设备节点: " + $d.InstanceId)
    pnputil /restart-device "$($d.InstanceId)" 2>$null | Out-Null
  }
  Start-Sleep -Seconds 8
} else {
  Write-Host "[2/4] 线缆不在总线上, 跳过设备重启" -ForegroundColor Yellow
}

# 3) 重新拉起软件栈 (与注册表自启动同款参数)
$sd = Get-ChildItem "$env:APPDATA\OTi\*\FunctModules\*\SmartData.exe" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if($sd){
  Start-Process -FilePath $sd.FullName -WorkingDirectory $sd.DirectoryName -ArgumentList "-GN:RunFromRegistry","-GS:HWID:VID_0EA0&PID_7301","-GS:AppLoaderExeName:SmartDataLink.exe"
  Write-Host ("[3/4] 已拉起: " + $sd.FullName)
} else {
  Write-Host "[3/4] 未找到 SmartData.exe, 请插线运行 D:\SmartDataLink.exe 安装" -ForegroundColor Red
}
Start-Sleep -Seconds 8

# 4) 状态汇报
Write-Host "[4/4] 当前状态:"
foreach($n in "SmartData","LinkEngKM","SDLStarter","LEWD"){
  $p = Get-Process -Name $n -ErrorAction SilentlyContinue
  Write-Host ("  进程 " + $n + " : " + $(if($p){"运行中 PID=" + $p.Id}else{"未运行"}))
}
Get-PnpDevice -ErrorAction SilentlyContinue | Where-Object { $_.InstanceId -match "VID_0EA0&PID_7301" } | ForEach-Object {
  Write-Host ("  设备 [" + $_.Status + "] " + $_.FriendlyName)
}
$v = Get-Volume -DriveLetter D -ErrorAction SilentlyContinue
Write-Host ("  D盘: " + $(if($v){$v.FileSystemLabel + " 正常"}else{"未出现"}))
Write-Host ""
Write-Host "完成。若仍连不上对方电脑, 请在对方电脑上也运行本脚本 (把 Fix-KMLink.cmd 和 Fix-KMLink.ps1 两个文件传过去, 双击 Fix-KMLink.cmd)" -ForegroundColor Green
Read-Host "按回车键关闭"