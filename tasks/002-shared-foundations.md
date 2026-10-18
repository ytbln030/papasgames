# Task 002 — Shared Foundations

## Ziel und erwartetes Verhalten

Alle gemeinsamen, Roblox-API-freien Bausteine werden angelegt, auf die praktisch jede weitere Task aufbaut: Konfigurationswerte, gemeinsame Typen, Grid-Mathematik und der Netzwerk-Contract (noch ohne tatsächliche Consumer). Nach diesem Task kann kein Spiellogik-Code geschrieben werden, der nicht auf diese Module zurückgreift.

## Voraussetzungen und Abhängigkeiten

Keine. Kann parallel zu [Task 001](001-world-and-starterplayer-baseline.md) bearbeitet werden.

Vollständige Spezifikation der Werte und Typen: [`ARCHITECTURE.md`](../ARCHITECTURE.md) Abschnitte 4–6.

## Betroffene Module

- `src/shared/Config/GameConfig.luau` (neu)
- `src/shared/Config/LevelConfig.luau` (neu)
- `src/shared/Types/GameTypes.luau` (neu)
- `src/shared/Util/GridMath.luau` (neu)
- `src/shared/Net/Net.luau` (neu)
- `src/shared/Hello.luau` kann entfernt werden (Platzhalter-Datei aus dem Rojo-Default-Template, keine Verwendung).

## Funktionale Anforderungen

### `GameTypes.luau`
Exportiert exakt die in [`ARCHITECTURE.md`](../ARCHITECTURE.md) Abschnitt 4 definierten Typen (`GridPosition`, `GameStateName`, `TargetData`, `BombOutcome`, `PlayerSessionData`, `LevelConfigData`) per `export type`. Keine Laufzeitlogik, `return {}` als Modulrückgabe reicht.

### `GameConfig.luau`
Liefert eine Tabelle mit exakt den in [`ARCHITECTURE.md`](../ARCHITECTURE.md) Abschnitt 5 gelisteten Feldern (`TileSize`, `TileGap`, `ObjectHeight`, `ObjectDiameter`, `DeathY`, `StartingLives`, `SafeDistanceTiles`, `MinSpawnDistanceFromTarget`, `Scoring = { BasePoints, TimeBonusPerSecond }`, `BombRecoilStuds`, `ColorPalette`). `ColorPalette` ist eine Liste von `Color3`-Werten (Rot, Blau, Grün, Gelb, Orange, Pink, Türkis, Lila — keine zu dunklen Töne, Spec §13).

### `LevelConfig.luau`
Enthält die Tabelle für Level 1–3 exakt wie in [`ARCHITECTURE.md`](../ARCHITECTURE.md) Abschnitt 5 spezifiziert, plus eine Funktion `GetConfig(level: number): LevelConfigData`, die für `level > 3` die Konfiguration von Level 3 zurückgibt (Clamp, keine Exception) und für `level < 1` einen Fehler wirft (defensive Programmierung gegen Aufrufer-Bugs).

### `GridMath.luau`
Reine Funktionen ohne Roblox-Instanzen:
- `GridToWorld(pos: GridPosition, tileSize: number, boardOrigin: Vector3): Vector3`
- `WorldToGrid(worldPos: Vector3, tileSize: number, boardOrigin: Vector3): GridPosition`
- `IsWithinBoard(pos: GridPosition, boardSize: number): boolean`
- `GridDistance(a: GridPosition, b: GridPosition): number` (Chebyshev- oder euklidische Distanz in Kacheln — Chebyshev wählen, da sie am Grid orientiert ist; Begründung als Kommentar im Modul).

### `Net.luau`
- Exportiert Konstanten-Tabellen `ClientActionType` und `GameEventType` mit den in [`ARCHITECTURE.md`](../ARCHITECTURE.md) Abschnitt 6 gelisteten String-Werten (z. B. `Net.ClientActionType.RequestPlay = "RequestPlay"`).
- `Net.EnsureRemotes(): ()` — nur auf dem Server aufrufbar; legt (falls nicht vorhanden) unter `ReplicatedStorage.Remotes` die zwei `RemoteEvent`-Instanzen `ClientAction` und `GameEvent` an.
- `Net.WaitForRemotes(): (RemoteEvent, RemoteEvent)` — client- und serverseitig nutzbar; wartet per `WaitForChild` auf beide Remotes und gibt sie zurück.
- In diesem Task werden die Remotes nur bereitgestellt, **nicht** gefeuert oder abgehört (das passiert in Task 006).

## Technische Vorgaben und Schnittstellen

- Alle Module in `src/shared/` sind reine Luau-Module (`return <table>`), keine Scripts.
- Wo sinnvoll `--!strict` am Dateianfang.
- Keine zirkulären `require`-Abhängigkeiten zwischen den fünf Modulen (`Net` darf `GameTypes` requiren, nicht umgekehrt; `LevelConfig`/`GameConfig` requiren nichts weiter).

## Bekannte zukünftige Anforderungen

- Weitere `GameEventType`/`ClientActionType`-Werte werden in späteren Tasks (006–012) ergänzt, nicht neu strukturiert.
- `LevelConfigData` könnte für Backlog-Task 016 um weitere Felder erweitert werden — `GetConfig` muss dafür nicht umgebaut werden.

## Out of Scope

- Tatsächliches Feuern/Abhören der Remotes.
- Erzeugung irgendwelcher Workspace-Instanzen (Board, Kugeln, Bombe).
- Automatisierte Tests (siehe [`decisions/003-manual-testing-strategy.md`](../decisions/003-manual-testing-strategy.md)).

## Akzeptanzkriterien

1. `require(GameConfig)`, `require(LevelConfig)`, `require(GameTypes)`, `require(GridMath)`, `require(Net)` laden jeweils fehlerfrei in der Studio-Command-Bar.
2. `LevelConfig.GetConfig(1)`, `GetConfig(2)`, `GetConfig(3)` liefern exakt die in `ARCHITECTURE.md` tabellierten Werte; `GetConfig(5)` liefert dieselben Werte wie `GetConfig(3)`.
3. `GridMath.GridToWorld({x=1,y=1}, 6, Vector3.new(0,0,0))` und die dazu inverse `WorldToGrid`-Anwendung ergeben wieder `{x=1,y=1}`.
4. `Net.EnsureRemotes()` auf dem Server erzeugt genau zwei `RemoteEvent`-Instanzen unter `ReplicatedStorage.Remotes` mit den Namen `ClientAction` und `GameEvent`; ein zweiter Aufruf erzeugt keine Duplikate.

## Teststrategie (manuell in Roblox Studio)

1. Nach Rojo-Sync alle fünf Module einzeln per `require(...)` in der Server-Command-Bar laden und auf Fehlerfreiheit prüfen.
2. `print(LevelConfig.GetConfig(1))`, `print(LevelConfig.GetConfig(5))` ausführen und Werte gegen die Tabelle in `ARCHITECTURE.md` manuell abgleichen.
3. `GridMath`-Hin- und Rückkonvertierung mit mehreren Beispielkoordinaten in der Command-Bar testen.
4. `Net.EnsureRemotes()` einmal und ein zweites Mal aufrufen, `ReplicatedStorage.Remotes:GetChildren()` prüfen (genau 2 Einträge, keine Duplikate).
5. Ergebnis dokumentieren.

## Definition of Done

- Alle fünf Module vorhanden, laden fehlerfrei, Werte stimmen mit `ARCHITECTURE.md` überein.
- `Hello.luau` entfernt oder durch reale Module ersetzt.
- Akzeptanzkriterien manuell verifiziert und dokumentiert.

---

## Ergebnis (von der ausführenden Task-Session auszufüllen)

_Noch nicht ausgeführt._
