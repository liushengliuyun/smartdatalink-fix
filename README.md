# SmartDataLink Fix - OTi 互联线一键修复

一键修复 OTi USB 互联线 (Smart KM Link / U3 KM Link, VID_0EA0&PID_7301) 软件栈卡死: 键盘/鼠标切换失灵、托盘卡住。

## 用法

1. 下载 Fix-KMLink.cmd 和 Fix-KMLink.ps1 到同一目录
2. 右键 Fix-KMLink.cmd -> 以管理员身份运行 (必须提权: LinkEngKM 旧实例可能杀不掉)
3. 看到 [3/3] 和状态汇报即完成

脚本默认【不会】重启 USB 设备节点 -- 见下方陷阱。

## 已知陷阱 (实测踩坑记录)

- **pnputil /restart-device 会把线缆固件打到挂死**: 复合设备卡在 ProblemCode 21 ("正在删除设备"死锁), 全部子设备 [Unknown], D 盘消失, 只有物理重插线缆才能恢复。软件发起的任何 USB 端口重置都可能触发。脚本 v3 起默认跳过该步骤, 需要时用 -RestartDevice 参数显式指定。
- **LinkEngKM 旧实例可能杀不掉**: 非提权终端 Stop-Process 静默失败, 必须管理员运行。
- **双机同时重启软件栈 + 物理重插后仍不通** (2026-10-12 实测): B->A 控制正常、剪贴板正常、A->B 输入不通 => 线缆固件状态机嫌疑最大, 软件层无法修复。

## 诊断笔记 (逆向发现)

- SmartData.exe 装 WH_KEYBOARD_LL/WH_MOUSE_LL 钩子做输入转发, 但只有鼠标钩子有看门狗 ("Mouse Hook MALFUNCTION!!! Exist Myself"), 键盘钩子失效无自愈
- 切换时 A 通过内部管道发 Cmd_Notify_KM_Switch_To_Remote, B 端 SmartData 应答后才武装 HID 端点接收; B 端不应答则 A 侧已切状态但 B 无输入
- 已验证的缓解: 禁用 USB 选择性挂起、关闭快速启动

## License

MIT