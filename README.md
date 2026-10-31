# dotfiles
All my configurations for macOS

## yabai / skhd / sketchybar

Dependencies:

```sh
brew install asmvik/formulae/yabai asmvik/formulae/skhd
brew install FelixKratz/formulae/sketchybar lua jq switchaudio-osx
brew install --cask sf-symbols font-sf-pro font-sketchybar-app-font

# SbarLua (Lua module for sketchybar, installed in ~/.local/share/sketchybar_lua)
(git clone https://github.com/FelixKratz/SbarLua.git /tmp/SbarLua && cd /tmp/SbarLua && make install && rm -rf /tmp/SbarLua)
```

The sketchybar `menus` helper is compiled on startup and needs the Xcode Command Line Tools.

yabai's scripting addition requires SIP to be partially disabled and a sudoers rule pinned to the binary's
sha256. Regenerate it after every `brew upgrade yabai`:

```sh
echo "$(whoami) ALL=(root) NOPASSWD: sha256:$(shasum -a 256 $(which yabai) | cut -d " " -f 1) $(which yabai) --load-sa" | sudo tee /private/etc/sudoers.d/yabai
```

Reload everything with `ctrl + shift + alt - r`.
