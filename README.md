# Nix-Chattie-Infra

Diese Repository-Struktur verwaltet mehrere NixOS-Hosts über eine gemeinsame Flake.

## Struktur

- `flake.nix` / `flake.lock`: zentrale Inputs und Outputs
- `hosts/<hostname>/configuration.nix`: host-spezifische NixOS-Konfiguration
- `hosts/<hostname>/disko.nix`: host-spezifische Disk-Layouts für Disko
- `modules/nixos/`: wiederverwendbare Basismodule (Netzwerk, SSH, Nutzer, Monitoring)
- `homes/`: Home-Manager-Profile für Client-Geräte

## Secrets & Access

Zugangsdaten (insbesondere SSH-Authorized-Keys) werden **nicht** global im Shared-Modul erzwungen.

- SSH-Keys müssen host-spezifisch (z. B. in `hosts/<hostname>/configuration.nix`) oder in privaten, nicht versionierten Overlays eingebunden werden.
- Benutzerdefinitionen und privilegierte Gruppen (z. B. `wheel`) sollen explizit pro Host gesetzt werden.
- Der gemeinsame Default setzt nur `security.sudo.wheelNeedsPassword = true` (via `lib.mkDefault`), sodass Passwort-loses `sudo` nicht versehentlich global aktiviert wird.

## Enthaltene Hosts

- `rpi5-klipper-1`
- `rpi5-klipper-2`
- `homeserver-laptop`
- `vps`
- `client-laptop`
- `tablet`
- `gaming-pc`

## Build- und Deploy-Kommandos

### NixOS-Konfiguration bauen

```bash
nix build .#nixosConfigurations.<host>.config.system.build.toplevel
```

### Direkt auf ein Zielsystem anwenden

```bash
sudo nixos-rebuild switch --flake .#<host>
```

### Remote-Deploy (Beispiel)

```bash
sudo nixos-rebuild switch --flake .#<host> --target-host root@<ip-or-hostname>
```

### Home-Manager-Konfiguration bauen

```bash
nix build .#homeConfigurations."admin@<client-host>".activationPackage
```

### Home-Manager direkt anwenden

```bash
home-manager switch --flake .#admin@<client-host>
```

## Disko initialisieren

> **Achtung:** Disko überschreibt Partitionstabellen und Dateisysteme. Gerätepfade in `hosts/<hostname>/disko.nix` vorab auf die echten IDs anpassen.

1. Zielhost wählen und Layout prüfen:

```bash
nix eval .#nixosConfigurations.<host>.config.disko.devices --json | jq
```

2. Partitionierung + Formatierung anwenden (destruktiv):

```bash
sudo nix run github:nix-community/disko -- --mode disko --flake .#<host>
```

3. Optional nur mounten (z. B. nach Reboot im Installer):

```bash
sudo nix run github:nix-community/disko -- --mode mount --flake .#<host>
```

4. Danach NixOS installieren/aktivieren:

```bash
sudo nixos-install --flake .#<host>
# oder auf bestehendem System
sudo nixos-rebuild switch --flake .#<host>
```

## Secret-Management mit sops-nix

Für Service-Hosts (`homeserver-laptop`, `vps`) ist `sops-nix` als Modul eingebunden. Die zentrale Moduldefinition liegt in `modules/nixos/secrets/sops.nix`.

### Dateien

- `.sops.yaml`: `age`-Empfänger und `creation_rules`
- `secrets/common.yaml`: gemeinsame Secrets (SMB, Container, VPN)
- `secrets/homeserver.yaml`: Homeserver-spezifische App-Secrets
- `secrets/vps.yaml`: VPS-spezifische App-Secrets

### Key-Setup (age)

1. Admin-Key erzeugen (lokal, **nicht committen**):

```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
```

2. Host-Key auf jedem Host erzeugen (wird durch `sops.age.generateKey = true` automatisch unter `/var/lib/sops-nix/key.txt` angelegt).

3. Öffentliche `age1...`-Keys aus Admin- und Host-Keys in `.sops.yaml` eintragen.

4. Secret-Dateien immer über `sops` bearbeiten:

```bash
sops secrets/common.yaml
sops secrets/homeserver.yaml
sops secrets/vps.yaml
```

> Platzhalterwerte `CHANGE_ME_ENCRYPTED` müssen durch echte, verschlüsselte Werte ersetzt werden.

## Domaincontroller (homeserver-laptop)

Der Homeserver ist als Samba AD Domain Controller für `chaos4all.de` vorbereitet:

- Realm: `CHAOS4ALL.DE`
- NetBIOS/Domain: `CHAOS4ALL`
- Samba AD Provisioning läuft einmalig über ein Activation Script, sobald `sam.ldb` noch nicht existiert.
- Das initiale Administrator-Passwort kommt aus `secrets/homeserver.yaml` unter `ad.domain-admin-password`.

Nach dem ersten Deploy sollten DNS/NTP auf den DC zeigen und Clients der Domain beitreten.

## Pre-Publish-Check (vor öffentlichem Push/Release)

Vor jedem öffentlichen Push/Release sollte ein kurzer Leak-Check laufen.

### 1) Arbeitsbaum auf Secret-Muster prüfen

Suche nach typischen Mustern wie `PRIVATE KEY`, `token`, `password`, `secret`, `AKIA...` etc.:

```bash
rg -n -i --hidden --glob '!.git/**' \
  '(PRIVATE KEY|BEGIN [A-Z ]*PRIVATE KEY|\btoken\b|\bpassword\b|\bsecret\b|AKIA[0-9A-Z]{16})' .
```

Optional gibt es dafür ein Script:

```bash
./scripts/prepublish-check.sh
```

### 2) Nicht nur HEAD prüfen: Git-History scannen

Ein sauberer aktueller Stand reicht nicht aus, wenn Secrets früher committed wurden.

```bash
git log -p --all -- .
git rev-list --all | while read c; do
  git grep -n -I -E '(PRIVATE KEY|token|password|AKIA[0-9A-Z]{16})' "$c"
done
```

Wenn Treffer in der History auftauchen:

1. Betroffene Secrets **sofort rotieren**.
2. Historie bereinigen (z. B. mit `git filter-repo`, alternativ BFG Repo-Cleaner).
3. Bereinigte Historie forciert pushen und Betroffene informieren.

### 3) Zusätzliche Policy für öffentliche Inhalte

- `flake.lock` darf keine privaten Hosts, privaten IP-Bereiche oder Schlüsselmaterial enthalten.
- Öffentliche Module unter `modules/` dürfen keine privaten Hosts/IPs/Keys hardcoden.
- Private Infrastruktur-Details gehören in private Overlays/Secrets, nicht ins öffentliche Repo.
