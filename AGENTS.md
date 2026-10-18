# AGENTS.md

Dauerhafte Regeln für KI-Coding-Agenten (Claude Code, Codex oder andere) in diesem Repository. Diese Regeln gelten projekt- und werkzeugunabhängig; `CLAUDE.md` ergänzt werkzeugspezifische Hinweise für Claude Code.

Quellen der Wahrheit, in dieser Reihenfolge: [`docs/SPEC.md`](docs/SPEC.md) (fachliche Anforderungen) → [`ARCHITECTURE.md`](ARCHITECTURE.md) (Schnittstellen/Module) → [`decisions/`](decisions/) (Begründungen für Abweichungen vom naheliegenden Ansatz) → [`ROADMAP.md`](ROADMAP.md) (Reihenfolge/Abhängigkeiten) → `tasks/XXX-*.md` (konkreter Arbeitsauftrag).

## Grundregeln

1. **Server-autoritativ.** Der Client sendet ausschließlich Absichten (`ClientAction`), niemals Spielergebnisse oder Positionsdaten zur Validierung. Siehe `ARCHITECTURE.md` Abschnitt 1 und 6.
2. **Grid-first.** Spielentscheidungen (Zielkachel, Bombenkachel, Trefferprüfung) basieren auf `GridPosition`, nicht auf Welt-Floats (Spec §49). Ausnahme: der Sicherheitsabstand zur Bombe ist explizit eine Weltdistanz (Spec §22).
3. **Keine neuen RemoteEvents** ohne eine neue Datei unter `decisions/`, die das begründet, und ein entsprechendes Update von `ARCHITECTURE.md` Abschnitt 6. Neue Nachrichtenarten werden über neue `type`-Werte in `Net.ClientActionType`/`Net.GameEventType` ergänzt.
4. **Kein externes Gameplay-Framework** (z. B. Knit) ohne neue Decision-Datei (siehe [`decisions/004-no-external-framework.md`](decisions/004-no-external-framework.md)).
5. **Keine automatisierten Tests vorhanden** — bewusste Entscheidung ([`decisions/003-manual-testing-strategy.md`](decisions/003-manual-testing-strategy.md)). Die "Teststrategie" jeder Task-Datei ist eine manuelle Prüf-Checkliste in Roblox Studio. Diese **tatsächlich durchführen und das Ergebnis dokumentieren**, nicht nur Code abliefern und Erfolg behaupten.
6. **Nur den zugewiesenen Task bearbeiten.** Keine ungefragten Refactorings außerhalb des Task-Scopes, keine vorzeitige Implementierung von Backlog-Punkten (`ROADMAP.md`, Abschnitt "Backlog") — das wäre "Features auf Vorrat" und widerspricht der Projektstrategie.
7. **Bestehende Schnittstellen respektieren.** Funktionssignaturen aus `ARCHITECTURE.md` Abschnitt 7 nur bei begründetem technischem Bedarf ändern, und dann mit einer neuen Decision-Datei dokumentieren.
8. **Task-Datei nach Abschluss aktualisieren.** Jede `tasks/XXX-*.md`-Datei endet mit einem Abschnitt "Ergebnis", der nach Bearbeitung mit dem tatsächlichen Ergebnis, den durchgeführten Prüfungen und ggf. getroffenen neuen Architekturentscheidungen gefüllt wird (siehe auch `docs/002-TASK_PROMPT.md`, falls im Repo vorhanden — diese Regel dupliziert dessen Vorgabe absichtlich nicht im Detail, sondern referenziert sie).
9. **Keine Commits, Pushes oder Deployments ohne explizite Freigabe** des Nutzers.
10. **Konfiguration statt Magic Numbers.** Neue Spielparameter gehören in `GameConfig.luau`/`LevelConfig.luau`, nicht hartcodiert in Services/Controllern.

## Code-Konventionen

- Luau-Module: `PascalCase`-Dateinamen, `camelCase` für lokale Variablen.
- `--!strict` an den Dateianfang reiner Logik-Module (`src/shared/**`) setzen, wo praktikabel.
- Services/Controller sind einfache Tabellen mit Funktionen, verdrahtet über die in `ARCHITECTURE.md` Abschnitt 3 festgelegte Composition-Root-Reihenfolge — kein Dependency-Injection-Framework.
- Keine zirkulären `require`-Abhängigkeiten (siehe Abhängigkeitsrichtungen in `ARCHITECTURE.md` Abschnitt 7, z. B. `PlayerService`/`BombService`/`TargetService` requiren nicht `GameService`).
