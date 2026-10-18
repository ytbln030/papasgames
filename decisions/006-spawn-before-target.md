# 006 — Spieler-Spawn erfolgt vor der ersten Target-Generierung

## Kontext

`docs/SPEC.md` §10 fordert, dass der Spawn-Punkt "möglichst nicht direkt auf dem später gesuchten Kreuzungspunkt" liegt und optional einen Mindestabstand zum Ziel einhält. §46 fordert zusätzlich, dass die Target-Generierung berücksichtigt, "wie weit der Spieler vom neuen Target entfernt ist". Die Spec legt nicht explizit fest, in welcher Reihenfolge Spawn und (erste) Target-Generierung ablaufen — das ist ein Henne-Ei-Problem, wenn beide voneinander abhängen sollen.

## Entscheidung

Reihenfolge ist fest: Zuerst platziert `PlayerService.SpawnPlayer` den Spieler auf einer beliebigen gültigen Kachel (nur Bedingung: innerhalb des Boards). Danach ruft `GameService` `TargetService.CreateTarget(levelConfig, playerGridPosition)` auf, wobei die aktuelle Spielerposition als Fairness-Eingabe dient (Mindestabstand `GameConfig.MinSpawnDistanceFromTarget`, §46). Dieselbe Reihenfolge gilt bei jedem Folge-Target: Die *aktuelle* Spielerposition zum Zeitpunkt der Generierung fließt ein, nicht die ursprüngliche Spawn-Position.

## Begründung

Löst die Reihenfolge-Ambiguität eindeutig und erfüllt beide Spec-Anforderungen (§10 und §46) mit einer einzigen, konsistenten Regel, ohne eine zweite Spawn-Iteration oder Nachkorrektur der Spielerposition zu benötigen.

## Konsequenz

- `TargetService.CreateTarget` benötigt als Parameter immer eine `GridPosition` des Spielers.
- `PlayerService.SpawnPlayer`/`RespawnPlayer` benötigen keine Kenntnis des aktiven Targets.
