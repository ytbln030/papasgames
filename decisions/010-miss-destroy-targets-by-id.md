# 010 — Verzögertes MISS-Despawn zerstört nur noch das gemisste Target

## Kontext

Task 008 lässt `GameService` nach jedem Fehlversuch (Spec §17/§26, Funktionale Anforderung 5) sofort ein neues Target erzeugen, ausgelöst synchron durch `BombService.BombResolved`. `BombService` verzögert bei `MISS` selbst das Entfernen der falsch getroffenen Zielkugeln um `MISS_DISPLAY_DELAY` (1s, Spec §26 "kurze MISS-Einblendung"), indem es `TargetService.DestroyActiveTarget()` per `task.delay` aufruft.

Da `GameService` das neue Target bereits **synchron** bei `BombResolved` erzeugt (also bevor dieser verzögerte Aufruf feuert), ist zum Zeitpunkt des verzögerten Callbacks bereits ein **neues** Target aktiv. `TargetService.DestroyActiveTarget()` kennt aber keine Zielreferenz - es löscht immer das jeweils aktuell aktive Target. Der verzögerte MISS-Callback hat also nach Ablauf der Sekunde das inzwischen aktive neue Target zerstört statt des längst ersetzten alten, wodurch das Spiel ohne aktives Target und ohne laufenden Timer hängen bleibt.

Dieses Race war vor Task 008 nicht sichtbar, weil die damalige Platzhalter-Logik nach `BombResolved` kein neues Target erzeugte.

## Entscheidung

`BombService` merkt sich beim Validieren eines `MISS`-Ergebnisses die Id des gerade gemissten Targets (`TargetService.GetActiveTarget().id`, abgefragt **vor** dem `task.delay`) und zerstört im verzögerten Callback nur dann, wenn `TargetService.GetActiveTarget()` zu diesem Zeitpunkt noch dasselbe Target (gleiche Id) ist. Ist inzwischen ein neues Target aktiv, bleibt es unberührt.

## Begründung

- Minimal-invasiv: keine neue Schnittstelle, kein neues Signal, nur ein lokaler Id-Schnappschuss plus Vergleich innerhalb von `BombService.resolveBomb`. `TargetService` bleibt vollständig unverändert.
- Bewahrt gleichzeitig Spec §26 (kurze MISS-Einblendung der falschen Kugeln) und Task 008 Funktionale Anforderung 5 (unmittelbar neues Target) - beide stehen ohne diese Änderung in Konflikt.
- `TargetService.DestroyActiveTarget()` bewusst nicht um eine Id-Prüfung erweitert: `TargetService` kennt laut `ARCHITECTURE.md` Abschnitt 7 ohnehin nur ein einzelnes aktives Target (kein Array), die Verantwortung für korrektes Timing beim asynchronen Aufruf bleibt beim Aufrufer (`BombService`).

## Konsequenz

- `BombService.resolveBomb` erzeugt im `MISS`-Zweig einen lokalen `missedTargetId`-Schnappschuss vor dem `task.delay` und prüft ihn im verzögerten Callback gegen `TargetService.GetActiveTarget()`.
- Betrifft nur den `MISS`-Zweig; `SUCCESS`/`HIT_BY_EXPLOSION` zerstören weiterhin sofort (kein verzögerter Aufruf, daher kein Race).
- Entdeckt und verifiziert während der manuellen Tests von Task 008 (siehe `tasks/008-scoring-and-level-progression.md`, Abschnitt "Ergebnis").
