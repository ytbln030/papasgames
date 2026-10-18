# 007 — BoardSize bleibt für die gesamte Session fix (MVP)

## Kontext

`docs/SPEC.md` §5 nennt als Beispiel unterschiedliche `BoardSize`-Werte pro Level (20×20, 25×25, 30×30, 35×35). `LevelConfigData` enthält entsprechend ein `BoardSize`-Feld. Das Beispiel-`LevelConfig` in §31 hält `BoardSize = 30` jedoch über das gezeigte Level hinweg konstant, und §53 listet keine konkrete Regel für einen Board-Rebuild beim Levelaufstieg (z. B. Umgang mit dem Spieler, falls er auf einer wegfallenden Kachel steht, Respawn-Verhalten, Kamera-Unterbrechung).

## Entscheidung

Für das MVP wird die `BoardSize` beim Level-Start einmalig aus `LevelConfig.GetConfig(1)` übernommen und bleibt für die **gesamte Session** fix, auch wenn spätere `LevelConfig`-Einträge eine andere `BoardSize` enthalten sollten. Ein Board-Rebuild beim Levelaufstieg ist explizit **out of scope** (Backlog 016).

## Begründung

- Entspricht dem in §31 gezeigten Beispiel (BoardSize bleibt dort konstant).
- Ein Board-Rebuild mitten in der Session hätte ungeklärte Rand-Effekte (Spieler-Position, aktives Target, Kamera), die die Spec nicht spezifiziert — vorzeitige Implementierung wäre Spekulation statt Spezifikation.
- Vermeidet, dass `BoardService` während einer laufenden Session destruktiv in bestehende Geometrie eingreifen muss.

## Konsequenz

- `BoardService.CreateBoard` wird pro Session genau einmal aufgerufen (beim `RequestPlay`-Handling in `GameService`).
- Level 1–3 unterscheiden sich im MVP nur in `TargetLifetime`, `MinTargetDistance`/`MaxTargetDistance` und `ScoreRequired`, nicht in `BoardSize`.
- Eine echte Board-Größenänderung pro Level müsste diese Entscheidung explizit revidieren, inkl. Klärung der oben genannten Rand-Effekte.
