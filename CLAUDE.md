# CLAUDE.md

Projektspezifische Regeln für Claude Code in diesem Repository. [`AGENTS.md`](AGENTS.md) ist die Quelle der Wahrheit für alle werkzeugunabhängigen Regeln (Server-Autorität, Grid-first, keine neuen Remotes ohne Decision, kein externes Framework, manuelle Teststrategie, Task-Scope, Freigabe vor Commits/Pushes/Deployments). Dieses Dokument ergänzt nur, was spezifisch für Claude Code in dieser Umgebung gilt.

## Roblox-Studio-MCP-Tools aktiv nutzen

Diese Entwicklungsumgebung stellt Roblox-Studio-MCP-Tools bereit (u. a. `execute_luau`, `screen_capture`, `start_stop_play`, `get_console_output`, `inspect_instance`, `search_game_tree`). Da dieses Projekt bewusst auf automatisierte Tests verzichtet ([`decisions/003-manual-testing-strategy.md`](decisions/003-manual-testing-strategy.md)), sind diese Tools der Ersatz dafür: Jede in einer `tasks/XXX-*.md`-Datei beschriebene manuelle Prüf-Checkliste soll, wo möglich, tatsächlich über diese Tools ausgeführt werden (Play-Test starten, Zustände per `execute_luau` abfragen/auslösen, Ergebnis per `screen_capture`/`get_console_output` belegen) — nicht nur beschrieben, sondern durchgeführt und das Ergebnis im "Ergebnis"-Abschnitt der Task-Datei dokumentiert.

## Rojo-Workflow

- `rojo serve` im Projektverzeichnis starten, dann in Roblox Studio über das Rojo-Plugin verbinden, um Live-Sync von `src/` zu erhalten.
- `default.project.json` mappt `src/shared`, `src/server`, `src/client` rekursiv — neue Unterordner benötigen **keine** Änderung an `default.project.json` (siehe `ARCHITECTURE.md` Abschnitt 2). Nur neue Top-Level-Instanzen (z. B. `DeathZone`, StarterPlayer-Properties) erfordern eine Änderung dieser Datei.

## Dokumentationspflege

Bei jeder Architekturänderung, die über den reinen Task-Scope hinausgeht: zuerst eine neue Datei unter `decisions/` anlegen, dann `ARCHITECTURE.md` entsprechend aktualisieren, erst danach den Code ändern. Reihenfolge nicht umdrehen — sonst läuft die Dokumentation dem Code nach.
