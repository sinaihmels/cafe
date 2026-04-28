## Recovery rollback on 2026-04-28

This worktree was moved to branch `codex/recovery-20260428` at commit `29cf133`
(`Main UI updates now I will customize myself`).

Reason:
- The project was only opening in Godot recovery mode.
- The problem survived git rollbacks, which pointed to editor/tool-script state and local cache as part of the issue.
- A fresh `.godot` cache was generated on this recovery branch after backing up the old one to `.godot_backup_20260428`.

Smoke-test result on this recovery branch:
- Godot `4.7.dev2` editor startup produced no script, parse, or missing-resource errors.
- Godot runtime startup produced no script, parse, or missing-resource errors.

Commits intentionally excluded from this recovery branch:
- `3dbd844` `able to customize and see ui in the editor. 1st version of dialogue system`
- `cb6200d` `card changes`
- `55ca630` `Changes before customizing the ui myself`
- `abf5269` `Changes in the editor are true and are not being overwritten by code`
- `05fbddf` `issues`

High-level areas removed with those commits:
- Dialogue system data, dialogue outcomes, dialogue UI theme, and encounter dialogue overlay work.
- Card/buff/customer content additions and updates.
- Encounter UI customization work across app view, encounter screen, counter, HUD, resources, customer lane, hand fan, and kitchen stage views.
- Editor-preview-heavy `@tool` work for kitchen/customer UI scenes.

One concrete broken state found while investigating:
- A historical Godot log showed `app_view.gd` looking for `Margin/Root/...` while the loaded scene tree had already moved those nodes, causing `Node not found` errors during startup. That exact mismatch is not present on this recovery branch.

Recommended reintroduction order later:
1. Reapply `3dbd844` alone and test editor open/run.
2. Reapply `cb6200d` alone and test again.
3. Reapply `55ca630` alone and test again.
4. Reapply `abf5269` in smaller chunks, especially `@tool` UI/editor-preview changes.
5. Reapply `05fbddf` last, also in smaller chunks.
