#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT_DIR"

# Fokus auf typische echte Leaks (High-Signal), nicht auf Dokumentation oder Placeholder-Namen.
HIGH_SIGNAL_PATTERN='(BEGIN [A-Z ]*PRIVATE KEY|AKIA[0-9A-Z]{16}|ghp_[0-9A-Za-z]{36}|glpat-[0-9A-Za-z_-]{20,}|xox[baprs]-[0-9A-Za-z-]{10,})'
ASSIGNMENT_PATTERN='((token|password|secret)[^\n]{0,24}[:=][[:space:]]*["'"'"']?[A-Za-z0-9_./+=-]{8,})'
PRIVATE_INFRA_PATTERN='(10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|192\.168\.[0-9]{1,3}\.[0-9]{1,3}|172\.(1[6-9]|2[0-9]|3[0-1])\.[0-9]{1,3}\.[0-9]{1,3}|\.local\b|\.lan\b|BEGIN OPENSSH PRIVATE KEY)'

status=0

echo "[1/3] Scanne Arbeitsbaum auf typische Secret-Muster ..."
if rg -n -i --hidden --glob '!.git/**' --glob '!README.md' --glob '!scripts/prepublish-check.sh' "$HIGH_SIGNAL_PATTERN" .; then
  echo "❌ Hochkritische Secret-Muster im Arbeitsbaum gefunden."
  status=1
elif rg -n -i --hidden --glob '!.git/**' --glob '!README.md' --glob '!scripts/prepublish-check.sh' "$ASSIGNMENT_PATTERN" . \
  | rg -v '(placeholder|CHANGE_ME|sops\.|sops/|/run/secrets|example|beispiel|wheelNeedsPassword)'; then
  echo "❌ Verdächtige Secret-Zuweisungen im Arbeitsbaum gefunden."
  status=1
else
  echo "✅ Keine offensichtlichen Secret-Leaks im Arbeitsbaum gefunden."
fi

echo

echo "[2/3] Prüfe flake.lock und öffentliche Module auf private Hosts/IPs/Keys ..."
if rg -n -i "$PRIVATE_INFRA_PATTERN" flake.lock modules; then
  echo "❌ Mögliche private Infrastruktur- oder Key-Hinweise in flake.lock/modules gefunden."
  status=1
else
  echo "✅ Keine offensichtlichen privaten Hosts/IPs/Keys in flake.lock und modules gefunden."
fi

echo

echo "[3/3] Hinweis zur History-Prüfung"
echo "Führe vor dem Publish zusätzlich einen History-Scan aus:"
echo "  git log -p --all -- ."
echo "  git rev-list --all | while read c; do git grep -n -I -E '$HIGH_SIGNAL_PATTERN|token|password|secret' \"\$c\"; done"
echo "Bei Treffern: Secrets rotieren und Historie mit git filter-repo oder BFG bereinigen."

exit "$status"
