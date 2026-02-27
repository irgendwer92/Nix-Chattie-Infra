# Nix-Chattie-Infra

Diese Repository-Struktur verwaltet mehrere NixOS-Hosts über eine gemeinsame Flake.

## Struktur

- `flake.nix` / `flake.lock`: zentrale Inputs und Outputs
- `hosts/<hostname>/configuration.nix`: host-spezifische NixOS-Konfiguration
- `hosts/<hostname>/disko.nix`: host-spezifische Disk-Layouts für Disko
- `modules/nixos/`: wiederverwendbare Basismodule (Netzwerk, SSH, Nutzer, Monitoring)
- `homes/`: Home-Manager-Profile für Client-Geräte

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
