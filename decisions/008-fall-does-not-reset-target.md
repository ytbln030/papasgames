# 008 — Sturz vom Spielfeld beendet nicht das aktive Target

## Kontext

`docs/SPEC.md` §8 und §24 legen fest, dass ein Sturz vom Spielfeld ein Leben kostet und einen sicheren Respawn auslöst. Die Spec sagt aber nicht explizit, ob das *aktuell aktive* Target (inkl. seines 20-Sekunden-Timers) dabei erhalten bleibt oder durch ein neues ersetzt wird.

## Entscheidung

Ein Fall-Tod (`PlayerService`-Event `PlayerFell`) kostet ein Leben und löst einen Respawn aus, **ändert aber nicht den `GameService`-Zustand** und ersetzt nicht das aktive Target. Timer und Target laufen unverändert weiter; der Spieler kann nach dem Respawn weiter versuchen, dasselbe Target zu lösen.

## Begründung

- Verhindert einen Exploit: Ohne diese Regel könnte sich ein Spieler absichtlich fallen lassen, um bei einem ungünstigen/fast abgelaufenen Target einen kostenlosen frischen Timer zu erhalten.
- Die Spec widerlegt diese Interpretation nirgends; "Fehlversuch" im Sinne von §24/§26 (der explizit ein neues Target auslöst) ist dort ausschließlich für falsch platzierte Bomben und Explosionstreffer definiert, nicht für Stürze.

## Konsequenz

- `PlayerService.PlayerFell` darf nur `GameService`-Lebenslogik triggern, nicht `TargetService.DestroyActiveTarget`/`CreateTarget`.
- Falls ein Sturz während `BOMB_PLACED`/`EXPLODING` passiert, bleibt die laufende Bomben-Fuse/Explosion ebenfalls unberührt.
