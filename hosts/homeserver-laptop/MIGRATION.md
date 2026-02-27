# Homeserver Migration-Runbook

## 1) BTRFS-Layout / Mountpunkte

Die Storage-Disks sind als BTRFS mit dedizierten Subvolumes aufgebaut:

- `/srv/storage/4tb/data`
- `/srv/storage/4tb/snapshots`
- `/srv/storage/4tb/backups`
- `/srv/storage/8tb/data`
- `/srv/storage/8tb/snapshots`
- `/srv/storage/8tb/backups`

Snapshots können z. B. mit `btrfs subvolume snapshot` nach `.../snapshots` geschrieben werden, Backup-Exporte nach `.../backups`.

## 2) Samba

Definierte Freigaben:

- `media` → `/srv/storage/8tb/data/media`
- `backups` → `/srv/storage/4tb/backups`
- `apps` → `/srv/storage/8tb/data/apps`

Nach dem ersten Deploy Samba-User setzen (einmalig):

```bash
sudo smbpasswd -a admin
```

## 3) HomeAssistant VM (libvirt/qemu)

Verzeichnis für Disks:

- `/var/lib/libvirt/images/homeassistant`

### Import eines vorhandenen Images

Beispiel mit bestehendem QCOW2-Image aus Backup:

```bash
sudo cp /srv/storage/4tb/backups/homeassistant/homeassistant.qcow2 /var/lib/libvirt/images/homeassistant/
sudo chown libvirt-qemu:kvm /var/lib/libvirt/images/homeassistant/homeassistant.qcow2
sudo chmod 0640 /var/lib/libvirt/images/homeassistant/homeassistant.qcow2
```

VM registrieren (Beispiel):

```bash
sudo virt-install \
  --name homeassistant \
  --memory 4096 \
  --vcpus 2 \
  --import \
  --disk /var/lib/libvirt/images/homeassistant/homeassistant.qcow2,format=qcow2,bus=virtio \
  --os-variant generic \
  --network network=default,model=virtio \
  --graphics none \
  --noautoconsole
```

## 4) Container-Migration aus Backup

Zielpfade:

- Traefik: `/srv/storage/8tb/data/apps/traefik`
- Paperless: `/srv/storage/8tb/data/apps/paperless/{data,media,export,consume}`
- Emby: `/srv/storage/8tb/data/apps/emby/config`
- Transmission: `/srv/storage/8tb/data/apps/transmission`
- Heimdall: `/srv/storage/8tb/data/apps/heimdall/config`

### Datenübernahme

1. Backup-Inhalte in die Zielpfade kopieren (`rsync -aHAX --numeric-ids ...`).
2. Ownership korrigieren (falls Container vorher nicht root liefen):
   - Media-Daten: Gruppe `media`
   - App-Konfigurationen: je nach Dienst (hier standardmäßig `root`)
3. Prüfen, dass OpenVPN-Credentials via sops-template vorliegen (`openvpn-auth.txt`).

### Netzwerke / Reihenfolge

Der deklarative Stack nutzt Host-Networking (`--network=host`) für die Services und startet die Abhängigkeiten in definierter Reihenfolge.
Empfohlene Start-Reihenfolge bei Erstmigration:

1. `paperless-broker`, `paperless-gotenberg`, `paperless-tika`
2. `paperless-ngx`
3. `traefik`, `heimdall`, `emby`, `transmission-openvpn`

Auf NixOS erfolgt das über den normalen Switch:

```bash
sudo nixos-rebuild switch --flake .#homeserver-laptop
```
