# Step 3: 死因指纹采集

对每个异常轮窗口([轮起点, 重启行])采集死因指纹。指纹库详见
`references/fingerprint-library.md`(含归因启发式)。本步骤按优先级扫:

## 3.1 高价值指纹(先扫这些)

```bash
# ① 模块死亡铁证(最稀有最硬)
grep -an "could not increase module refcount" <log>
# ② 显示 GPIO defer 链
grep -an "rc=-517\|component_bind_all failed" <log> | grep <异常轮窗口>
# ③ 两条崩溃点名路径(都要扫,漏一条就误判)
grep -an "is crashing" <log>            # apexd 路径:apexd: Native process 'X' is crashing. Attempting a revert
grep -an "times before boot completed" <log>  # init 路径:init: process with updatable components 'X' exited N times
# ④ PMIC 兄弟驱动齐挂(归因上溯的信号)
grep -an "spmi\|pm7250\|pm6125" <log> | grep <窗口> | grep -iE "fail|defer|-517"
```

## 3.2 指纹归因启发式

- **③ 的两条路径是并列的**,init 点名(updatable crashing → sys.init.updatable_crashing)
  与 apexd 点名(revert 路径)互补——**只扫一条会得出「无崩溃证据」的错误结论**
  (95916 教训:漏扫 apexd 路径导致误判显示链不成立)
- **④ 同一 PMIC mfd 父设备(如 pm7250b@2)下 ≥2 个兄弟子驱动同时 -517/-22**
  → 单驱动 bug 解释不了,上溯到 SPMI 总线/mfd 层 probe 停摆
- **① 的语义是唯一的**:try_module_get 失败 = 模块 state=GOING(卸载/加载失败
  清理中),比 -517(defer 噪音)干净得多。注意它要求 pctldev 已注册但模块
  非常——「probe 卡住」与「回滚中」都可能的场合,标 L2 强推断,给复测项
  (initcall_debug + /proc/modules)定谳
- **「重试方放弃窗口 < 故障持续时长」是放大器**:数清请求方重试几次、跨多久
  (如 msm_drm 对 -517 重试 12 次跨 14s 后放弃)——低概率时序故障变 boot 失败的扳机

## 3.3 对照组纪律

每个指纹必须做**正常轮对照**:同样的 grep 跑 2~3 个正常轮窗口。
正常轮也有 → 常态噪音(排除);仅异常轮有 → 指纹(采信)。
已知的常态噪音(勿当指纹):`Image size: 4096 Bytes`(读首块固定打印)、
`deferred probe timeout, ignoring dependency`、temp-alarm 注册失败、
SPMI 错误刷屏、`apexd --unmount-all failed : 256`(关机流程,紧邻
reboot command 时才是 rescue 链的一部分)。

**完成后,读取 `workflows/step-04-abl-recovery.md` 继续。**
