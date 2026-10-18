# Task 010 — Game HUD

## Ziel und erwartetes Verhalten

`GameHudUI` zeigt eine schmale, dauerhafte Informationsleiste am oberen Bildschirmrand (Spec §27) mit Level, Anzahl erfolgreich zerstörter Targets, verbleibender Zeit des aktuellen Kreuzes, Leben und Punktzahl, sowie kurzes PERFECT/MISS-Feedback (Spec §25, §26).

## Voraussetzungen und Abhängigkeiten

[Task 002](002-shared-foundations.md), [Task 006](006-networking-and-state-machine.md). Kann parallel zu [009](009-input-controller.md), [011](011-main-menu-and-game-over.md), [012](012-explosion-effects-and-feedback.md) bearbeitet werden.

## Betroffene Module

- `src/client/UI/GameHudUI.luau` (neu)
- `src/client/Controllers/GameClientController.luau` (Erweiterung: zusätzliche Signals `ScoreUpdated`, `BombPlaced`, `RoundResult`, falls in Task 006 noch nicht vollständig, siehe `ARCHITECTURE.md` Abschnitt 7)

## Funktionale Anforderungen

1. `GameHudUI.Create(): ScreenGui` erzeugt code-generiert (Spec-Entscheidung, [`decisions/002-ui-code-generated.md`](../decisions/002-ui-code-generated.md)) eine schmale Topbar unter `PlayerGui`, die **wenig Bildschirmhöhe** verbraucht (Spec §27, §9 — First-Person-Priorität).
2. Zeigt mindestens: `LEVEL`, `TARGETS` (Anzahl erfolgreich zerstörter Kreuze in dieser Session), `TIME` (verbleibende Lebenszeit des aktuellen Kreuzes, laufend aktualisiert), `LIVES`, `SCORE` (Spec §27-Tabelle).
3. `GameHudUI.Update(data: {...}): ()` aktualisiert die Anzeige; wird von `GameClientController`-Signals (`ScoreUpdated`, `TargetSpawned`, `StateChanged`) gespeist.
4. Der `TIME`-Wert zählt lokal client-seitig in Echtzeit herunter (berechnet aus `TargetData.spawnedAt` + `TargetData.lifetime`, nicht durch ständige Server-Broadcasts — reduziert Netzwerklast), wird aber bei jedem `TargetSpawned`/`TargetCleared`-Event neu synchronisiert.
5. Zeigt nach einem `RoundResult`-Event kurz `PERFECT!`/`TARGET DESTROYED` (bei `SUCCESS`, Spec §25) bzw. `MISS` (bei `MISS`/`HIT_BY_EXPLOSION`, Spec §26) für ca. 1 Sekunde an.
6. Die Topbar ist nur sichtbar, während eine Session aktiv ist (State ≠ `MENU`/`GAME_OVER`) — siehe Zusammenspiel mit Task 011.

## Technische Vorgaben und Schnittstellen

- `GameHudUI` abonniert ausschließlich `GameClientController`-Signals, bindet sich nicht selbst an das `GameEvent`-Remote (siehe `ARCHITECTURE.md` Abschnitt 7).
- Keine Abhängigkeit auf `MainMenuUI`/`EffectsController` (Geschwister-Module, unabhängig voneinander).

## Bekannte zukünftige Anforderungen

- Combo-Anzeige (Backlog 014) könnte als weiteres Feld in der Topbar ergänzt werden, ohne bestehende Felder zu verändern.
- Level-Fortschrittsanzeige (Spec §27-Tabelle, "Punkte bis zum nächsten Level") ist im MVP optional; falls nicht umgesetzt, als bewusste Auslassung dokumentieren.

## Out of Scope

- Startscreen/Game-Over-Screen (Task 011).
- Gefahrenzonen-Anzeige (bereits serverseitig als Weltobjekt gelöst, [`decisions/005`](../decisions/005-danger-zone-world-visual.md)).

## Akzeptanzkriterien

1. Alle fünf Pflichtwerte (Level, Targets, Time, Lives, Score) sind jederzeit während einer aktiven Session korrekt und aktuell sichtbar.
2. Der Timer zählt sichtbar und korrekt (±1s Toleranz durch Client-Rendering) bis 0 herunter.
3. PERFECT/MISS-Feedback erscheint zuverlässig nach jedem Rundenende und verschwindet nach ca. 1 Sekunde automatisch wieder.
4. Die Topbar beansprucht sichtbar nur einen schmalen Streifen am oberen Bildschirmrand.
5. Außerhalb einer aktiven Session (Startscreen, Game Over) ist die Topbar nicht eingeblendet.

## Teststrategie (manuell in Roblox Studio)

1. Session starten, alle fünf HUD-Werte mit dem tatsächlichen Server-Zustand (Server-Print) abgleichen.
2. Timer über einen vollen Countdown beobachten, mit der Stoppuhr grob gegen `TargetLifetime` prüfen.
3. Je eine erfolgreiche und eine fehlgeschlagene Runde spielen, PERFECT- bzw. MISS-Feedback beobachten.
4. Zum Startscreen zurückkehren (Game Over abwarten) und prüfen, dass die Topbar verschwindet.
5. Ergebnis dokumentieren (ggf. mit Screenshot).

## Definition of Done

- `GameHudUI.luau` implementiert und von `GameClientController` korrekt gespeist.
- Alle Akzeptanzkriterien manuell verifiziert und dokumentiert.

---

## Ergebnis (von der ausführenden Task-Session auszufüllen)

_Noch nicht ausgeführt._
