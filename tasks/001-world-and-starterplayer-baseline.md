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

_Noch nicht ausgeführt._
