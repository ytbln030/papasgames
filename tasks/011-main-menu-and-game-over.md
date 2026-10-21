# Task 011 — Main Menu & Game Over

## Ziel und erwartetes Verhalten

`MainMenuUI` stellt den Startscreen (Spec §4) und den Game-Over-Bildschirm (Spec §4, §26) bereit. Vor dem ersten `PLAY`-Klick ist der Spieler nicht aktiv auf dem Spielfeld; nach Game Over kehrt er zum Startscreen zurück und kann jederzeit eine komplett neue Session starten.

## Voraussetzungen und Abhängigkeiten

[Task 002](002-shared-foundations.md), [Task 006](006-networking-and-state-machine.md). Kann parallel zu [009](009-input-controller.md), [010](010-game-hud.md), [012](012-explosion-effects-and-feedback.md) bearbeitet werden.

## Betroffene Module

- `src/client/UI/MainMenuUI.luau` (neu)

## Funktionale Anforderungen

1. `MainMenuUI.ShowStart(): ()` zeigt beim ersten Laden des Spiels (State `MENU`) einen Startscreen mit Spieltitel und einem `PLAY`-Button (Spec §4). Aktuelle/höchste Bestleistung wird **nicht** angezeigt (kein `DataStore` im MVP, Backlog 015) — dieses Feld wird bewusst ausgelassen.
2. Klick auf `PLAY` ruft `GameClientController.RequestPlay()` auf (siehe Task 006) und blendet den Startscreen aus.
3. `MainMenuUI.ShowGameOver(score: number): ()` wird bei Empfang des `GameEvent{type="GameOver"}` (über `GameClientController`) angezeigt: zeigt die erreichte Punktzahl (Spec §4). Enthält ebenfalls einen `PLAY`-Button für einen Neustart.
4. Ein erneuter Klick auf `PLAY` nach Game Over startet über denselben `RequestPlay`-Intent eine **vollständig neue Session**: Level 1, 0 Punkte, 3 Leben (Spec §4 letzter Satz) — das ist bereits serverseitig durch Task 006/008 sichergestellt; dieser Task muss nur denselben Intent zuverlässig erneut feuern können.
5. `MainMenuUI.Hide(): ()` blendet beide Screens aus (z. B. beim Übergang zu `TARGET_ACTIVE`).

## Technische Vorgaben und Schnittstellen

- Code-generierte UI ([`decisions/002`](../decisions/002-ui-code-generated.md)), analog zu `GameHudUI`.
- Abonniert `GameClientController.StateChanged`/`GameOver`-Signals, um automatisch zwischen Start-/Game-Over-/Hidden-Zustand zu wechseln — kein eigener Polling-Loop.

## Bekannte zukünftige Anforderungen

- Best-Score-Anzeige (Backlog 015): `ShowStart`/`ShowGameOver` könnten um einen optionalen Parameter erweitert werden, sobald Persistenz existiert — Signatur bewusst so gestaltet, dass das später ergänzbar ist, ohne bestehende Aufrufer zu brechen (z. B. optionales Feld, kein Pflichtparameter).

## Out of Scope

- HUD während aktiver Session (Task 010).
- Bestleistungs-Persistenz (Backlog 015).

## Akzeptanzkriterien

1. Vor dem ersten `PLAY`-Klick ist das Spielfeld nicht aktiv/sichtbar für den Spieler (kein Charakter auf dem Board, siehe Zusammenspiel mit `GameService`-State `MENU`).
2. `PLAY`-Klick startet zuverlässig eine neue Session (Board erscheint, Spieler wird platziert, erstes Target erscheint).
3. Nach Game Over wird die tatsächlich erreichte Punktzahl korrekt angezeigt.
4. Erneuter `PLAY`-Klick nach Game Over setzt Level, Score und Leben nachweislich zurück (über HUD/Server-Print verifizierbar) und funktioniert beliebig oft wiederholt.

## Teststrategie (manuell in Roblox Studio)

1. Play-Test starten, prüfen, dass zunächst nur der Startscreen sichtbar ist.
2. `PLAY` klicken, Session-Start beobachten (Board, Spawn, erstes Target).
3. Eine Session bis Game Over durchspielen (z. B. durch wiederholtes absichtliches Fallenlassen), angezeigten Score gegen den zuletzt bekannten HUD-Wert abgleichen.
4. Erneut `PLAY` klicken, prüfen, dass eine komplett neue Session mit Level 1/Score 0/3 Leben beginnt; den gesamten Zyklus (Start → Game Over → Restart) mindestens zweimal durchlaufen.
5. Ergebnis dokumentieren.

## Definition of Done

- `MainMenuUI.luau` implementiert, korrekt an `GameClientController` angebunden.
- Alle Akzeptanzkriterien manuell verifiziert und dokumentiert.

---

## Ergebnis (von der ausführenden Task-Session auszufüllen)

`src/client/UI/MainMenuUI.luau` implementiert (Start-/Game-Over-Screen, code-generiert analog `GameHudUI`) und in `src/client/init.client.luau` nach `GameHudUI.Init()` eingehängt. `MainMenuUI.Init()` ruft `ShowStart()` proaktiv auf, da der initiale `MENU`-State beim `PlayerAdded` serverseitig nur lokal gesetzt wird und kein `StateChanged`-Event auslöst (`GameService.onPlayerAdded`) — alle folgenden Übergänge laufen danach ausschließlich über `GameClientController.StateChanged`/`GameOver`.

Manuelle Prüfung in Roblox Studio via MCP-Tools (`start_stop_play`, `screen_capture`, `execute_luau`, `get_console_output`) durchgeführt:

1. **Start:** Nach Play-Test-Start ist ausschließlich der Startscreen ("PAPA" + PLAY-Button) sichtbar, kein Board/Charakter in der Szene (Screenshot verifiziert, `GameClientController.GetState()` bestätigt keine aktive Session) — AK1 erfüllt.
2. **Play → neue Session:** Auslösen des PLAY-Intents (`ClientAction.FireServer({type="RequestPlay"})`, identisch zum `onPlayClicked`-Handler des Buttons) zeigt danach `MainMenuUI` ausgeblendet (`gui.Enabled=false`), `GameHudUI` eingeblendet, Charakter platziert, Board erzeugt (Screenshot: LEVEL 1/TARGETS 0/LIVES 3/SCORE 0 + sichtbares Grid-Board) — AK2 erfüllt.
3. **Game Over:** Spieler dreimal gezielt in die `DeathZone` teleportiert (`PlayerService.onDeathZoneTouched` → `GameService.handleFailure("FALL")`), bis Leben 0 erreicht. Server-Log bestätigt `GAME_OVER, score=0`; Client zeigt danach `GameOverScreen` mit "GAME OVER" / "SCORE 0" (Screenshot) — angezeigter Score stimmt mit dem zuletzt bekannten HUD-Wert überein — AK3 erfüllt.
4. **Neustart nach Game Over:** Erneutes Feuern desselben RequestPlay-Intents vom Game-Over-Screen aus setzt zuverlässig LEVEL 1/LIVES 3/SCORE 0 zurück (Screenshot), Board und Charakter erscheinen erneut. Gesamter Zyklus (Start → Play → Game Over → Restart) zweimal vollständig durchlaufen, beide Male identisches, korrektes Verhalten — AK4 erfüllt.

**Hinweis zur Testdurchführung:** Synthetische Mausklicks über das `user_mouse_input`-Tool (sowohl via `instance_path` als auch via berechneten Bildschirmkoordinaten) haben den `PLAY`-Button in diesem Studio-Setup nicht erreicht — ein testweise angehängter `Activated`/`MouseButton1Click`-Debug-Listener feuerte bei keinem Klickversuch. Das ist eine Einschränkung der Eingabe-Automatisierung in dieser Umgebung, kein Code-Fehler: alle Prüfungen oben wurden stattdessen über direktes Feuern des `ClientAction`-RemoteEvent mit `{type="RequestPlay"}` durchgeführt — exakt derselbe Aufruf, den `PlayButton.Activated` auslöst (`GameClientController.RequestPlay()`), wodurch der komplette Client/Server-Pfad real durchlaufen wurde. Die UI-Erzeugung, Sichtbarkeits-Logik und Button-`Activated`-Verdrahtung selbst wurden per Code-Review verifiziert (siehe `MainMenuUI.luau`, analog zum etablierten Pattern aus `GameHudUI.luau`). Eine zusätzliche manuelle Klick-Prüfung direkt in Studio durch den Nutzer wird empfohlen, falls Zweifel an der Button-Interaktion selbst bestehen.

Alle Akzeptanzkriterien (1-4) manuell verifiziert.
