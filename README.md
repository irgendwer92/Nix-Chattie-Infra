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

`flake.nix` bindet `sops-nix` als Input ein, und das Modul `modules/nixos/secrets.nix` stellt Secrets deklarativ unter `/run/secrets/...` bereit.

### Privater Pfadstandard

Nicht versionierte Secret-Dateien liegen lokal unter:

- `secrets/private/common.yaml`
- `secrets/private/homeserver-laptop.yaml`
- `secrets/private/vps.yaml`

Die komplette Struktur `secrets/private/` ist in `.gitignore` eingetragen.

### Kurz-Workflow

1. **Secret anlegen/verschlüsseln**

```bash
mkdir -p secrets/private
sops secrets/private/common.yaml
sops secrets/private/homeserver-laptop.yaml
sops secrets/private/vps.yaml
```

2. **Auf dem Host entschlüsseln lassen**

- Auf dem Zielhost sorgt `sops-nix` mit dem Host-Key (`/var/lib/sops-nix/key.txt`) für die Entschlüsselung.
- Deklarierte Secrets landen zur Laufzeit unter `/run/secrets/...` (z. B. `/run/secrets/smb-password`, `/run/secrets/openvpn.env`).

3. **Konfiguration deployen**

```bash
sudo nixos-rebuild switch --flake .#<host>
```

## Domaincontroller (homeserver-laptop)

Der Homeserver ist als Samba AD Domain Controller für `chaos4all.de` vorbereitet:

- Realm: `CHAOS4ALL.DE`
- NetBIOS/Domain: `CHAOS4ALL`
- Samba AD Provisioning läuft einmalig über ein Activation Script, sobald `sam.ldb` noch nicht existiert.
- Das initiale Administrator-Passwort kommt aus `secrets/private/homeserver-laptop.yaml` unter `ad.domain-admin-password`.

Nach dem ersten Deploy sollten DNS/NTP auf den DC zeigen und Clients der Domain beitreten.
