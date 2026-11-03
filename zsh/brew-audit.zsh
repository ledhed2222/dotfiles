# brew-audit: top-level Homebrew installs the Brewfile doesn't list. Reports,
# never acts. `brew leaves --installed-on-request` skips dependencies, unlike
# `brew bundle cleanup`. Each one is worth adding to the Brewfile (every
# machine), fine as this machine's own, or a `brew uninstall`.
# Plain enough for bash too: make.sh sources this and runs it at the end.
brew-audit() {
  local formulae casks
  formulae=$(comm -23 <(brew leaves --installed-on-request | sort) <(brew bundle list --global --formula | sort) | tr '\n' ' ')
  casks=$(comm -23 <(brew list --cask | sort) <(brew bundle list --global --cask | sort) | tr '\n' ' ')
  if [ -z "$formulae$casks" ]; then
    echo "Everything installed is in the Brewfile"
    return
  fi
  echo "Installed here but not in the Brewfile:"
  [ -n "$formulae" ] && echo "  formulae: $formulae"
  [ -n "$casks" ] && echo "  casks:    $casks"
  return 0
}
