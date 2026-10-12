# SmartDataLink Fix - OTi 互联线一键修复

一键修复 OTi USB 互联线 (Smart KM Link / U3 KM Link, VID_0EA0&PID_7301) 的常见故障:

- 键盘/鼠标切换到另一台电脑失灵
- 拔插线缆无效、越插越糟
- 虚拟光驱 D 盘 (SMARTLINK) 消失
- OTi 软件栈卡死 (SmartData / LinkEngKM / LEWD)

## 原理

停掉整个 OTi 软件栈 (含 LEWD 看门狗) -> 用 pnputil 重启线缆 USB 设备节点 -> 按注册表自启动同款参数重新拉起软件栈。
等效于"两台电脑都重启 + 重新拔插线缆"的软件部分, 免重启。

## 用法

1. 下载 Fix-KMLink.cmd 和 Fix-KMLink.ps1 放同一目录 (桌面即可)
2. 双击 Fix-KMLink.cmd (未提权会自动弹 UAC, 点"是")
3. 看到 [4/4] 状态汇报即完成

若本机修不好 (线缆整体从 USB 总线掉线, 所有设备显示 Unknown), 只能物理重插; 恢复后在另一台电脑上做同样操作。

## 适用环境

- 两台 Windows 电脑 + OTi 方案 USB 互联线 (设备管理器显示 "Oti U3 Transfer Cable", VID_0EA0&PID_7301)

## 诊断笔记 (逆向发现)

- SmartData.exe 装键盘/鼠标低级钩子做转发, 但只有鼠标钩子有看门狗 ("Mouse Hook MALFUNCTION!!!"), 键盘钩子失效后无自愈
- 切换握手: A 侧切换时经内部管道发 Cmd_Notify_KM_Switch_To_Remote 给 B, B 的 LinkEngKM 应答后固件才把 HID 端点武装为接收模式; B 端应答卡死 -> A 已切出 (光标消失) 但 B 永远收不到输入
- LinkEngKM 与 LEWD 以高权限运行: 非管理员 Stop-Process 杀不掉且静默失败, 托盘退出/结束"应用"进程也不会碰到它们 -> 修复必须管理员运行, 四进程全杀
- 剪贴板走数据通道, 与键鼠控制链路相互独立; 剪贴板共享正常不代表控制链路正常
- 编码坑: 中文 Windows 的 PowerShell 5.1 把无 BOM 的 UTF-8 按 ANSI/GBK 读, 脚本中文串乱码导致解析直接失败 (窗口闪退, 一行未执行) -> .ps1 必须存成 UTF-8 with BOM
- 故障时线缆可能整体从 USB 总线掉线 (设备管理器全 [Unknown]), 此时软件无解, 只能物理重插
- 已验证的缓解: 禁用 USB 选择性挂起、关闭快速启动

## License

MIT