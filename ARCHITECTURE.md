# ARCHITECTURE.md

Technische Gesamtarchitektur für das Bomben-Kreuzungs-Spiel (Roblox). Grundlage: [`docs/SPEC.md`](docs/SPEC.md). Entscheidungsbegründungen im Detail stehen in [`decisions/`](decisions/); dieses Dokument beschreibt den aktuellen Soll-Zustand der Architektur und die festgelegten Schnittstellen, auf die sich alle Tasks in [`tasks/`](tasks/) beziehen.

Dieses Dokument ist die **Quelle der Wahrheit** für Modulnamen, Pfade, Datentypen und Netzwerk-Contracts. Eine Task darf diese Schnittstellen nur ändern, wenn sie gleichzeitig eine neue Datei unter `decisions/` anlegt, die die Änderung begründet, und dieses Dokument entsprechend aktualisiert.

---

## 1. Grundprinzipien

1. **Server-autoritativ** (Spec §39): Der Client sendet ausschließlich *Absichten* (`ClientAction`), niemals Ergebnisse oder Positionen zur Validierung. Der Server entscheidet: Wo ist das Target? Ist die Bombe korrekt? Ist der Abstand ausreichend? Wie viele Punkte gibt es? Das gilt bereits im Singleplayer-MVP, weil es die spätere Multiplayer-Erweiterung (Spec §2, §40) ohne Umbau ermöglicht.
2. **Grid-first** (Spec §49): Alle Spielentscheidungen (Zielkachel, Bombenkachel, Trefferprüfung) basieren auf ganzzahligen Grid-Koordinaten (`GridPosition`), nie auf exakten Welt-Floats. Nur Distanzprüfungen, die die Spec explizit in Studs definiert (Sicherheitsabstand zur Bombe, §22), verwenden Weltkoordinaten.
3. **Keine Features auf Vorrat**: Es wird nur die Erweiterbarkeit gebaut, die aktuell benötigt wird (siehe `decisions/`). Multiplayer, Combo-System, Hardcore-Modus etc. werden nicht vorab implementiert, aber die Architektur blockiert sie auch nicht (siehe Abschnitt 7).
4. **Kein externes Gameplay-Framework** (siehe [`decisions/004-no-external-framework.md`](decisions/004-no-external-framework.md)): einfache Luau-Module, manueller Composition Root, kein Knit o. ä.
5. **Konfiguration statt Magic Numbers**: Alle Spielparameter liegen in `GameConfig.luau` / `LevelConfig.luau`, nie hartcodiert in Services.

---

## 2. Verzeichnisstruktur

Rojo mappt Verzeichnisse rekursiv (`default.project.json`); neue Unterordner unter `src/shared`, `src/server`, `src/client` benötigen **keine** Änderung an `default.project.json`.

```
src/shared/                              → ReplicatedStorage.Shared
  Config/
    GameConfig.luau                      -- globale, levelunabhängige Konstanten
    LevelConfig.luau                     -- Level-1..3-Tabelle + GetConfig(level)
  Types/
    GameTypes.luau                       -- gemeinsame Luau-Typen (siehe Abschnitt 4)
  Net/
    Net.luau                             -- RemoteEvent-Wrapper + Event-Namenskonstanten
  Util/
    GridMath.luau                        -- reine Grid↔World-Funktionen

src/server/                              → ServerScriptService.Server
  init.server.luau                       -- Composition Root
  Services/
    BoardService.luau
    PlayerService.luau
    TargetService.luau
    BombService.luau
    GameService.luau

src/client/                              → StarterPlayer.StarterPlayerScripts.Client
  init.client.luau                       -- Composition Root
  Controllers/
    GameClientController.luau
    InputController.luau
    EffectsController.luau
  UI/
    GameHudUI.luau
    MainMenuUI.luau
```

Es gibt **kein** `StarterGui`-Mapping. ScreenGuis werden zur Laufzeit per Code unter `Players.LocalPlayer.PlayerGui` erzeugt (siehe [`decisions/002-ui-code-generated.md`](decisions/002-ui-code-generated.md)).

`StarterPlayer`-Eigenschaften (First-Person-Zwang, Sprung deaktiviert) werden deklarativ in `default.project.json` gesetzt, nicht per Code (siehe Task 001).

---

## 3. Bootstrap-Reihenfolge

**Server** (`src/server/init.server.luau`) – `require` + `Init()` in dieser festen Reihenfolge:

```
BoardService → PlayerService → TargetService → BombService → GameService
```

Begründung: Jeder Service in der Kette nutzt Funktionen des/der vorherigen (`GameService` orchestriert alle vier; `BombService` braucht `BoardService.GetTileAtWorldPosition` und `TargetService.ValidateBombTile`; `PlayerService` braucht die Board-Grenzen für gültige Spawns).

**Client** (`src/client/init.client.luau`):

```
GameClientController → InputController → EffectsController
```

`GameClientController` muss zuerst stehen, weil `InputController` und `EffectsController` sich an dessen Signals hängen bzw. es `ClientAction`-Events über `Net` feuert. `GameHudUI` und `MainMenuUI` werden nicht im Bootstrap selbst gestartet, sondern lazy von `GameClientController` erzeugt/angezeigt, sobald der erste `GameEvent` eintrifft.

---

## 4. Zentrale Datenmodelle (`GameTypes.luau`)

```lua
export type GridPosition = { x: number, y: number }

export type GameStateName =
	"MENU" | "STARTING" | "TARGET_ACTIVE" | "BOMB_PLACED"
	| "EXPLODING" | "ROUND_RESULT" | "NEXT_TARGET" | "GAME_OVER"

export type TargetData = {
	id: number,
	center: GridPosition,
	left: GridPosition,
	right: GridPosition,
	top: GridPosition,
	bottom: GridPosition,
	color: Color3,
	spawnedAt: number,
	lifetime: number,
}

export type BombOutcome = "SUCCESS" | "MISS" | "HIT_BY_EXPLOSION"

export type PlayerSessionData = {
	lives: number,
	score: number,
	levelScore: number,
	level: number,
	state: GameStateName,
}

export type LevelConfigData = {
	Level: number,
	BoardSize: number,
	TargetLifetime: number,
	BombFuse: number,
	ScoreRequired: number,
	MinTargetDistance: number,
	MaxTargetDistance: number,
	Margin: number,
}
```

Diese Typen werden von Services und Controllern per `require(GameTypes)` importiert (reine Typdefinitionen, keine Laufzeitlogik).

---

## 5. Konfigurationswerte

### `GameConfig.luau` (levelunabhängig)

| Feld | Wert | Herkunft |
|---|---|---|
| `TileSize` | `6` | Spec §6 |
| `TileGap` | `0.1` | Spec §6 |
| `ObjectHeight` | `3.5` | Spec §12 |
| `ObjectDiameter` | `3` | Spec §11 |
| `DeathY` | `-50` | Spec §8 |
| `StartingLives` | `3` | Spec §26 |
| `SafeDistanceTiles` | `2` | Spec §22 (`SafeDistance = SafeDistanceTiles * TileSize`) |
| `MinSpawnDistanceFromTarget` | `4` | Spec §10 |
| `Scoring.BasePoints` | `100` | Spec §28 |
| `Scoring.TimeBonusPerSecond` | `10` | Spec §28 |
| `BombRecoilStuds` | `1.5` | Spec §19 ("kleiner Schritt zurück") |
| `ColorPalette` | Rot, Blau, Grün, Gelb, Orange, Pink, Türkis, Lila (keine zu dunklen Töne) | Spec §13 |

### `LevelConfig.luau` (`GetConfig(level): LevelConfigData`, clamt auf Level 3 für `level > 3`)

| Level | BoardSize | TargetLifetime | BombFuse | ScoreRequired | MinTargetDistance | MaxTargetDistance | Margin |
|---|---|---|---|---|---|---|---|
| 1 | 30 | 20 | 2 | 1000 | 3 | 5 | 1 |
| 2 | 30 | 18 | 2 | 1500 | 3 | 6 | 1 |
| 3 | 30 | 16 | 2 | 2000 | 3 | 7 | 1 |

Quelle: Spec §30–§32. `BoardSize` bleibt über alle MVP-Level konstant ([`decisions/007-board-size-fixed-per-session.md`](decisions/007-board-size-fixed-per-session.md)).

---

## 6. Networking

Genau **zwei** `RemoteEvent`-Instanzen unter `ReplicatedStorage.Remotes` (zur Laufzeit von `Net.EnsureRemotes()` server-seitig erzeugt, Client wartet per `WaitForChild`):

- **`ClientAction`** (Client → Server): `{ type: "RequestPlay" | "PlaceBomb" }`
- **`GameEvent`** (Server → Client): `{ type: "StateChanged" | "TargetSpawned" | "TargetCleared" | "BombPlaced" | "RoundResult" | "ScoreUpdated" | "GameOver", ... }`

Begründung für nur zwei generische Remotes statt der drei benannten Remotes aus Spec §35: [`decisions/001-remote-consolidation.md`](decisions/001-remote-consolidation.md). Neue Nachrichten werden über neue `type`-Werte hinzugefügt, nicht über neue `RemoteEvent`-Instanzen.

`Net.luau` exportiert die gültigen `type`-Strings als Konstanten (keine rohen Stringliterale in Services/Controllern), damit Client und Server nie auseinanderlaufen.

---

## 7. Service-Schnittstellen

### `BoardService`
- `CreateBoard(levelConfig: LevelConfigData): ()` — baut das Grid aus Tile-Parts (Grau, leichte Farbvariation, `TileGap`).
- `GridToWorld(pos: GridPosition): Vector3`
- `WorldToGrid(worldPos: Vector3): GridPosition`
- `IsValidTile(pos: GridPosition): boolean`
- `GetRandomTile(exclude: { GridPosition }?): GridPosition`
- `GetTileAtWorldPosition(worldPos: Vector3): GridPosition?` — für Bomben-Snap (Spec §19) und Spieler-Standort.

Erzeugt **nicht** die `DeathZone` (die ist ein statischer, in `default.project.json` deklarierter Part, siehe Task 001) und reagiert nicht auf sie — das macht `PlayerService`.

### `PlayerService`
- `SpawnPlayer(player: Player): ()` — platziert Charakter auf zufälliger gültiger Kachel (`BoardService.GetRandomTile`).
- `RespawnPlayer(player: Player): ()` — nach Fall-Tod, ebenfalls über `GetRandomTile`.
- Event `PlayerFell(player: Player)` — gefeuert, wenn `DeathZone.Touched` für diesen Spieler auslöst. `PlayerService` mutiert selbst **keine** Lives/Score, sondern meldet nur nach oben; `GameService` reagiert.

### `TargetService`
- `CreateTarget(levelConfig: LevelConfigData, playerPosition: GridPosition): TargetData` — wählt Mittelpunkt + 4 Offsets unter Beachtung von Rand-Margin (Spec §15), unterschiedlichen Abständen (Spec §16) und Mindestabstand zur aktuellen Spielerposition (Spec §46, [`decisions/006-spawn-before-target.md`](decisions/006-spawn-before-target.md)).
- `GetActiveTarget(): TargetData?`
- `ValidateBombTile(pos: GridPosition): boolean` — `pos == activeTarget.center`.
- `DestroyActiveTarget(): ()`
- Event `TargetExpired()` — nach Ablauf von `lifetime` ohne Bombenplatzierung.

### `BombService`
- `TryPlaceBomb(player: Player, levelConfig: LevelConfigData): boolean` — rein synchroner Rückgabewert: `true` bei erfolgreicher Platzierung, `false` wenn ignoriert (kein aktives Target, Spieler-Kachel ungültig, oder für dieses Target bereits eine Bombe platziert). Mutiert selbst **keine** Lives/Score — das macht `GameService`.
- Erzeugt das Gefahrenzonen-Weltvisual (Ring/markierte Kacheln, Radius `SafeDistanceTiles * TileSize`), siehe [`decisions/005-danger-zone-world-visual.md`](decisions/005-danger-zone-world-visual.md).
- Event `BombExploded(player: Player)` — gefeuert beim Ablauf der Fuse (`levelConfig.BombFuse`), vor der Validierung.
- Event `BombResolved(player: Player, outcome: BombOutcome)` — gefeuert direkt nach `BombExploded` mit dem validierten Ergebnis (Spec §24). Das asynchrone Ergebnis wird bewusst per Signal statt per Rückgabewert geliefert, siehe [`decisions/009-bomb-outcome-via-signal.md`](decisions/009-bomb-outcome-via-signal.md).

### `GameService`
- Hält `PlayerSessionData` pro Spieler und die State Machine (die 7+1 Zustände aus Spec §34).
- Verarbeitet `ClientAction`: `RequestPlay` → neue Session (Level 1, Score 0, 3 Leben), `PlaceBomb` → `BombService.TryPlaceBomb` (bei Erfolg State-Übergang nach `BOMB_PLACED`); reagiert auf `BombService.BombExploded`/`BombResolved` mit den Übergängen nach `EXPLODING`/`ROUND_RESULT`.
- Wendet Konsequenzen an: Score/Zeitbonus (Spec §28), Level-Aufstieg (Spec §30, [`decisions/007`](decisions/007-board-size-fixed-per-session.md)), Lebensverlust bei Timeout/MISS/HIT_BY_EXPLOSION/Fall (genau 1 Leben pro Vorfall, nie kumuliert, Spec §24), Game Over bei 0 Leben.
- Broadcastet `GameEvent` an den/die betroffenen Client(s).

### `GameClientController` (Client)
- Einziger `GameEvent`-Listener. Hält lokalen Spiegel von `PlayerSessionData` + aktuellem `TargetData`.
- Exponiert Signals: `StateChanged`, `TargetSpawned`, `TargetCleared`, `BombPlaced`, `RoundResult`, `ScoreUpdated`, `GameOver`. `GameHudUI`, `MainMenuUI` und `EffectsController` abonnieren diese, statt selbst `GameEvent.OnClientEvent` zu binden.

---

## 8. Spielzustände (Spec §34)

```
MENU → STARTING → TARGET_ACTIVE → BOMB_PLACED → EXPLODING → ROUND_RESULT → NEXT_TARGET → TARGET_ACTIVE → …
                                                                                  ↘ (0 Leben) GAME_OVER → MENU
```

- Der 20-Sekunden-Timer läuft **nur** im Zustand `TARGET_ACTIVE` (Spec §17). Sobald eine Bombe platziert wird, stoppt er (Übergang zu `BOMB_PLACED`).
- Ein Fall-Tod (`PlayerFell`) ändert den Zustand **nicht** — das aktive Target und sein Timer laufen weiter ([`decisions/008-fall-does-not-reset-target.md`](decisions/008-fall-does-not-reset-target.md)).

---

## 9. Bekannte zukünftige Anforderungen (nicht implementiert, Architektur blockiert sie aber nicht)

- **Multiplayer** (Spec §2, §40–42): `PlayerSessionData` ist bereits pro `Player` indiziert, nicht global — ein zweiter Spieler bräuchte keine Datenstruktur-Änderung, nur Erweiterung der Zuteilungslogik in `GameService`.
- **Combo-System** (Spec §29): `PlayerSessionData` könnte um `comboCount` erweitert werden, ohne bestehende Felder zu ändern.
- **Levels 4/5** (fehlende Kacheln, Ablenkobjekte, Spec §32): `LevelConfigData` kann um weitere Felder ergänzt werden; `BoardService`/`TargetService`-APIs ändern sich dafür nicht.
- **Hardcore-Modus** (Spec §52): wäre ein alternativer Konsequenz-Pfad in `GameService` (Game Over statt Lebensverlust), keine Strukturänderung.

## 10. Offene, bewusst nicht entschiedene Fragen (Spec §53)

- Müssen alle vier Kugeln jederzeit gleichzeitig im Sichtfeld liegen, oder reicht gute Erkennbarkeit beim Umschauen? → Playtest-Entscheidung, keine Architekturauswirkung.
- Gemeinsames vs. individuelles Multiplayer-Target? → Wird erst bei der Multiplayer-Erweiterung (Backlog) entschieden; `TargetService` hält aktuell bewusst nur **ein** aktives Target (kein Array), siehe [`decisions/003`](decisions/003-manual-testing-strategy.md) Kontext und ROADMAP-Backlog-Eintrag 017.

## 11. Teststrategie (projektweit)

Es gibt **keinen** automatisierten Test-Runner (Nutzerentscheidung, [`decisions/003-manual-testing-strategy.md`](decisions/003-manual-testing-strategy.md)). Jede Task in `tasks/` definiert eine konkrete, manuell in Roblox Studio durchzuführende Prüf-Checkliste statt eines Testbefehls. Reine Logik-Module (`GridMath`, Teile von `TargetService`) sind bewusst ohne Roblox-API-Abhängigkeiten geschrieben, damit sie bei Bedarf später leicht automatisiert testbar wären — das wird aber aktuell nicht eingerichtet.
