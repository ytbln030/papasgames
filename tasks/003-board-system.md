# Task 003 — Board System

## Ziel und erwartetes Verhalten

`BoardService` erzeugt serverseitig das begehbare, schwebende Kachelfeld und stellt Grid↔World-Konvertierung sowie Kachel-Lookups für alle anderen Services bereit. Nach diesem Task ist in Studio ein begehbares 30×30-Kachelfeld sichtbar, auf dem ein Spieler laufen kann, ohne dass bereits Zielobjekte, Bomben oder Game-States existieren.

## Voraussetzungen und Abhängigkeiten

- [Task 002](002-shared-foundations.md) (`GameConfig`, `GameTypes`, `GridMath`) muss abgeschlossen sein.
- [Task 001](001-world-and-starterplayer-baseline.md) sollte abgeschlossen sein (kein alter Baseplate mehr im Weg), ist aber kein Hard-Blocker für den Code selbst.

Kann parallel zu [Task 004](004-player-spawn-and-safety.md) bearbeitet werden (unterschiedliche Dateien).

## Betroffene Module

- `src/server/Services/BoardService.luau` (neu)

## Funktionale Anforderungen

1. `BoardService.CreateBoard(levelConfig: LevelConfigData): ()` erzeugt unter `Workspace` ein Modell/Folder `Board` mit `levelConfig.BoardSize × levelConfig.BoardSize` quadratischen, flachen, begehbaren `Part`-Instanzen (`Anchored = true`, Collision aktiv).
2. Kachelgröße = `GameConfig.TileSize`, optischer Zwischenraum = `GameConfig.TileGap` (Spec §6) — Kacheln besitzen **keinen funktionalen** Abstand (keine Lücken für Kollisionszwecke), der Gap ist rein visuell (z. B. durch geringfügig verkleinerte Part-Size).
3. Grundfarbe Grau/Silber mit sehr subtiler Variation zwischen Kacheln (Spec §7, Beispielwerte RGB 120–132 je Kanal) — Variation darf den Kontrast zu den (später erscheinenden) farbigen Kugeln nicht beeinträchtigen.
4. `BoardService.GridToWorld(pos: GridPosition): Vector3` und `BoardService.WorldToGrid(worldPos: Vector3): GridPosition` nutzen intern `GridMath` mit dem Board-Ursprung als Parameter.
5. `BoardService.IsValidTile(pos: GridPosition): boolean` prüft Grenzen gegen die aktuell aktive `BoardSize`.
6. `BoardService.GetRandomTile(exclude: { GridPosition }?): GridPosition` liefert eine zufällige gültige Kachel, die nicht in `exclude` enthalten ist (für Spawn/Respawn, Task 004).
7. `BoardService.GetTileAtWorldPosition(worldPos: Vector3): GridPosition?` liefert die Kachel, über der sich eine Weltposition befindet, oder `nil`, falls außerhalb des Boards (wird in Task 004 für "Kachel unter Spieler" und in Task 007 für Bomben-Snap verwendet, Spec §19).

## Technische Vorgaben und Schnittstellen

- Board wird exakt einmal pro Session erzeugt (aufgerufen von `GameService` in Task 006); `CreateBoard` muss idempotent mit vorherigem Zustand umgehen (vorhandenes `Workspace.Board` vor Neuaufbau entfernen), auch wenn dieser Fall im MVP nicht beim Levelwechsel auftritt (siehe [`decisions/007`](../decisions/007-board-size-fixed-per-session.md) — Board bleibt pro Session fix, `CreateBoard` wird dennoch robust gegen Mehrfachaufruf geschrieben).
- Jede Kachel speichert ihre Grid-Koordinaten (z. B. als `Attribute`en `GridX`/`GridY` auf dem Part), damit `GetTileAtWorldPosition` nicht auf Fließkomma-Rückrechnung angewiesen ist, sondern per Raycast/Touched-Lookup die getroffene Part-Instanz direkt auslesen kann. Die konkrete Lookup-Implementierung (Raycast nach unten ab Spielerposition vs. direkte `WorldToGrid`-Rundung) liegt im Ermessen der Umsetzung, muss aber mit `IsValidTile` konsistent sein.
- Keine Abhängigkeit von `Players`/`Humanoid` in diesem Modul — reine Board-Verwaltung.

## Bekannte zukünftige Anforderungen

- Levels mit anderer `BoardSize` (Spec §5) — API nimmt bereits `levelConfig` entgegen, keine Signaturänderung nötig für zukünftige Boardgrößen (auch wenn im MVP nicht genutzt, siehe Decision 007).
- Level 4/5 (fehlende Kacheln, Backlog 016) — würde `IsValidTile`/`GetRandomTile` erweitern, nicht ersetzen.

## Out of Scope

- `DeathZone`-Reaktion (Task 001/004).
- Zielobjekte/Kugeln (Task 005).
- Multiplayer-Mehrfachboards.

## Akzeptanzkriterien

1. Nach `BoardService.CreateBoard(LevelConfig.GetConfig(1))` sind genau 900 begehbare Kachel-Parts in `Workspace.Board` sichtbar.
2. Ein Spieler kann über das gesamte Feld laufen, ohne durchzufallen; außerhalb des Feldes gibt es keine Collision.
3. `GetTileAtWorldPosition` liefert für eine Position exakt über dem Mittelpunkt einer bekannten Kachel genau deren `GridPosition`, und `nil` für eine Position klar außerhalb des Boards.
4. `GetRandomTile()` liefert wiederholt aufgerufen stets gültige, innerhalb des Boards liegende Koordinaten; mit `exclude` werden die ausgeschlossenen Koordinaten nie zurückgegeben (über mehrere Aufrufe stichprobenhaft verifiziert).
5. Benachbarte Kacheln zeigen eine sichtbare, aber subtile Grautonvariation.

## Teststrategie (manuell in Roblox Studio)

1. In der Server-Command-Bar `BoardService.CreateBoard(LevelConfig.GetConfig(1))` aufrufen, `Workspace.Board:GetChildren()` zählen (muss 900 sein).
2. Play-Test: Charakter auf das Feld teleportieren, in alle vier Richtungen laufen, Kante erreichen und beobachten, dass er dort herunterfällt (bis zur `DeathZone`, Task 001).
3. `BoardService.GetTileAtWorldPosition(player.Character.PrimaryPart.Position)` während des Stehens auf einer bekannten Kachel aufrufen und Ergebnis gegen die visuell erkennbare Kachel abgleichen.
4. `GetRandomTile()` zehnmal aufrufen und alle Ergebnisse gegen `IsValidTile` prüfen.
5. Screenshot des Boards zur Dokumentation der Grautonvariation anfertigen.
6. Ergebnis dokumentieren.

## Definition of Done

- `BoardService.luau` implementiert mit allen oben genannten Funktionen.
- Alle Akzeptanzkriterien manuell verifiziert und dokumentiert.
- Keine Abhängigkeit auf noch nicht existierende Module außer denen aus Task 002.

---

## Ergebnis (von der ausführenden Task-Session auszufüllen)

_Noch nicht ausgeführt._
