# ~/.omega_wand.zsh
# Session-level Ω cache vortex + wand/lock helpers
# Key lives in RAM (this shell env) until you explicitly lock.

omega_vortex_unlock_session() {
  if [[ -n "${OMEGA_BANK_PASSPHRASE-}" ]]; then
    printf '[unlock] cache vortex already primed in this shell.\n' >&2
    return 0
  fi

  printf '\n'
  printf '∞*!∞*!∞*!∞*!∞*!∞*!∞*!∞*!∞*!\n'
  printf '          O M E G A   V O R T E X\n'
  printf '          S E S S I O N   C A C H E\n'
  printf '                 ↓\n'
  printf '          paste the master key\n'
  printf '     (it will live in this shell only)\n'
  printf '∞*!∞*!∞*!∞*!∞*!∞*!∞*!∞*!∞*!\n'
  printf '\n'
  printf '  VORTEX INPUT (hidden): '

  local _omega_passphrase
  IFS= read -r -s _omega_passphrase
  printf '\n\n'

  if [[ -z "${_omega_passphrase}" ]]; then
    printf '[unlock] empty passphrase; cache vortex not set.\n' >&2
    return 1
  fi

  export OMEGA_BANK_PASSPHRASE="${_omega_passphrase}"
  unset _omega_passphrase

  printf '[unlock] cache vortex primed in this shell (OMEGA_BANK_PASSPHRASE).\n' >&2
  return 0
}

omega_vortex_lock_session() {
  if [[ -z "${OMEGA_BANK_PASSPHRASE-}" ]]; then
    printf '[lock] cache vortex already empty in this shell.\n' >&2
    return 0
  fi

  unset OMEGA_BANK_PASSPHRASE
  printf '[lock] cache vortex cleared from this shell.\n' >&2
  return 0
}

# Main spell: wand
wand() {
  # Your Ω root
  local root="$HOME/dlog"

  if [[ ! -d "$root" ]]; then
    printf '[wand] ~/dlog does not exist.\n' >&2
    return 1
  fi

  # If no key in this shell yet, summon the vortex ONCE
  if [[ -z "${OMEGA_BANK_PASSPHRASE-}" ]]; then
    omega_vortex_unlock_session || return 1
  fi

  # Now cast refold.command wand with the key inherited in env
  ( cd "$root" && ./refold.command wand "$@" )
}

# Lock command: clear the key so the next wand will prompt again
lock() {
  omega_vortex_lock_session
}
