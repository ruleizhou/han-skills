# 死因指纹库与归因启发式

## 高价值指纹(稀有度排序)

### ① `could not increase module refcount for pin N`(-22)
- 出处:`drivers/pinctrl/pinmux.c:153`,try_module_get(pctldev->owner) 失败
- **唯一语义**:pinctrl 属主模块 state=GOING(正在卸载/加载失败清理中)。
  COMING 算活,只有 GOING 算死——「模块正在死去」的铁证
- 全文出现次数个位数即可圈定异常轮(95916:10 次精确锁定 2 轮)
- 深挖方向:为什么 GOING(加载失败回滚卡住?卡点疑在 SPMI 同步事务)→
  复测 initcall_debug + /proc/modules 的 state 列

### ② `request for <gpio> failed, rc=-517` + `component_bind_all failed: -517`
- -517=EPROBE_DEFER,海量噪音;**与「请求方重试 N 次后放弃」组合才有意义**
- 数请求方重试次数与跨度(msm_drm 12 次/14s 后放弃 = 放弃窗口 < 故障时长,
  低概率时序故障放大成 boot 失败的扳机)
- 正常轮同窗口 0 次 = 指纹;正常轮也有 = 噪音

### ③ 崩溃点名双路径(必须都扫)
- init 路径:`init: process with updatable components 'X' exited N times before
  boot completed` → 触发 sys.init.updatable_crashing → RescueParty 观察源
- apexd 路径:`apexd: Native process 'X' is crashing. Attempting a revert`
- **两条并列互补**,只扫一条会误判「无崩溃证据」;一条被点名不排除另一条
  也在崩(95916:轮 A 双点名,轮 B 仅 apexd 点名照样触发 RescueParty)

### ④ PMIC mfd 兄弟驱动齐挂
- 同一 SPMI 从设备(如 pm7250b@2)下 ≥2 个不同子驱动(spmi-gpio / adc-tm /
  usb-pdphy / charger-iio)同时 -517/-22
- 单驱动 bug 解释不了兄弟齐挂 → 上溯 SPMI 总线/mfd 层 probe 停摆
- 配套:`Failed to get IIO path for MAIN_PSY`(充电 IIO 时序)、
  `set keepcaps failed`(ODM 充电服务前兆)

## 归因启发式

1. **兄弟齐挂 → 查父**(mfd/总线层);**单点挂 → 查驱动自身**
2. **同轮多因并存时**(如 GPIO 链 + 充电服务崩),分清「触发者」(被 init/apexd
   点名的)与「同源受害者」(同一 PMIC 时序的另一个影子)
3. **显示链判活**:SF 进程的 SELinux avc 日志存在 ≠ 显示栈正常——要看
   `Could not find 'IComposer...'/'SurfaceFlingerAIDL'`(接口缺失才是死相)
4. `disp_vddio` 等 gpio 名可能是驱动 panel 配置结构体的 label,dts 里搜不到——
   按 panel 节点 gpios phandle 追,别按名字搜

## 已知常态噪音(勿当指纹)

| 噪音 | 频度量级 | 真相 |
|------|---------|------|
| `Image size: 4096 Bytes` | 每轮 | bootloader 读首块固定打印,非分区大小;真实加载看 `Load Image total time` |
| `deferred probe timeout, ignoring dependency` | 每轮数十次 | 常态(全文 40 万次) |
| temp-alarm 注册失败 | 每轮 | 常态(全文 19 万次) |
| SPMI 错误刷屏 | 每轮 | 常态(全文 23 万次) |
| `apexd --unmount-all failed : 256` | 每次关机 | 关机流程常态(1979 次);紧邻 reboot command 才是 rescue 链一部分 |
| UDC/dwc3 busy 风暴 | 高频 | Type-C 相关,与重启根因无直接关联时只作伴随记录 |
