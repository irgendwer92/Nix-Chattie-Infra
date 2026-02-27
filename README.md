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
