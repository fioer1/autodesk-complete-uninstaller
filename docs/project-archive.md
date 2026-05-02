# 项目归档说明

本文档记录当前项目的完成状态和后续维护方式。项目不需要人工日常管理，但 GitHub 仓库不应设置为 Archived，因为月度自动更新仍需要继续向 fork 推送分支。

## 当前状态

- 项目状态：完成，进入自动维护阶段。
- 当前工作分支：`feat/local-gui-sync`。
- 本地保护分支：`local-snapshot`，保留整理前的完整本地快照。
- 最新上游基线：`upstream/main`，当前提交为 `6ce82ca0dc1aa3b20e13c2711990bc5d37818378`。
- 当前 GUI 分支提交：`56c1aaf21b4ccd5db9062d8e31a30a02bf3d2747`。
- 最近同步日志：`logs/upstream-sync-2026-05.md`。

## 远端配置

- `origin`：`https://github.com/fioer1/autodesk-complete-uninstaller.git`
- `upstream`：`https://github.com/bequiet11/autodesk-complete-uninstaller.git`
- `upstream` 的 push URL 已设置为 `DISABLED`，避免误推原作者仓库。

## 自动化

Codex App 自动化名称：`Monthly upstream GUI sync`。

运行策略：

- 每天上午 9:00 检查一次。
- 如果当前月份已经存在成功同步日志，则跳过。
- 如果当前月份还没有成功同步日志，则执行一次月度同步。
- 这样即使每月 1 日当天没有开机，也会在本月下一次开机运行时补做。

自动化执行内容：

1. 抓取 `origin` 和 `upstream` 最新引用。
2. 以 `feat/local-gui-sync` 为 GUI 集成分支。
3. 将本地 GUI、启动脚本和回归测试适配到最新 `upstream/main`。
4. 遇到明确冲突时谨慎处理；不确定时写入冲突报告，不硬改。
5. 运行 GUI 相关 PowerShell 回归脚本。
6. 生成当月同步日志，记录上游提交、分支提交、冲突处理、测试结果和后续事项。
7. 成功后提交并推送到 `origin/feat/local-gui-sync`。

## 回归检查

自动化和人工同步都应运行以下脚本：

- `tests/gui_async_callback_closure_regression.ps1`
- `tests/gui_async_regression.ps1`
- `tests/gui_product_list_order_regression.ps1`
- `tests/gui_products_gridview_template_regression.ps1`
- `tests/gui_scan_perf_regression.ps1`
- `tests/gui_scan_registry_view_compat.ps1`
- `tests/gui_scan_source_parity_regression.ps1`
- `tests/gui_uninstall_behavior_regression.ps1`

## 人工恢复命令

如果自动化失败，需要人工恢复时，从仓库根目录执行：

```powershell
git status -sb
git fetch upstream --tags
git fetch origin
git switch feat/local-gui-sync
git rebase upstream/main
```

如果 rebase 有冲突，只处理 GUI 相关文件和测试文件；不确定的冲突应保留现场并记录到当月日志。

成功后运行测试：

```powershell
.\tests\gui_async_callback_closure_regression.ps1
.\tests\gui_async_regression.ps1
.\tests\gui_product_list_order_regression.ps1
.\tests\gui_products_gridview_template_regression.ps1
.\tests\gui_scan_perf_regression.ps1
.\tests\gui_scan_registry_view_compat.ps1
.\tests\gui_scan_source_parity_regression.ps1
.\tests\gui_uninstall_behavior_regression.ps1
```

推送时使用：

```powershell
git push --force-with-lease
```

仅在执行过 rebase 后才使用 `--force-with-lease`。

## 归档原则

- 不关闭、不 Archived 你的 fork，因为自动化需要继续推送。
- 不再需要人工月度检查，自动化负责补跑和记录日志。
- 如果 GitHub 凭据、仓库路径或自动化运行环境变化，才需要人工介入。
- 每月只以成功同步日志作为「已完成」标记。

## 最后人工确认

2026-05-02 已手动执行一次同步检查。结果：上游无新提交，GUI 分支已在最新上游基线上，8 个 GUI 回归脚本全部通过，并已推送到 `origin/feat/local-gui-sync`。
