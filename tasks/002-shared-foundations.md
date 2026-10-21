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

**Status: Abgeschlossen.** Alle fünf Module angelegt, `Hello.luau` entfernt, Akzeptanzkriterien manuell in einer laufenden Roblox-Studio-Session (verbunden über `rojo serve` + Rojo-Plugin, Live-Sync aktiv) verifiziert, siehe Prüfprotokoll unten.

### Durchgeführte Änderungen

- [`src/shared/Types/GameTypes.luau`](../src/shared/Types/GameTypes.luau): exportiert `GridPosition`, `GameStateName`, `TargetData`, `BombOutcome`, `PlayerSessionData`, `LevelConfigData` exakt wie `ARCHITECTURE.md` Abschnitt 4, keine Laufzeitlogik, `return {}`.
- [`src/shared/Config/GameConfig.luau`](../src/shared/Config/GameConfig.luau): alle Felder aus Abschnitt 5 (`TileSize`, `TileGap`, `ObjectHeight`, `ObjectDiameter`, `DeathY`, `StartingLives`, `SafeDistanceTiles`, `MinSpawnDistanceFromTarget`, `Scoring.BasePoints`/`TimeBonusPerSecond`, `BombRecoilStuds`, `ColorPalette`). `ColorPalette` enthält 8 helle `Color3`-Werte (Rot, Blau, Grün, Gelb, Orange, Pink, Türkis, Lila), keine zu dunklen Töne.
- [`src/shared/Config/LevelConfig.luau`](../src/shared/Config/LevelConfig.luau): Level-1..3-Tabelle exakt wie in Abschnitt 5 tabelliert, plus `GetConfig(level)` mit Clamp auf Level 3 für `level > 3` und `error(...)` für `level < 1`. Requiert bewusst **nicht** `GameTypes` (Vorgabe aus dem Task: "LevelConfig/GameConfig requiren nichts weiter") — die Rückgabeform entspricht strukturell `GameTypes.LevelConfigData`, per Kommentar im Modul dokumentiert.
- [`src/shared/Util/GridMath.luau`](../src/shared/Util/GridMath.luau): `GridToWorld`, `WorldToGrid`, `IsWithinBoard`, `GridDistance` (Chebyshev, Begründung als Kommentar im Modul). Requiert `GameTypes` nur für den `GridPosition`-Typ (kein Zyklus, da `GameTypes` selbst nichts requiert).
- [`src/shared/Net/Net.luau`](../src/shared/Net/Net.luau): `ClientActionType`/`GameEventType`-Konstanten exakt wie `ARCHITECTURE.md` Abschnitt 6. `EnsureRemotes()` legt `ReplicatedStorage.Remotes.ClientAction`/`GameEvent` idempotent an; `WaitForRemotes()` wartet per `WaitForChild` und gibt beide zurück. Server-Guard in `EnsureRemotes` prüft `RunService:IsServer()` nur, wenn `RunService:IsRunning()` wahr ist (siehe Befund unten) — so bleibt die Funktion sowohl im Studio-Edit-Modus (Command-Bar) als auch während einer echten Play-Session auf dem Client korrekt gesperrt.
- [`src/shared/Hello.luau`](../src/shared/Hello.luau): entfernt (Platzhalter aus dem Rojo-Default-Template).

### Durchgeführte Prüfungen

1. **Statische Prüfung:** `rojo build default.project.json -o ...rbxlx` terminiert ohne Fehler (valides Projekt nach Entfernen von `Hello.luau` und Hinzufügen der fünf neuen Module).
2. **AC1 (fehlerfreies Laden):** Alle fünf Module per `require(...)` in der Studio-Command-Bar (Edit-Datamodel, `execute_luau`) geladen — keine Fehler, `GameConfig.TileSize == 6` als Smoke-Test bestätigt.
3. **AC2 (`LevelConfig.GetConfig`):** `GetConfig(1)`, `GetConfig(2)`, `GetConfig(3)`, `GetConfig(5)` ausgeführt und gegen die Tabelle in `ARCHITECTURE.md` abgeglichen — alle Felder (`BoardSize`, `TargetLifetime`, `BombFuse`, `ScoreRequired`, `MinTargetDistance`, `MaxTargetDistance`, `Margin`) stimmen exakt überein; `GetConfig(5)` ist feldweise identisch zu `GetConfig(3)` (bestätigt per Vergleich). `GetConfig(0)` wirft wie vorgesehen einen Fehler (`pcall` bestätigt `ok == false`).
4. **AC3 (`GridMath` Hin-/Rückkonvertierung):** `GridToWorld`/`WorldToGrid` für mehrere Beispielkoordinaten getestet, u. a. das in den Akzeptanzkriterien genannte `{x=1,y=1}` mit `tileSize=6`, `boardOrigin=(0,0,0)` → `world=(6,0,6)` → zurück `{x=1,y=1}` (Match). Zusätzlich mit weiteren Koordinaten (`{5,3}`, `{10,10}`, `{15,1}`) und einem nicht-trivialen `boardOrigin=(100,0,-50)` getestet — alle Rückkonvertierungen exakt. `IsWithinBoard` für Rand- und Außerhalb-Fälle (`{1,1}`/`{30,30}` → true, `{0,1}`/`{31,1}` → false bei `boardSize=30`) und `GridDistance` (Chebyshev: `{0,0}→{3,4}` = 4, identische Position = 0) verifiziert.
5. **AC4 (`Net.EnsureRemotes` Idempotenz):** Getestet in einer echten Play-Session (`start_stop_play`) im `Server`-Datamodel, da `RunService:IsServer()` im reinen Studio-Edit-Modus (Command-Bar ohne laufendes Spiel) stets `false` zurückgibt (Studio-Eigenheit, siehe Befund unten) — mit laufendem Play ist `IsServer()=true`, `IsRunning()=true` wie erwartet. Erster Aufruf erzeugt `ReplicatedStorage.Remotes` mit genau zwei `RemoteEvent`-Kindern (`ClientAction`, `GameEvent`); zweiter Aufruf erzeugt keine Duplikate (`#GetChildren() == 2` nach beiden Aufrufen, gleiche Ordner-Instanz). `Net.WaitForRemotes()` liefert serverseitig und clientseitig (separat im `Client`-Datamodel getestet) dieselben zwei Remotes zurück. Nach Stoppen des Play-Tests ist `ReplicatedStorage.Remotes` im Edit-Modus wieder nicht vorhanden (Play-State wird korrekt verworfen, Repository bleibt sauber).

### Befund außerhalb des ursprünglichen Testplans (im Rahmen der Umsetzung behoben)

Die erste Implementierung von `Net.EnsureRemotes` prüfte unbedingt `RunService:IsServer()`. In Studio ist `RunService:IsServer()` im Edit-Modus (also auch in der normalen Command-Bar ohne laufendes Spiel) **immer `false`** (`IsClient()` dagegen `true`), obwohl dieser Kontext faktisch serverseitige Rechte hat (Instanzen erzeugen etc.). Das hätte die in der Teststrategie vorgesehene Prüfung über die Command-Bar systematisch verhindert. Behoben, indem die Prüfung nur greift, wenn `RunService:IsRunning()` wahr ist (d. h. während einer echten Play-Session) — im Edit-Modus bleibt `EnsureRemotes()` nutzbar, während es während einer laufenden Play-Session auf dem Client weiterhin korrekt verweigert wird. Dies ist eine reine Implementierungsdetail-Korrektur innerhalb der Funktionssignatur aus `ARCHITECTURE.md`, keine Schnittstellenänderung und daher ohne neue Decision-Datei.

Zusätzlich beim ersten Testlauf beobachtet: `require()` cacht ein `ModuleScript`-Ergebnis innerhalb einer Edit-Modus-Session auch nach einer Quelltextänderung via Rojo-Sync (alte kompilierte Closure bleibt aktiv, bis eine neue Play-Session eine frische VM erzeugt). Kein Code-Bug, sondern eine Eigenheit der Studio-Command-Bar-Umgebung; für zukünftige Tasks relevant, falls iterativ im Edit-Modus gegen bereits `require`-te Module getestet wird (Abhilfe: Play-Test starten/stoppen für eine frische VM).

### Neue Architekturentscheidungen

Keine. Alle Module folgen exakt den in `ARCHITECTURE.md` Abschnitten 4–6 spezifizierten Schnittstellen und Werten; die Server-Guard-Korrektur in `Net.EnsureRemotes` ist eine Implementierungsdetail-Korrektur ohne Signaturänderung.

### Auswirkungen auf spätere Tasks

- Task 003–012 können wie vorgesehen `require(GameConfig)`, `require(LevelConfig)`, `require(GameTypes)`, `require(GridMath)` und `require(Net)` nutzen; die Konstanten-Tabellen in `Net` werden dort um weitere `type`-Werte ergänzt, nicht neu strukturiert.
- Task 006 (Networking/State-Machine) sollte beim Verdrahten von `GameService.Init()` beachten, dass `Net.EnsureRemotes()` serverseitig genau einmal beim Bootstrap aufgerufen wird; dank der Idempotenz-Garantie ist ein versehentlicher Doppelaufruf unkritisch.
