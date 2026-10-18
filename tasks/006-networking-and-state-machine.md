# Task 006 — Networking & State Machine

## Ziel und erwartetes Verhalten

Dies ist der Konvergenzpunkt, der Board/Player/Target zu einem tatsächlichen Spielablauf verbindet: `GameService` implementiert die Zustandsmaschine aus `docs/SPEC.md` §34 und reagiert auf den `RequestPlay`-Client-Intent, indem es eine neue Session startet (Spawn + erstes Target). Auf Client-Seite entsteht `GameClientController`, der `GameEvent`-Broadcasts empfängt und als zentrale Verteilstelle für spätere UI/Effekt-Module dient. **Noch kein** Bomben-Flow und **kein** Scoring — das kommt in Task 007/008.

## Voraussetzungen und Abhängigkeiten

[Task 002](002-shared-foundations.md), [Task 003](003-board-system.md), [Task 004](004-player-spawn-and-safety.md), [Task 005](005-target-system.md) müssen abgeschlossen sein. Dies ist bewusst der am stärksten verzahnte Task der Roadmap — siehe [`ROADMAP.md`](../ROADMAP.md).

## Betroffene Module

- `src/server/Services/GameService.luau` (neu)
- `src/server/init.server.luau` (Composition Root: requiret + initialisiert `BoardService → PlayerService → TargetService → BombService → GameService`; `BombService` existiert als leeres/stub-Modul, falls Task 007 noch nicht läuft — siehe Hinweis unten)
- `src/client/Controllers/GameClientController.luau` (neu)
- `src/client/init.client.luau` (Composition Root, startet zunächst nur `GameClientController`)

> Hinweis zur Bootstrap-Reihenfolge: `ARCHITECTURE.md` Abschnitt 3 sieht `BombService` vor `GameService` in der Init-Kette vor. Falls Task 007 zum Zeitpunkt dieser Task noch nicht existiert, legt diese Task ein minimales `BombService`-Platzhaltermodul an (`Init()` ohne Funktionalität, `TryPlaceBomb` liefert `nil`), das Task 007 vollständig ausimplementiert, ohne die Schnittstelle zu brechen.

## Funktionale Anforderungen

### Server (`GameService`)
1. Implementiert die State Machine mit den Zuständen aus [`ARCHITECTURE.md`](../ARCHITECTURE.md) Abschnitt 8: `MENU, STARTING, TARGET_ACTIVE, BOMB_PLACED, EXPLODING, ROUND_RESULT, NEXT_TARGET, GAME_OVER`.
2. Hält pro `Player` ein `PlayerSessionData` (`lives, score, levelScore, level, state`), initialisiert bei `PlayerAdded` mit `state = "MENU"`.
3. Ruft beim Server-Start `Net.EnsureRemotes()` auf.
4. Abonniert `ClientAction`: bei `type == "RequestPlay"` → neue Session für den sendenden Spieler: `lives = GameConfig.StartingLives`, `score = 0`, `levelScore = 0`, `level = 1`, state `STARTING`; ruft `BoardService.CreateBoard(LevelConfig.GetConfig(1))` (nur beim allerersten `RequestPlay` einer Session — siehe [`decisions/007`](../decisions/007-board-size-fixed-per-session.md)), dann `PlayerService.SpawnPlayer(player)`, dann `TargetService.CreateTarget(LevelConfig.GetConfig(1), spielerGridPosition)` ([`decisions/006`](../decisions/006-spawn-before-target.md)), setzt state `TARGET_ACTIVE`.
5. Abonniert `TargetService.TargetExpired`: Platzhalter-Reaktion für diesen Task ist erlaubt (volle Konsequenz-Logik inkl. Lebensverlust folgt in Task 008) — **mindestens** muss ein neues Target erzeugt werden, damit der Loop nicht einfriert; Lebensverlust darf hier bereits rudimentär (z. B. fester Dekrement ohne Game-Over-Prüfung) vorhanden sein, wird aber in Task 008 vervollständigt und überprüft.
6. Abonniert `PlayerService.PlayerFell`: Platzhalter-Reaktion analog Punkt 5 (volle Prüfung in Task 008).
7. Broadcastet nach jeder Zustandsänderung ein `GameEvent{type="StateChanged", state=...}` sowie nach Target-Erzeugung `GameEvent{type="TargetSpawned", target=TargetData}` / nach Entfernung `GameEvent{type="TargetCleared"}` an den betroffenen Spieler.

### Client (`GameClientController`)
1. Ruft `Net.WaitForRemotes()` beim Start auf.
2. Bindet sich an `GameEvent.OnClientEvent`, hält einen lokalen Spiegel von `PlayerSessionData`/aktivem `TargetData`.
3. Exponiert eigene Signals: `StateChanged`, `TargetSpawned`, `TargetCleared` (weitere folgen in Task 007/008, siehe `ARCHITECTURE.md` Abschnitt 7) — andere Client-Module abonnieren diese, statt selbst `GameEvent` zu binden.
4. Exponiert `GameClientController.RequestPlay(): ()`, das `ClientAction{type="RequestPlay"}` feuert (wird in Task 011 vom PLAY-Button aufgerufen).

## Technische Vorgaben und Schnittstellen

- `GameService` ist die **einzige** Stelle, die `PlayerSessionData` mutiert.
- `GameService` darf `BoardService`, `PlayerService`, `TargetService`, `BombService` requiren; keines dieser Module darf `GameService` requiren (einseitige Abhängigkeit, verhindert Zyklen).
- State-Übergänge werden zentral über eine einzige Funktion (z. B. `SetState(player, newState)`) vorgenommen, die zugleich den `StateChanged`-Broadcast auslöst — keine verstreuten direkten Zuweisungen an `session.state`.

## Bekannte zukünftige Anforderungen

- Multiplayer (Backlog 017): `PlayerSessionData`-Tabelle ist bereits pro `Player` indiziert; `BoardService.CreateBoard` müsste für gemeinsames Board nur einmal global (nicht pro Spieler) aufgerufen werden — das ist bereits so umgesetzt (kein Pro-Spieler-Board).

## Out of Scope

- Bomben-Platzierung, Explosion, Validierung (Task 007).
- Vollständige, geprüfte Score-/Level-/Game-Over-Logik (Task 008) — Platzhalter reichen hier aus, solange der Loop nicht einfriert.
- HUD/Menü-Darstellung (Task 010/011).

## Akzeptanzkriterien

1. Nach `ClientAction{RequestPlay}` eines Spielers wird nachweislich (Server-Print/Output) `BoardService.CreateBoard`, `PlayerService.SpawnPlayer` und `TargetService.CreateTarget` aufgerufen, und der State wechselt zu `TARGET_ACTIVE`.
2. `GameClientController` empfängt `StateChanged` und `TargetSpawned` und spiegelt sie nachweislich in seinem lokalen State (per Print verifizierbar).
3. Ein zweiter `RequestPlay` desselben Spielers (z. B. nach manuellem State-Reset) baut das Board nicht erneut auf (kein zweites `Workspace.Board`).
4. Beim Ablauf des Target-Timers oder einem Sturz entsteht nachweislich ein neues Target, ohne dass der Server-Loop blockiert oder Fehler wirft.

## Teststrategie (manuell in Roblox Studio)

1. Play-Test starten, über die Studio-Command-Bar (Client-seitig simuliert oder direkt serverseitig) `ClientAction{type="RequestPlay"}` feuern bzw. `GameClientController.RequestPlay()` aufrufen.
2. Server-Output beobachten: Board-Erzeugung, Spawn, erstes Target, State-Wechsel zu `TARGET_ACTIVE`.
3. Client-Output beobachten: `GameClientController` empfängt und spiegelt die Events (temporäre Print-Statements in den Signal-Handlern).
4. Target auslaufen lassen (kurze Testlifetime) und beobachten, dass ein neues Target entsteht.
5. Absichtlich vom Board fallen und beobachten, dass der Loop weiterläuft (neues Target oder zumindest kein Absturz).
6. Ergebnis dokumentieren.

## Definition of Done

- `GameService.luau`, `GameClientController.luau` implementiert, Composition Roots (`init.server.luau`/`init.client.luau`) verdrahtet.
- Alle Akzeptanzkriterien manuell verifiziert und dokumentiert.

---

## Ergebnis (von der ausführenden Task-Session auszufüllen)

_Noch nicht ausgeführt._
