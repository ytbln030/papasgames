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

**Status: Abgeschlossen.** Alle Akzeptanzkriterien manuell über die Roblox-Studio-MCP-Tools (verbundene Instanz „Papas game“, `rojo serve` + Live-Sync) tatsächlich verifiziert, siehe Prüfprotokoll unten.

### Durchgeführte Änderungen

- [`src/server/Services/BoardService.luau`](../src/server/Services/BoardService.luau) (neu): `CreateBoard`, `GridToWorld`, `WorldToGrid`, `IsValidTile`, `GetRandomTile`, `GetTileAtWorldPosition` wie spezifiziert implementiert.
  - Board wird um den Weltursprung zentriert (`boardOrigin` abhängig von `BoardSize`/`TileSize`), damit die Methode unabhängig von zukünftigen `BoardSize`-Werten funktioniert (Decision 007).
  - `GridToWorld` liefert die begehbare Kachel-Oberfläche (Top-Surface), nicht den Part-Mittelpunkt, als sinnvolle Platzierungsreferenz für spätere Tasks (Spawn, Bomben-Snap).
  - Kachel-Dicke (`TILE_THICKNESS = 1`) ist ein reines Darstellungsdetail ohne Spec-Vorgabe und daher als lokale Konstante im Service belassen, nicht in `GameConfig` (Spec/Architecture nennen keinen Höhenparameter).
  - `GetTileAtWorldPosition` nutzt `WorldToGrid` + `IsValidTile` (keine Raycast-Implementierung) — `GridMath.WorldToGrid` ignoriert die Y-Komponente ohnehin, wodurch die Methode unabhängig von der Spieler-Y-Position korrekt funktioniert und per Konstruktion konsistent mit `IsValidTile` ist. Die laut Task optionale Raycast-Variante war damit nicht nötig.
  - `GridX`/`GridY`-Attribute werden trotzdem auf jedem Tile-Part gesetzt (Technische Vorgabe), auch wenn die eigene Lookup-Implementierung sie nicht benötigt — für Debug-Zwecke/zukünftige Services.
  - `CreateBoard` entfernt ein vorhandenes `Workspace.Board` zu Beginn (Idempotenz bei Mehrfachaufruf).

### Durchgeführte Prüfungen

1. **AC1 (900 Kacheln):** `BoardService.CreateBoard(LevelConfig.GetConfig(1))` per `execute_luau` (Edit-Datamodel) aufgerufen; `Workspace.Board:GetChildren()` ergab exakt 900 Parts. Zweiter `CreateBoard`-Aufruf (Idempotenz-Test) ergab weiterhin exakt 900 (keine Duplikate).
2. **Kachel-Eigenschaften:** `Tile_1_1`, `Tile_15_15`, `Tile_30_30` per `execute_luau` inspiziert: `Anchored = true`, `CanCollide = true`, `Size ≈ (5.9, 1, 5.9)` (TileSize 6 − Gap 0.1, rein visueller Zwischenraum), `GridX`/`GridY`-Attribute korrekt gesetzt, Positionen symmetrisch um den Ursprung (`(-87,0,-87)` … `(87,0,87)`).
3. **AC5 (Grauton-Variation):** Farbwerte der drei inspizierten Kacheln lagen bei RGB (126/130/126), (125/121/130), (120/129/122) — innerhalb des Spec-Beispielbereichs 120–132 je Kanal, sichtbar aber subtil unterschiedlich. Per Screenshot (Top-Down, 220 Studs Höhe) zusätzlich das durchgängige 30×30-Raster inkl. sichtbarer, rein optischer Gap-Linien dokumentiert; feine Grauton-Unterschiede sind in der vorhandenen Dusk-Beleuchtung der Szene (`Lighting.ClockTime = 18.5`, unverändert seit Task 001, nicht Teil dieses Task-Scopes) im Screenshot kaum erkennbar, numerisch aber eindeutig nachgewiesen (vorheriger Punkt).
4. **AC3 (`GetTileAtWorldPosition`):** `GetTileAtWorldPosition(GridToWorld({x=15,y=15}))` ergab `{x=15,y=15}`; auch mit einer um +3 Studs erhöhten Y-Koordinate (Simulation einer Spieler-Fußposition über der Kachel) weiterhin `{x=15,y=15}` (Y wird korrekt ignoriert). Für eine klar außerhalb liegende Position (`(1000, 50, 1000)`) lieferte die Funktion `nil`. Zusätzlich `IsValidTile` an den Grenzen geprüft: `(1,1)`/`(30,30)` gültig, `(0,15)`/`(31,15)` ungültig.
5. **AC4 (`GetRandomTile`):** 200 Aufrufe mit `exclude = {(10,10),(11,11),(12,12)}` — alle Ergebnisse über `IsValidTile` als gültig bestätigt, keines der 200 Ergebnisse traf eine ausgeschlossene Koordinate.
6. **AC2 (Begehbarkeit/Fallverhalten) — Play-Test:** Play-Session gestartet (Server-Datamodel neu, daher `CreateBoard` dort erneut aufgerufen, um den Modul-internen `boardOrigin`/`BoardSize`-Zustand dieser Server-VM zu initialisieren — Board-Instanzen blieben aus dem Edit-Modus erhalten und wurden lediglich idempotent neu erzeugt). Charakter per `HumanoidRootPart.CFrame` auf Kachel (15,15) teleportiert: Charakter landete stabil auf der Oberfläche (`Position.Y ≈ 3.998`, keine Durchfall-Bewegung). Anschließend auf eine Position außerhalb des Feldes (Grid-X 40 bei `BoardSize = 30`) teleportiert: Charakter fiel innerhalb 1 Sekunde von `Y = 5.5` auf `Y ≈ -59.4` (ungebremst, keine Collision außerhalb des Boards) — konsistent mit dem Fallverhalten bis zur `DeathZone` bei `DeathY = -50` (Reaktion selbst ist Task 004).
7. **Konsole:** `get_console_output` nach dem Play-Test geprüft — keine Fehler oder Warnungen im Zusammenhang mit `BoardService` oder `Workspace.Board`; vorhandene Meldungen (UIBlox-`FoundationProvider`-Warnung, ein fehlgeschlagener `rbxassetid`-Content-Load) sind unabhängiges Engine-/CoreGui-Rauschen.
8. Der während der Prüfung per Command-Bar erzeugte `Workspace.Board` wurde nach Abschluss der Tests wieder aus dem Edit-Modus-Zustand entfernt (kein Teil des versionierten Projekts/Rojo-Baums; reine Laufzeit-Erzeugung durch `CreateBoard`, analog zum in Task 001 dokumentierten Umgang mit Sitzungszustand).

### Neue Architekturentscheidungen

Keine. Die Implementierung folgt den in `tasks/003-board-system.md` und `ARCHITECTURE.md` Abschnitt 7 festgelegten Schnittstellen ohne Abweichung.

### Auswirkungen auf spätere Tasks

- Task 004 (`PlayerService`) kann `BoardService.GetRandomTile`/`GetTileAtWorldPosition`/`GridToWorld` wie spezifiziert nutzen; `GridToWorld` liefert direkt die Spawn-Oberfläche (keine zusätzliche Y-Korrektur nötig).
- Task 006 (`GameService`/Composition Root) muss `BoardService.CreateBoard(LevelConfig.GetConfig(1))` einmalig beim `RequestPlay`-Handling aufrufen — ohne diesen Aufruf bleibt der interne Modul-Zustand (`boardOrigin`/`currentBoardSize`) der jeweiligen Server-Lua-VM uninitialisiert (siehe Prüfung 6: Play-Modus startet eine neue Server-VM, in der `require`-Zustand aus dem Edit-Modus nicht erhalten bleibt).
- Task 007 (Bomben-Snap) kann `GetTileAtWorldPosition` direkt verwenden; die Y-Unabhängigkeit der Implementierung ist dafür hilfreich (Bombe muss nicht exakt auf Kachelhöhe liegen).
