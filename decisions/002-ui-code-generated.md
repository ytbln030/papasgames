# 002 — UI wird vollständig per Code erzeugt

## Kontext

Für Startscreen und HUD (`docs/SPEC.md` §4, §27) muss entschieden werden, ob die UI in Roblox Studio visuell gebaut und per Rojo `$path` referenziert wird, oder vollständig programmatisch (`Instance.new(...)`) entsteht. Diese Entscheidung wurde explizit mit dem Nutzer abgestimmt (Planungsphase, AskUserQuestion).

## Entscheidung

Alle UI-Elemente (`GameHudUI.luau`, `MainMenuUI.luau`) werden zur Laufzeit per Luau-Code unter `Players.LocalPlayer.PlayerGui` erzeugt. Es gibt kein `StarterGui`-Rojo-Mapping.

## Begründung

- Vollständig text-/diff-basiert versionierbar und für KI-Coding-Agenten ohne Studio-GUI editierbar.
- Konsistent mit dem Rest des Codes (ein einziger Workflow: Code schreiben, per Rojo syncen).
- Kein Verlust an Funktionalität für die im MVP benötigten, bewusst einfachen UI-Elemente (Topbar, Start-/Game-Over-Screen).

## Konsequenz

- Kein `StarterGui`-Eintrag in `default.project.json`.
- Spätere, visuell aufwändigere UI (falls gewünscht) müsste diese Entscheidung explizit revidieren.
