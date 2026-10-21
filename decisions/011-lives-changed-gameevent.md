# 011 — Neuer GameEvent-Typ `LivesChanged` für die Lebensanzeige

## Kontext

[Task 010](../tasks/010-game-hud.md) verlangt, dass die HUD-Topbar jederzeit die aktuelle Anzahl verbleibender Leben korrekt anzeigt. `ARCHITECTURE.md` Abschnitt 6/7 sieht dafür bisher keinen Übertragungsweg vor: `PlayerSessionData.lives` wird serverseitig in `GameService` mutiert (`onRequestPlay`, `handleFailure`), aber nie per `GameEvent` an den Client gemeldet — weder `ScoreUpdated` (nur bei `SUCCESS`, trägt nur `score`/`levelScore`/`level`) noch `RoundResult`/`GameOver` enthalten den aktuellen Lebensstand bei jedem Vorfall.

Besonders der nicht-tödliche Sturz-Fall (Spec, [`decisions/008-fall-does-not-reset-target.md`](008-fall-does-not-reset-target.md)) feuert aktuell **gar kein** `GameEvent` (`handleFailure` kehrt für `reason == "FALL"` ohne Game Over sofort zurück) — der Client hätte also keine Möglichkeit, einen Lebensverlust durch Sturz überhaupt zu erkennen, auch nicht indirekt über andere Events.

Dies ist eine Erweiterung über den in Task 010 deklarierten Betroffene-Module-Rahmen (`GameHudUI.luau`, `GameClientController.luau`) hinaus, da sie `Net.luau` und `GameService.luau` betrifft. Gemäß `CLAUDE.md` wird sie daher vorab dokumentiert.

## Entscheidung

- Neuer `Net.GameEventType`-Wert `LivesChanged`, Payload `{ type = "LivesChanged", lives: number }`.
- `GameService` feuert `LivesChanged` an zwei Stellen:
  1. In `onRequestPlay`, unmittelbar nachdem `session.lives` auf `GameConfig.StartingLives` gesetzt wurde (synchronisiert den Startwert explizit, statt dass der Client ihn aus `GameConfig` rät).
  2. In `handleFailure`, unmittelbar nach dem Dekrementieren von `session.lives`, **unabhängig davon** ob danach `GAME_OVER` folgt oder `reason == "FALL"` ist — deckt damit erstmals auch den stillen Sturz-Fall ab.
- Kein bestehender Event-Typ wird umgebaut; `ScoreUpdated`/`RoundResult`/`GameOver` bleiben unverändert.

## Begründung

- Folgt dem bereits etablierten Muster „ein Aspekt der Session = ein eigener, gezielter Event-Typ" (`ScoreUpdated` für Score/Level, jetzt `LivesChanged` für Leben), statt Lebensdaten in andere, semantisch unpassende Events huckepack zu nehmen oder sie clientseitig unzuverlässig aus Nebeneffekten (z. B. „jedes `RoundResult` ungleich `SUCCESS` = ein Leben weniger") zu rekonstruieren — Letzteres würde am Sturz-Fall ohnehin scheitern, da dafür kein Event existiert.
- Minimal-invasiv: keine neue `RemoteEvent`-Instanz (weiterhin nur die zwei aus [`decisions/001`](001-remote-consolidation.md)), nur ein neuer `type`-Wert.
- `GameService` bleibt alleinige Quelle der Wahrheit für `lives`; `BombService`/`TargetService`/`PlayerService` mutieren weiterhin nichts (ARCHITECTURE.md Abschnitt 7 unverändert in diesem Punkt).

## Konsequenz

- `ARCHITECTURE.md` Abschnitt 6 (Networking-Typliste) und Abschnitt 7 (`GameService`-Bullet, `GameClientController`-Signalliste) werden entsprechend ergänzt.
- `GameClientController` bekommt ein zusätzliches `LivesChanged`-Signal nach demselben Connect/Fire-Muster wie `StateChanged`/`TargetSpawned`/`TargetCleared`.
- `GameHudUI` (Task 010) abonniert dieses Signal für das `LIVES`-Feld, statt Lebensverlust aus anderen Events zu raten.
