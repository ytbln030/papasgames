# 009 — BombService liefert Platzierungserfolg synchron, Explosionsergebnis per Signal

## Kontext

`ARCHITECTURE.md` Abschnitt 7 beschreibt bisher `BombService.TryPlaceBomb(player: Player): BombOutcome?` — `nil` bei ungültiger Platzierung, sonst *nach Ablauf der Fuse* das Ergebnis als Rückgabewert. Das ist mit der technischen Vorgabe aus `tasks/007-bomb-and-explosion.md` ("Alle Zeit-/Fuse-Logik über `task.delay`/`task.spawn`, keine blockierenden `wait()`-Schleifen") nicht vereinbar: Ein Rückgabewert kann nicht sowohl den sofortigen Platzierungserfolg als auch ein erst Sekunden später feststehendes Ergebnis transportieren, ohne den aufrufenden Thread zu blockieren.

Zusätzlich braucht `BombService.TryPlaceBomb` das aktuelle `LevelConfigData` für `levelConfig.BombFuse` (Spec §21), das bisher nicht als Parameter vorgesehen war.

## Entscheidung

- `TryPlaceBomb(player: Player, levelConfig: LevelConfigData): boolean` ersetzt die bisherige Signatur. Der Rückgabewert ist rein synchron: `true`, wenn die Bombe platziert wurde (Spieler stand auf einer gültigen Kachel, hatte für das aktuelle Target noch keine Bombe platziert), sonst `false` (Anfrage wird ignoriert, Spec §18/§50).
- Das asynchrone Ergebnis nach Ablauf der Fuse wird über zwei neue, modul-eigene Signale geliefert (Connect/Fire-Tabellen analog `TargetService.TargetExpired`/`PlayerService.PlayerFell`, siehe [`decisions/004-no-external-framework.md`](004-no-external-framework.md)):
  - `BombService.BombExploded(player: Player)` — gefeuert genau beim Ablauf der Fuse, vor der Validierung (Trigger für den `GameService`-Übergang nach `EXPLODING`).
  - `BombService.BombResolved(player: Player, outcome: BombOutcome)` — gefeuert direkt danach mit dem validierten Ergebnis (Trigger für den `GameService`-Übergang nach `ROUND_RESULT`).
- `GameService.Init()` verbindet sich einmalig mit beiden Signalen.

## Begründung

- Erhält die in `ARCHITECTURE.md` Abschnitt 1 geforderte Inversion of Control: `BombService` kennt weiterhin `GameService` nicht, sondern meldet nur nach oben (wie `PlayerService.PlayerFell`, `TargetService.TargetExpired`).
- Vermeidet blockierende Warteschleifen vollständig, da sowohl die sofortige Platzierungs-Antwort als auch das verzögerte Explosionsergebnis jeweils eigene, nicht-blockierende Kanäle haben.
- Bildet den vollen in `tasks/007-bomb-and-explosion.md` geforderten State-Übergang `TARGET_ACTIVE → BOMB_PLACED → EXPLODING → ROUND_RESULT` ab, statt `EXPLODING` zu überspringen.
- Folgt einem bereits etablierten Muster statt einen neuen Mechanismus (z. B. Callback-Parameter, Promise) einzuführen.

## Konsequenz

- `ARCHITECTURE.md` Abschnitt 7, Eintrag `BombService`, wird entsprechend aktualisiert.
- `GameService` muss `LevelConfig.GetConfig(session.level)` vor dem Aufruf von `TryPlaceBomb` auflösen (analog zum bereits bestehenden Aufruf vor `TargetService.CreateTarget`).
