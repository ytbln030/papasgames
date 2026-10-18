# 003 — Manuelle Teststrategie statt automatisiertem Headless-Testing

## Kontext

Für reine Spiellogik (Grid-Mathematik, Kreuz-Generierung, Validierung) wäre ein headless Test-Runner wie Lune (plus Selene/StyLua) technisch möglich und würde KI-Agenten erlauben, ihre Arbeit automatisiert gegen sich selbst zu verifizieren. Diese Option wurde dem Nutzer in der Planungsphase vorgelegt (AskUserQuestion).

## Entscheidung

Es wird **kein** automatisierter Test-Runner eingerichtet. Der Nutzer hat sich explizit für "Nur manuelle Prüfung in Studio" entschieden. `rokit.toml` bleibt unverändert (nur `rojo`).

## Begründung

Nutzerentscheidung. Einfacherer Start, kein zusätzliches Tooling im Projekt.

## Konsequenz

- Jede Task-Datei unter `tasks/` definiert statt eines automatisierten Tests eine konkrete, Schritt-für-Schritt nachvollziehbare manuelle Prüf-Checkliste in Roblox Studio (Teststrategie-Feld).
- Agenten müssen diese Checkliste **tatsächlich durchführen** (z. B. über die in dieser Umgebung verfügbaren Roblox-Studio-MCP-Tools, siehe `CLAUDE.md`) und das Ergebnis in der Task-Datei dokumentieren, nicht nur den Code als "sollte funktionieren" abliefern.
- Reine Logik-Module (`GridMath.luau`, Teile von `TargetService.luau`) werden trotzdem bewusst ohne Roblox-API-Abhängigkeiten geschrieben (pure functions), damit eine spätere Einführung automatisierter Tests ohne Rewrite möglich bliebe — das ist aber aktuell nicht eingerichtet und kein Implementierungsziel.
