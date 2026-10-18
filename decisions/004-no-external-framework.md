# 004 — Kein externes Gameplay-Framework (z. B. Knit)

## Kontext

Frameworks wie Knit bieten fertige Service/Controller-Patterns inklusive Netzwerk-Abstraktion und würden Boilerplate reduzieren. Sie sind aber eine zusätzliche Abhängigkeit mit eigener Lernkurve und reduzieren die Transparenz des Codes für Agenten, die ohne Chat-Kontext an einzelnen Tasks arbeiten.

## Entscheidung

Es wird kein externes Gameplay-Framework verwendet. Services und Controller sind einfache Luau-Module (Tabellen mit Funktionen), die über einen manuellen Composition Root (`init.server.luau` / `init.client.luau`) per `require` verdrahtet werden (siehe `ARCHITECTURE.md` Abschnitt 3).

## Begründung

- Entspricht Grundprinzip "Overengineering vermeiden" aus `docs/001-MASTER_PROMPT_ARCHITEKT.md`.
- Volle Transparenz: Ein Agent, der nur eine einzelne Task-Datei und `ARCHITECTURE.md` kennt, kann den gesamten Kontrollfluss nachvollziehen, ohne Framework-Dokumentation zu kennen.
- Der Umfang des MVP (ca. 5 Server-Module, 5 Client-Module) rechtfertigt keine Framework-Einführung.

## Konsequenz

- Kein neuer Rokit-/Wally-Eintrag für ein Gameplay-Framework.
- Sollte sich im Rahmen der Multiplayer-Erweiterung (Backlog 017) herausstellen, dass ein Framework signifikanten Mehrwert bietet, muss diese Entscheidung explizit revidiert und neu dokumentiert werden.
