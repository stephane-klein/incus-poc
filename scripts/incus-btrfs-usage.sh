#!/usr/bin/env bash
# Espace disque EXCLUSIF btrfs par instance incus (LXC + QEMU).
# Itère les sous-volumes réels sur disque (pas de dépendance incus).
# Lancer EN ROOT sur l'HÔTE incus (où les sous-volumes btrfs sont réels).
set -euo pipefail

POOL="${1:-default}"
BASE="/var/lib/incus/storage-pools/$POOL"

if [ ! -d "$BASE" ]; then
  echo "Pool '$POOL' introuvable dans $BASE" >&2
  exit 1
fi

printf "%-28s %-22s %14s %14s\n" "INSTANCE" "TYPE" "EXCLUSIF" "PARTAGÉ"
printf "%-28s %-22s %14s %14s\n" "--------" "----" "--------" "--------"

for dir in containers virtual-machines; do
  pdir="$BASE/$dir"
  [ -d "$pdir" ] || continue
  for path in "$pdir"/*; do
    [ -e "$path" ] || continue
    name=$(basename "$path")
    case "$dir" in
      containers)       type="CONTAINER (LXC)" ;;
      virtual-machines) type="VIRTUAL-MACHINE (QEMU)" ;;
    esac
    out=$(btrfs filesystem du -s "$path" 2>/dev/null)
    excl=$(printf '%s\n' "$out" | awk 'NF && $NF ~ /^\// {print $2; exit}')
    shar=$(printf '%s\n' "$out" | awk 'NF && $NF ~ /^\// {print $3; exit}')
    printf "%-28s %-22s %14s %14s\n" "$name" "$type" "${excl:-?}" "${shar:-?}"
  done
done

echo
echo "Usage globale du pool '$POOL' :"
btrfs filesystem du -s "$BASE" 2>/dev/null | sed 's/^/  /'
