# 001 — Zwei generische RemoteEvents statt drei benannter Remotes

## Kontext

`docs/SPEC.md` §35 schlägt unter "Empfohlene grobe Architektur" drei Remotes vor: `PlaceBomb`, `GameStateUpdate`, `TargetUpdate`. Die Spheren eines Targets sind jedoch normale, serverseitig erzeugte `Part`-Instanzen in `Workspace` und werden durch die Roblox-Replikation automatisch an alle Clients übertragen — dafür ist kein eigenes Remote nötig. Übrig bleiben zwei Kommunikationsrichtungen: Client-Absichten (Bombe platzieren, Spiel starten) und Server-Broadcasts für HUD/Menü-Zustand.

## Entscheidung

Es werden genau zwei `RemoteEvent`-Instanzen verwendet:
- `ClientAction` (Client → Server): `{ type: "RequestPlay" | "PlaceBomb" }`
- `GameEvent` (Server → Client): `{ type: "StateChanged" | "TargetSpawned" | "TargetCleared" | "BombPlaced" | "RoundResult" | "ScoreUpdated" | "GameOver", ... }`

Neue Nachrichtenarten werden über neue `type`-Werte ergänzt, nicht über neue `RemoteEvent`-Instanzen.

## Begründung

- §35 ist explizit als "Beispiel"/"empfohlene grobe Architektur" markiert, kein verbindliches Interface.
- Weniger Instanzen = weniger Boilerplate beim Erzeugen/Warten (`WaitForChild`) und weniger Stellen, an denen Client/Server auseinanderlaufen können.
- Ein typisiertes `type`-Feld erlaubt beliebig viele zukünftige Ereignisse (Combo-Update, Multiplayer-Scoreboard, …) ohne neue Instanzen und ohne Änderung an `default.project.json`.

## Konsequenz

- `Net.luau` ist die einzige Stelle, die die gültigen `type`-Strings kennt (als Konstanten exportiert).
- Agenten dürfen keine zusätzlichen `RemoteEvent`/`RemoteFunction`-Instanzen anlegen, ohne diese Entscheidung zu revidieren (neue Decision-Datei + Update von `ARCHITECTURE.md` Abschnitt 6).
