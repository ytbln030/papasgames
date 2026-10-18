# Task 009 — Input Controller

## Ziel und erwartetes Verhalten

`InputController` ermöglicht dem Spieler, über `E` (PC) oder einen automatisch erzeugten mobilen Button eine Bombenplatzierung auszulösen. Nach diesem Task kann ein Spieler die Bombenplatzierung real über Tastatur/Touch auslösen, statt sie über die Studio-Command-Bar zu simulieren.

## Voraussetzungen und Abhängigkeiten

[Task 002](002-shared-foundations.md) (`Net`-Contract). Kann sehr früh starten und parallel zu praktisch allen anderen Tasks ab Phase 1 bearbeitet werden — der eigentliche Effekt (Bombe erscheint) ist erst nach [Task 006](006-networking-and-state-machine.md)/[007](007-bomb-and-explosion.md) sichtbar, der Code selbst hat aber keine weiteren Abhängigkeiten.

## Betroffene Module

- `src/client/Controllers/InputController.luau` (neu)

## Funktionale Anforderungen

1. Bindet eine Aktion `"PlaceBomb"` über `ContextActionService:BindActionAtPriority(...)` an die Taste `E` (Spec §18) **und** lässt dabei automatisch einen mobilen Touch-Button erzeugen (`createTouchButton = true` im Bind-Aufruf — kein manuell gebautes Button-UI nötig, Spec §18 "Mobile: BOMB-Button").
2. Bei Aktivierung (egal ob Taste oder Touch-Button, `Enum.UserInputState.Begin`) feuert `InputController` `Net`'s `ClientAction`-Remote mit `{ type = Net.ClientActionType.PlaceBomb }`.
3. Pro Tastendruck/Button-Tap wird die Aktion genau einmal gefeuert (kein Repeat-Spam bei gehaltener Taste — `ContextActionService` liefert dafür bereits `Begin`/`End`/`Change`, nur auf `Begin` reagieren).
4. Der Button-Titel ist `"BOMB"` (Spec §18).

## Technische Vorgaben und Schnittstellen

- Nutzt ausschließlich `Net.luau` aus Task 002 für das Remote-Firing, keine direkten `RemoteEvent:FireServer`-Aufrufe mit rohen Strings.
- Keine Abhängigkeit auf `GameClientController` — `InputController` ist eine reine Eingabe-zu-Intent-Übersetzung, unabhängig vom lokalen Spielzustand (der Server validiert ohnehin, ob die Aktion gerade erlaubt ist, siehe `ARCHITECTURE.md` Abschnitt 1, Server-autoritativ).

## Bekannte zukünftige Anforderungen

- Controller-Support (Spec §18 "später könnte ein Controller-Button ergänzt werden") — `ContextActionService`-Bindings unterstützen Gamepad-Tasten grundsätzlich bereits über zusätzliche `Enum.KeyCode`-Einträge in derselben Bind-Aufruf, keine Strukturänderung nötig, wenn das später ergänzt wird.

## Out of Scope

- Serverseitige Validierung, ob eine Bombe gerade platziert werden darf (liegt in `BombService`/`GameService`, Task 006/007).
- Visuelles Feedback der Platzierung (Task 012).

## Akzeptanzkriterien

1. `E`-Taste löst genau einmal pro Druck die Bomben-Intent-Aktion aus.
2. Auf einem simulierten mobilen Gerät (Studio "Device"-Emulation) erscheint automatisch ein "BOMB"-Touch-Button, der dieselbe Aktion auslöst.
3. Gehaltene `E`-Taste löst die Aktion nicht wiederholt mehrfach pro Sekunde aus.
4. Ohne laufende Session (State `MENU`) löst die Taste weiterhin ein `ClientAction`-Remote aus (Client sendet immer den Intent) — die Ablehnung erfolgt serverseitig, nicht durch Unterdrückung im `InputController`.

## Teststrategie (manuell in Roblox Studio)

1. Play-Test starten, `E`-Taste drücken, über ein temporäres Server-Print bestätigen, dass genau ein `ClientAction`-Event mit `type = "PlaceBomb"` ankommt.
2. `E`-Taste für 3 Sekunden gedrückt halten, Anzahl der ankommenden Events zählen (muss 1 sein).
3. Studio-Gerät-Emulation auf ein Touch-Gerät umstellen, prüfen, dass ein "BOMB"-Button erscheint und beim Tippen dasselbe Event auslöst.
4. Ergebnis dokumentieren.

## Definition of Done

- `InputController.luau` implementiert und im Client-Composition-Root (`init.client.luau`) gestartet.
- Alle Akzeptanzkriterien manuell verifiziert und dokumentiert.

---

## Ergebnis (von der ausführenden Task-Session auszufüllen)

_Noch nicht ausgeführt._
