{ lib, ... }:
{
  # Keine globalen Benutzer- oder Zugangsdefaults im Shared-Modul erzwingen.
  # Benutzer, SSH-Keys und Gruppenmitgliedschaften werden host-spezifisch definiert.

  security.sudo.wheelNeedsPassword = lib.mkDefault true;
}
