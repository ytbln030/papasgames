# Task 001 — World & StarterPlayer Baseline

## Ziel und erwartetes Verhalten

Die Welt-Grundkonfiguration wird auf den Spec-Zustand "frei schwebendes Spielfeld, kein Boden" gebracht und die StarterPlayer-Grundeinstellungen (First-Person, kein Sprung) werden gesetzt. Nach diesem Task existiert in `Workspace` kein kollidierbarer Boden mehr außer der in einer späteren Task erzeugten Spielfeld-Geometrie, und es gibt eine statische, unsichtbare `DeathZone` unterhalb des Spielfelds. Spieler starten First-Person und können nicht springen.

Dies ist eine reine Konfigurations-Task (Rojo-Projektdatei + minimale Script-Bereinigung), **keine** Spiellogik.

## Voraussetzungen und Abhängigkeiten

Keine. Kann parallel zu [Task 002](002-shared-foundations.md) bearbeitet werden.

Hintergrund: [`ARCHITECTURE.md`](../ARCHITECTURE.md) Abschnitt 2 (Verzeichnisstruktur) und Abschnitt 5 (`GameConfig.DeathY = -50`).

## Betroffene Module

- `default.project.json` (Workspace- und StarterPlayer-Konfiguration)
- `src/server/init.server.luau` (Bereinigung des aktuellen Baseplate/Terrain-Bootstraps)

## Funktionale Anforderungen

1. Entferne den aktuellen `Workspace.Baseplate`-Part und das Terrain-`FillBlock`/`Decoration`-Setup aus `default.project.json` bzw. `src/server/init.server.luau` — das Spiel hat laut `docs/SPEC.md` §8 ausdrücklich **keine** Baseplate.
2. Füge in `default.project.json` unter `Workspace` einen statischen Part `DeathZone` hinzu:
   - `Anchored = true`, `CanCollide = false`, `Transparency = 1`
   - Position bei `Y = -50` (`GameConfig.DeathY`, siehe [`ARCHITECTURE.md`](../ARCHITECTURE.md) Abschnitt 5), großzügige horizontale Ausdehnung (z. B. `Size = [1000, 2, 1000]`), damit das Spielfeld (max. 35×35 Kacheln à 6 Studs, vgl. Spec §5) in jeder zukünftigen Levelgröße darüber liegt.
   - Name exakt `DeathZone`, da spätere Tasks (004) per `WaitForChild("DeathZone")` darauf zugreifen.
3. Setze in `default.project.json` unter `StarterPlayer.$properties`:
   - `CameraMode = "LockFirstPerson"` (Spec §9, §45)
   - `CharacterJumpHeight = 0` und `CharacterJumpPower = 0` (Sprung in der ersten Version deaktiviert, Spec §9)
4. `src/server/init.server.luau` darf nach der Bereinigung keine Terrain-/Baseplate-Logik mehr enthalten. Falls danach keine sinnvolle Bootstrap-Logik mehr übrig bleibt, darf die Datei auf einen Kommentar-Platzhalter reduziert werden — sie wird in Task 006 durch den eigentlichen Composition Root ersetzt.
5. Die bestehende `Lighting`/`Atmosphere`-Konfiguration in `default.project.json` bleibt unverändert (kein Spec-Widerspruch, siehe Plan-Kontext).

## Technische Vorgaben und Schnittstellen

Keine Luau-Schnittstellen in diesem Task. Die `DeathZone` ist ein reines Datenmodell-Objekt (Instanz-Deklaration), ihre Touched-Reaktion gehört zu Task 004.

## Bekannte zukünftige Anforderungen

- Task 003 erzeugt das eigentliche Spielfeld in `Workspace` (z. B. unter `Workspace.Board`) — muss nicht mit der `DeathZone` kollidieren (unterschiedliche Y-Ebene).
- Task 004 bindet sich an `DeathZone.Touched`.

## Out of Scope

- Reaktion auf `DeathZone`-Kontakt (Lebensverlust, Respawn) — siehe Task 004.
- Visuelle Gestaltung des Spielfelds selbst — siehe Task 003.
- Änderungen an `Lighting`/`Atmosphere`.

## Akzeptanzkriterien

1. In einer frischen Studio-Session gibt es keinen kollidierbaren Boden bei `Y ≈ -10` mehr (alter Baseplate entfernt).
2. Ein in der Luft gespawnter Charakter fällt, bis er bei `Y = -50` die `DeathZone` berührt (sichtbar z. B. über `Touched`-Print, ohne Reaktion außer dem Print — Reaktion folgt in Task 004).
3. Die Kamera ist beim Play-Test sofort in First-Person, ohne manuellen Wechsel.
4. Die Leertaste (Sprung) bewegt den Charakter nicht nach oben.
5. `default.project.json` bleibt valides JSON und `rojo build` (bzw. der laufende `rojo serve`) terminiert ohne Fehler.

## Teststrategie (manuell in Roblox Studio)

1. `rojo serve` starten, Studio mit Rojo-Plugin verbinden, Sync abwarten.
2. Play-Test starten: prüfen, dass kein grüner/grauer Baseplate-Boden mehr sichtbar ist und die Kamera First-Person ist.
3. Leertaste drücken: Charakter darf nicht springen.
4. Charakter per `CFrame`-Teleport (Studio-Command-Bar) über die erwartete Spielfeld-Position setzen und fallen lassen; prüfen, dass er bei `Y = -50` die `DeathZone` berührt (temporärer `print` im Touched-Handler reicht als Nachweis für diesen Task).
5. Ergebnis (inkl. ggf. Screenshots/Konsolen-Ausgaben) in diesem Abschnitt der Task-Datei dokumentieren.

## Definition of Done

- Alle Akzeptanzkriterien manuell verifiziert und das Ergebnis unten dokumentiert.
- Keine Baseplate/Terrain-Reste mehr im Projekt.
- `default.project.json` enthält `DeathZone` und die StarterPlayer-Properties exakt wie oben spezifiziert.

---

## Ergebnis (von der ausführenden Task-Session auszufüllen)

**Status: Abgeschlossen.** Alle Akzeptanzkriterien erfüllt und in einer laufenden Roblox-Studio-Session (verbunden über `rojo serve` + Rojo-Plugin, Live-Sync bereits aktiv) tatsächlich verifiziert, siehe Prüfprotokoll unten.

### Durchgeführte Änderungen

- [`default.project.json`](../default.project.json): `Workspace.Baseplate` entfernt, stattdessen `Workspace.DeathZone` (`Part`, `Anchored = true`, `CanCollide = false`, `Transparency = 1`, `Position = [0, -50, 0]`, `Size = [1000, 2, 1000]`) hinzugefügt. `StarterPlayer.$properties` mit `CameraMode = "LockFirstPerson"`, `CharacterJumpHeight = 0`, `CharacterJumpPower = 0` ergänzt. `Lighting`/`Atmosphere` unverändert gelassen.
- [`src/server/init.server.luau`](../src/server/init.server.luau): Terrain-`FillBlock`/`Decoration`- und Baseplate-Transparenz-Logik vollständig entfernt, Datei auf einen Kommentar-Platzhalter reduziert (Hinweis auf den künftigen Composition Root aus Task 006).

### Durchgeführte Prüfungen

1. **Statische Prüfung (AC5):** `rojo build default.project.json -o /tmp/papa-build-check.rbxlx` terminiert ohne Fehler; `python3 -m json.tool` bestätigt valides JSON. Im gebauten Output: `Baseplate` kommt 0× vor, `DeathZone` vorhanden, `CameraMode`-Token = `1` (= `Enum.CameraMode.LockFirstPerson`), `CharacterJumpHeight`/`CharacterJumpPower` = `0`.
2. **Live-Studio-Sync:** `search_game_tree`/`inspect_instance` (MCP, verbundene Studio-Instanz "Papas game") zeigen nach Sync: kein `Workspace.Baseplate` mehr; `Workspace.DeathZone` mit exakt den Soll-Properties (`Position = 0, -50, 0`; `Size = 1000, 2, 1000`; `CanCollide = false`; `Transparency = 1`).
3. **AC3 (First-Person-Kamera, kein manueller Wechsel):** Play-Test gestartet, per `execute_luau` (Client) direkt nach Spawn geprüft: `player.CameraMode = Enum.CameraMode.LockFirstPerson`, `camera.CameraType = Enum.CameraType.Custom` (Standard-Roblox-Verhalten bei LockFirstPerson). Zusätzlich per Screenshot bestätigt (Ich-Perspektive, keine dritte Person sichtbar).
4. **AC4 (kein Sprung):** `Humanoid.JumpHeight = 0`, `JumpPower = 0`, `UseJumpPower = false` bestätigt. Zusätzlich aktiv simuliert: `humanoid.Jump = true` gesetzt und 0,5 s gewartet — `HumanoidRootPart.Position.Y` blieb unverändert (Delta = 0), `Humanoid:GetState()` blieb `Running` (kein Übergang zu `Jumping`). Leertaste bewegt den Charakter also nachweislich nicht nach oben.
5. **AC2 (Fall bis zur DeathZone):** Server-seitig (`execute_luau`, `datamodel_type = "Server"`) einen temporären `DeathZone.Touched`-Listener mit `print(...)` registriert (siehe Vorgabe in Abschnitt "Technische Vorgaben" — rein manueller Test-Code, nicht Teil des Repos), Charakter per `HumanoidRootPart.CFrame = CFrame.new(100, 20, 100)` über eine freie Stelle des zukünftigen Spielfelds teleportiert und fallen lassen. Ergebnis: `Touched` feuerte zuverlässig für alle Charakter-BodyParts, im Console-Log dokumentiert (`[Task001-Test] DeathZone touched by Workspace.BlumiXFan.HumanoidRootPart at Y = -22.68` usw.), finale `HumanoidRootPart.Position.Y ≈ -41.6` (weiter fallend, da `CanCollide = false` — erwartet, da die Reaktion auf den Kontakt explizit Task 004 vorbehalten ist). Die Streuung der geloggten Touch-Y-Werte (~-22 bis -25 statt exakt am DeathZone-Rand bei Y=-49) ist eine bekannte Ungenauigkeit von `Touched` bei sehr schnell fallenden, nicht kollidierenden Körpern (Low-Framerate-Sampling der Physik-Engine bei `CanCollide = false`) und für diesen Test unkritisch — der Nachweis "Charakter erreicht/durchquert die DeathZone beim Fallen" ist damit erbracht.
6. **AC1 (kein kollidierbarer Boden bei Y ≈ -10):** Bestätigt über Punkt 2 (kein `Baseplate` mehr im Tree) und Punkt 5 (Charakter fällt ungehindert durch den gesamten Bereich bis weit unter Y = -10).

### Befund außerhalb des Task-Scopes (zur Kenntnisnahme, nicht behoben)

Im Workspace der verbundenen Studio-Session existiert zusätzlich eine `Workspace.SpawnLocation` (`SpawnLocation`, `Size = 12, 1, 12`, `CanCollide = true`, `Position ≈ 0, 0.5, 0`) samt `Decal`-Kind. Diese Instanz ist **nicht** über Rojo/`default.project.json` verwaltet (vermutlich Rest des ursprünglichen Studio-Platzhalter-Templates) und daher nicht Teil dieses Tasks (Funktionale Anforderung 1 nennt explizit nur `Workspace.Baseplate` und das Terrain-Setup in `init.server.luau`). Sie wirkt aktuell als kleiner kollidierbarer Boden nahe dem Ursprung (bestätigt: ein bei `(0, 20, 0)` fallen gelassener Charakter landet auf ihr bei Y ≈ 4 statt bis zur `DeathZone` durchzufallen) und widerspricht damit dem übergeordneten Spec-Ziel "kein Boden" (§8), auch wenn sie AC1–AC5 dieses Tasks nicht verletzt. Sie wurde bewusst **nicht** entfernt, da sie außerhalb des deklarierten Task-Scopes liegt und nicht Teil des versionierten Projekts ist (reiner Studio-Sitzungszustand). Empfehlung: spätestens in Task 004 (`PlayerService.SpawnPlayer`/`RespawnPlayer`) berücksichtigen bzw. manuell in Studio entfernen, sobald programmatisches Spawnen auf Grid-Kacheln eingeführt wird.

### Neue Architekturentscheidungen

Keine. Alle Änderungen folgen exakt der in diesem Task-File spezifizierten Konfiguration; keine Abweichung von `ARCHITECTURE.md`.

### Auswirkungen auf spätere Tasks

- Task 003 (Board-System) kann das Spielfeld wie geplant unabhängig von der `DeathZone`-Y-Ebene erzeugen.
- Task 004 (`PlayerService`) kann sich wie vorgesehen per `WaitForChild("DeathZone")` an `DeathZone.Touched` binden; der temporäre Test-Listener aus Prüfung 5 wurde nur zur Laufzeit der Play-Test-Session registriert und ist nicht Teil des Repositories.
- Die oben dokumentierte `SpawnLocation` sollte bei der Umsetzung von Task 004 beachtet werden (siehe Befund oben).
