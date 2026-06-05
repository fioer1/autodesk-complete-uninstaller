# Upstream GUI Sync Log - 2026-06

- Run time: 2026-06-05T19:08:33.5972468+08:00
- Automation: Monthly upstream GUI sync
- Branch: `feat/local-gui-sync`
- Monthly sync marked successful: yes

## Upstream State

- Local `upstream/main` before successful fetch: `6ce82ca0dc1aa3b20e13c2711990bc5d37818378`
- Remote `upstream/main` observed via `git ls-remote upstream refs/heads/main`: `ae086ab0291d52ceab83e3f5d37dfdc431d29da2`
- Local `upstream/main` after fetch: `ae086ab0291d52ceab83e3f5d37dfdc431d29da2`
- Upstream change integrated: `ae086ab Fix Option 4 Deep Clean hang + add admin self-elevation`

## Local State

- Local branch before sync: `1b5adbe8569da091a9df30f6405bfdbcd314bdc4`
- `origin/feat/local-gui-sync` before sync: `1b5adbe8569da091a9df30f6405bfdbcd314bdc4`
- Local branch after upstream integration: `7e42218631cad9b04cc516553890b119b6ff89e7`
- Integration method: merge `upstream/main` into `feat/local-gui-sync`
- Force push needed: no

## Files Changed

Upstream integration changed:

```text
M autodesk_complete_uninstaller.bat
```

This sync log was also updated:

```text
M logs/upstream-sync-2026-06.md
```

The local GUI files and regression tests were preserved:

```text
AutodeskUninstallerGUI.ps1
DESIGN-lamborghini.md
LaunchGUI.bat
docs/project-archive.md
logs/upstream-sync-2026-05.md
tests/gui_async_callback_closure_regression.ps1
tests/gui_async_regression.ps1
tests/gui_product_list_order_regression.ps1
tests/gui_products_gridview_template_regression.ps1
tests/gui_scan_perf_regression.ps1
tests/gui_scan_registry_view_compat.ps1
tests/gui_scan_source_parity_regression.ps1
tests/gui_uninstall_behavior_regression.ps1
```

## Conflict Decisions

No conflicts occurred. The merge completed with Git's `ort` strategy.

## GUI Regression Tests

All local GUI regression scripts passed:

- `tests/gui_async_callback_closure_regression.ps1`: passed
- `tests/gui_async_regression.ps1`: passed
- `tests/gui_product_list_order_regression.ps1`: passed
- `tests/gui_products_gridview_template_regression.ps1`: passed
- `tests/gui_scan_perf_regression.ps1`: passed
- `tests/gui_scan_registry_view_compat.ps1`: passed
- `tests/gui_scan_source_parity_regression.ps1`: passed
- `tests/gui_uninstall_behavior_regression.ps1`: passed

## Network Notes

The configured global Git proxy still points at `http://127.0.0.1:7890`, which was unavailable. This run succeeded by passing a temporary Git proxy override:

```text
git -c http.proxy=http://127.0.0.1:7892 -c https.proxy=http://127.0.0.1:7892 ...
```

## Follow-up Needed

Update the global Git proxy from `127.0.0.1:7890` to a working proxy such as `127.0.0.1:7892`, or remove it if direct GitHub access is available. No code follow-up is needed for this sync.

## Post-sync GUI Button Mapping Debug - 2026-06-05T20:29:14.4427448+08:00

- Trigger: User asked to re-check whether the other GUI buttons match the original batch menu after Full Uninstall appeared to run option 10.
- Local code commit before this debug pass: `f2d352d`
- GUI fix commit: `f50a7c5 fix: align GUI button batch mappings`
- Upstream commit context: `ae086ab0291d52ceab83e3f5d37dfdc431d29da2`
- Files changed:
  - `AutodeskUninstallerGUI.ps1`
  - `autodesk_complete_uninstaller.bat`
  - `tests/gui_button_batch_mapping_regression.ps1`
  - `tests/gui_full_clean_sequence_regression.ps1`
- Conflict decisions: no merge or rebase conflicts occurred in this debug pass.
- Findings:
  - Several GUI buttons still sent stale `X`/`0` menu-navigation input after invoking batch options 6, 7, 8, 10, 11, and 12.
  - `AUTODESK_GUI_MODE=1` was initially placed on the left side of the pipe, which does not reliably set the variable for the batch process on the right side.
  - The previous Full Clean auto-scan patch had also affected the Option 2 no-scan branch; Option 2 now returns to the menu as before, while Option 3 owns the auto-scan path.
- Fixes:
  - GUI buttons now map directly to batch options 3, 4, 5, 6, 7, 8, 10, 11, and 12 without stale pause/menu-navigation input.
  - Error 103 is labeled as diagnosis in the GUI and declines repair prompts by default.
  - Piped GUI commands now set `AUTODESK_GUI_MODE=1` on the batch side of the pipe.
  - Batch GUI mode exits after one-shot operations instead of pausing and returning to `:main_menu`.
- Test results:
  - All 12 PowerShell GUI regression scripts passed.
  - PowerShell AST parse for `AutodeskUninstallerGUI.ps1` passed.
  - `git diff --check` passed.
  - A direct cmd pipe check confirmed `AUTODESK_GUI_MODE=1` is visible on the right side of the pipe.
- Monthly sync marked successful: yes; this was a post-sync GUI/debug follow-up, not a new upstream sync.
- Follow-up needed: none for the GUI button mapping. The global Git proxy note above still applies.
