# Task 012 — Explosion Effects & Feedback

## Ziel und erwartetes Verhalten

`EffectsController` liefert die akustisch-visuelle Wucht, die laut Spec für dieses Spiel "besonders wichtig" ist (§44): Explosions-Feedback (Licht, Partikel, Sound, kurzer Camera-Shake) sowie akustische Beeps während der Fuse (Spec §21). Nach diesem Task fühlt sich eine Bombenrunde spürbar dramatisch an, nicht nur mechanisch korrekt.

## Voraussetzungen und Abhängigkeiten

[Task 006](006-networking-and-state-machine.md), [Task 007](007-bomb-and-explosion.md). Kann parallel zu [009](009-input-controller.md), [010](010-game-hud.md), [011](011-main-menu-and-game-over.md) bearbeitet werden.

## Betroffene Module

- `src/client/Controllers/EffectsController.luau` (neu)

## Funktionale Anforderungen

1. Abonniert `GameClientController.BombPlaced` → startet client-seitig schneller werdende Beep-Sounds während der Fuse (Spec §21: "BEEP BEEP BEEP BOOM", Tempo steigt Richtung Explosion).
2. Abonniert `GameClientController.RoundResult` → spielt bei Explosion (unabhängig vom Ergebnis) einen kurzen Camera-Shake (`Camera.CFrame`-Offset über wenige Frames, **kurz genug, um die Orientierung nicht zu verlieren**, Spec §45) sowie einen Explosions-Sound ab.
3. Unterscheidet akustisch/visuell leicht zwischen `SUCCESS` (zusätzlicher Erfolgs-Sound, Spec §25) und `MISS`/`HIT_BY_EXPLOSION` (Fehlschlag-Sound, Spec §26).
4. Optional (falls zeitlich im Rahmen dieses Tasks umsetzbar, sonst explizit als nicht umgesetzt dokumentieren): kurzes Aufleuchten der vier Zielkugeln unmittelbar vor ihrer Zerstörung (Spec §23 "können die vier Kugeln zunächst kurz aufleuchten und anschließend gleichzeitig zerplatzen").
5. Bei `TargetSpawned` optional ein kurzer "Target erscheint"-Sound (Spec §44-Liste).

## Technische Vorgaben und Schnittstellen

- Rein client-seitig, keine Server-Mutationen. `EffectsController` liest ausschließlich `GameClientController`-Signals.
- Camera-Shake darf die normale Kamerasteuerung (First-Person, Spec §45) nicht dauerhaft überschreiben — nach Abschluss des Shakes muss die Kamera exakt zur vom Spieler gesteuerten Ausrichtung zurückkehren.
- Sound-Assets: Platzhalter-Sounds aus der Roblox-Bibliothek sind für den MVP ausreichend; Asset-IDs werden als benannte Konstanten im Modul gepflegt (keine Magic-ID-Strings verstreut im Code).

## Bekannte zukünftige Anforderungen

- Weitere Sounds aus Spec §44 (Timer nähert sich Null, Level abgeschlossen) können als zusätzliche Signal-Abonnements ergänzt werden, ohne bestehende Handler zu ändern.

## Out of Scope

- Gefahrenzonen-Visual (bereits serverseitig gelöst, Task 007/[`decisions/005`](../decisions/005-danger-zone-world-visual.md)).
- HUD-Textfeedback (PERFECT/MISS-Text ist Task 010, akustisches/visuelles Feedback hier).

## Akzeptanzkriterien

1. Während der 2-Sekunden-Fuse sind hörbar beschleunigende Beeps zu vernehmen.
2. Bei jeder Explosion ist ein kurzer, spürbarer aber nicht orientierungsraubender Camera-Shake sichtbar.
3. `SUCCESS` und `MISS`/`HIT_BY_EXPLOSION` sind akustisch klar unterscheidbar.
4. Nach dem Shake kehrt die Kamera exakt zur spielergesteuerten Blickrichtung zurück (kein bleibender Versatz).

## Teststrategie (manuell in Roblox Studio)

1. Play-Test: Bombe platzieren, Fuse-Beeps anhören und subjektiv auf steigendes Tempo prüfen.
2. Je eine `SUCCESS`- und eine `MISS`/`HIT_BY_EXPLOSION`-Runde spielen, Sounds vergleichen.
3. Nach mehreren Explosionen die Kameraausrichtung vor/nach dem Shake vergleichen (z. B. auf einen fixen Punkt zielen, Explosion abwarten, prüfen, dass die Kamera wieder exakt darauf zeigt).
4. Ergebnis dokumentieren, inkl. expliziter Angabe, ob Punkt 4 der funktionalen Anforderungen (Kugel-Aufleuchten) umgesetzt wurde oder bewusst ausgelassen wurde.

## Definition of Done

- `EffectsController.luau` implementiert und im Client-Composition-Root gestartet.
- Alle Akzeptanzkriterien manuell verifiziert und dokumentiert; optionale Punkte explizit als umgesetzt/ausgelassen vermerkt.

---

## Ergebnis (von der ausführenden Task-Session auszufüllen)

_Noch nicht ausgeführt._
