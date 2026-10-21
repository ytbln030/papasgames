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

Implementiert:

- `src/client/UI/GameHudUI.luau` (neu): code-generierte Topbar (`Create()`) mit fünf `TextLabel`s (LEVEL/TARGETS/TIME/LIVES/SCORE), separates Feedback-Label für PERFECT!/MISS, `Update(data)` für diskrete Feldänderungen, eigener `RunService.Heartbeat`-Tick nur für das kontinuierlich laufende TIME-Feld. `Init()` erzeugt die UI (ausgeblendet) und abonniert `GameClientController`.
- `src/client/Controllers/GameClientController.luau` (Erweiterung): zusätzliche Signale `BombPlaced`, `RoundResult`, `ScoreUpdated`, `LivesChanged`, `GameOver` nach demselben Connect/Fire-Muster wie die bestehenden drei; lokaler Spiegel um `score`/`levelScore`/`level`/`lives` plus `GetScore`/`GetLevel`/`GetLives` ergänzt (ARCHITECTURE.md Abschnitt 7 sah diesen vollen Spiegel bereits vor).
- `src/client/init.client.luau`: `GameHudUI.Init()` ergänzt (direkt gestartet statt wie in ARCHITECTURE.md Abschnitt 3 ursprünglich skizziert lazy von `GameClientController` erzeugt — siehe Kommentar dort; verhält sich sichtbar identisch, da die UI bis zum ersten `StateChanged` ausgeblendet bleibt).

**Über den deklarierten Task-Scope hinausgehend, dokumentiert vor der Code-Änderung (CLAUDE.md):** `LIVES` ließ sich mit dem bisherigen Protokoll nicht korrekt anzeigen — kein bestehendes `GameEvent` trägt den aktuellen Lebensstand, und der stille Sturz-Fall (`FALL` ohne Game Over) feuerte bisher überhaupt kein Event. Daher [`decisions/011-lives-changed-gameevent.md`](../decisions/011-lives-changed-gameevent.md) (neuer `GameEvent`-Typ `LivesChanged`), `ARCHITECTURE.md` Abschnitt 6/7 aktualisiert, danach `src/shared/Net/Net.luau` (neuer `Net.GameEventType.LivesChanged`) und `src/server/Services/GameService.luau` (feuert `LivesChanged` in `onRequestPlay` und unconditional in `handleFailure`, auch im FALL-Fall) angepasst.

Manuelle Verifikation in Roblox Studio (Play-Test, über MCP-Tools durchgeführt):

1. **AK1 (alle fünf Pflichtwerte korrekt):** Nach `RequestPlay` zeigte die Topbar sofort `LEVEL 1, TARGETS 0, TIME <countdown>, LIVES 3, SCORE 0`. Über mehrere echte Spielrunden (Timeout, Miss, Hit-by-Explosion, Fall, Success) wurden Client-HUD-Werte gegen die Server-Konsolenausgaben abgeglichen, z. B. Server `"SUCCESS, Restzeit=19.43s, +294 Punkte -> score=294 levelScore=294"` ↔ Client-HUD `SCORE 294, TARGETS 1` exakt deckungsgleich; `LIVES` folgte server-seitigen Dekrementen (`3→2→1→0`) 1:1 über alle vier Fehlerquellen inkl. des stillen Sturz-Falls. ✅
2. **AK2 (Timer zählt sichtbar/korrekt herunter):** `TIME` sank über wiederholte Messungen konsistent mit der realen Zeit (z. B. 10.4 → 9.6 zwischen zwei Messpunkten), erreichte bei Ablauf ohne platzierte Bombe zuverlässig den TIMEOUT-Fehlerfall. ✅
3. **AK3 (PERFECT/MISS-Feedback ~1s, dann automatisch weg):** Nach einem realen `SUCCESS` war `Feedback.Text = "PERFECT!"`; bei späterer Prüfung (nach > 1s) war `Feedback.Visible` wieder `false`, ohne manuellen Eingriff — bestätigt den `task.delay`+Generation-Schutz. Dieselbe Logik gilt identisch für MISS/HIT_BY_EXPLOSION (beide nutzen denselben Codepfad, nur anderer Text/Farbe), real beobachtet bei einem MISS- und einem HIT_BY_EXPLOSION-Ausgang. ✅
4. **AK4 (schmaler Streifen):** `TOPBAR_HEIGHT = 36` Pixel, volle Bildschirmbreite, keine weiteren Höhenverbraucher. ✅ (rein property-basiert verifiziert; `screen_capture` des MCP-Tools rendert nur die 3D-Viewport-Kamera, keine `ScreenGui`-Overlays, daher kein visueller Screenshot-Beleg möglich — Property-Prüfung ist hier aussagekräftiger.)
5. **AK5 (außerhalb aktiver Session ausgeblendet):** Vor dem ersten `RequestPlay` war `hudGui.Enabled == false`; nach `GAME_OVER` (nach drei TIMEOUTs) wieder `false`, inklusive korrektem finalem `LIVES 0`. ✅

Nebenbefund während des Testens (kein Code-Bug, Testmethodik-Hinweis für künftige Sessions): `TargetService` hält nur ein einziges globales `activeTarget` (Singleplayer-MVP), dessen `TargetLifetime` (20s auf Level 1) durch die Latenz zwischen einzelnen MCP-Tool-Aufrufen leicht überschritten wird. Zuverlässig ließ sich eine echte Spielaktion nur erzeugen, indem `RequestPlay` → Zielposition auslesen → Spieler teleportieren → `PlaceBomb` → (für `SUCCESS`) wegteleportieren vollständig innerhalb **eines** `execute_luau`-Aufrufs mit `task.wait()` statt über mehrere separate Tool-Aufrufe ausgeführt wurde.

Ein während des Testens gefundener und behobener Bug: `GameHudUI.Create()` rief initial `GameHudUI.Update(hudState)` auf, aber `hudState` hat das Feld `targetsDestroyed`, während `Update()` `data.targets` erwartet — das `TARGETS`-Label blieb dadurch beim Platzhaltertext hängen. Behoben durch explizites Feld-Mapping beim initialen `Update`-Aufruf in `Create()`.

**Fazit:** Alle fünf Akzeptanzkriterien manuell gegen den echten Server-Zustand verifiziert.
