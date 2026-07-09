# Sonarex

Sonarex ist eine iOS-Musikplayer-App fuer eigene Navidrome- bzw. Subsonic-kompatible Musikserver. Die App synchronisiert Musik-Metadaten, Playlists und Favoriten, streamt Songs vom eingetragenen Server und speichert die lokalen App-Daten mit SwiftData. Das Serverpasswort wird nicht im Repository abgelegt, sondern zur Laufzeit im iOS-Keychain gespeichert.

## Aktueller Projektstand

- SwiftUI-App mit SwiftData-Persistenz
- Navidrome/Subsonic-Anbindung fuer Sync, Suche, Streaming, Favoriten und Playlists
- AVFoundation/MediaPlayer fuer Wiedergabe, Remote Commands und Sperrbildschirm-Integration
- Premium-/StoreKit-Struktur fuer eingeschraenkte Funktionen
- Datenschutz- und AGB-Texte in `Sonarex/Core/Resources/`
- Unit Tests in `SonarexTests/`
- UI- und Accessibility-Test in `SonarexUITests/`

## Voraussetzungen

- macOS mit Xcode, das iOS 26.5 Simulator Runtime enthaelt
- Swift 6
- iOS Simulator mit iOS 26.5, z. B. `iPhone 17`
- Optional: eigener Navidrome- oder Subsonic-kompatibler Server

Das Projekt ist auf aktuelle iOS-/SDK-Nutzung ausgelegt. App-, Unit-Test- und UI-Test-Targets sind auf iOS 26.5 konfiguriert. Wenn auf einem anderen Rechner nur eine aeltere Simulator Runtime installiert ist, schlagen UI-Tests mit einem Deployment-Target/Simulator-Mismatch fehl.

## Projektstruktur

- `Sonarex/` - App-Code, Views, Models, Remote Services und Ressourcen
- `SonarexTests/` - Unit Tests fuer Modelle, Services und zentrale Logik
- `SonarexUITests/` - UI-Tests und Accessibility Audit
- `Sonarex.xcodeproj/` - Xcode-Projekt
- `Unterlagen/` - begleitende Projektunterlagen

## Start in Xcode

1. Repository klonen oder als ZIP entpacken.
2. `Sonarex.xcodeproj` in Xcode oeffnen.
3. Scheme `Sonarex` auswaehlen.
4. Einen iOS-26.5-Simulator auswaehlen, z. B. `iPhone 17`.
5. App mit `Run` starten.

Beim ersten Start legt die App Demo-Daten an, damit die Oberflaeche auch ohne echten Server sichtbar ist. Fuer echte Musikdaten in den Einstellungen einen Navidrome-Server eintragen und synchronisieren.

## Build per Terminal

```bash
xcodebuild build \
  -scheme Sonarex \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5'
```

Falls der Simulator auf dem Zielrechner anders heisst, kann der Name angepasst werden. Wichtig ist, dass die iOS-Version zum Deployment Target passt.

## Tests

Alle Tests:

```bash
xcodebuild test \
  -scheme Sonarex \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5'
```

Nur Unit Tests:

```bash
xcodebuild test \
  -scheme Sonarex \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:SonarexTests
```

Nur UI-/Accessibility-Tests:

```bash
xcodebuild test \
  -scheme Sonarex \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' \
  -only-testing:SonarexUITests
```

Der Accessibility-Test nutzt `performAccessibilityAudit`. Er erzeugt einen Audit-Anhang mit gefundenen Hinweisen. Je nach Simulator- und Xcode-Version koennen in der Konsole zusaetzliche Simulator-Warnungen erscheinen, etwa zu Audio, WebKit/WebCore oder Accessibility-Bundles. Solche Meldungen sind nicht automatisch App-Fehler; entscheidend ist, ob der Test fehlschlaegt oder die App reproduzierbar abstuerzt.

## Navidrome-Zugangsdaten

Fuer echte Server-Nutzung muessen in der App eingetragen werden:

- Server-URL
- Benutzername
- Passwort

Das Passwort wird lokal im iOS-Keychain gespeichert. Es wird nicht in Git, Testdaten oder Projektdateien eingecheckt. Die Subsonic-Authentifizierung nutzt tokenbasierte Requests; das Klartextpasswort wird dabei nicht als URL-Parameter uebertragen.

## Datenschutz und Ressourcen

Die rechtlichen Texte liegen unter:

- `Sonarex/Core/Resources/AGB.txt`
- `Sonarex/Core/Resources/Privacy.txt`
- `Sonarex/Core/Resources/LegalContact.example.txt`

Private Kontakt- oder Zugangsdaten sollten nicht in diese Dateien eingetragen werden, solange das Repository abgegeben oder geteilt wird.

## Abgabe / Weitergabe

Empfohlen ist die Weitergabe ueber Git, damit der aktuelle Stand nachvollziehbar bleibt:

```bash
git status
git add .
git commit -m "Finaler Abgabestand"
git push
```

Zusätzlich kann ein sauberes ZIP aus dem Git-Stand erzeugt werden:

```bash
git archive --format zip --output Sonarex.zip HEAD
```

Dieses ZIP enthaelt nur versionierte Projektdateien und keine lokalen Build-Artefakte wie DerivedData, Simulator-Daten oder persoenliche Xcode-Caches.

## Hinweise fuer Bewertende

- Hauptscheme: `Sonarex`
- App Bundle Identifier: `com.cloudresiliencelab.msd.sonarex`
- Unit-Test-Target: `SonarexTests`
- UI-Test-Target: `SonarexUITests`
- Empfohlener Simulator: iPhone 17 mit iOS 26.5
- Keine externen Package-Installationsschritte erforderlich
