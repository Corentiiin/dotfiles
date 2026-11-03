# dotfiles
Toutes mes configurations pour macOS.

## yabai / skhd / sketchybar

Un environnement de bureau en mosaïque pour macOS 26 (Tahoe), sur Apple Silicon :

- **yabai** place automatiquement les fenêtres en mosaïque (BSP).
- **skhd** fournit les raccourcis clavier.
- **sketchybar** remplace la barre de menus par une barre au style Apple.

### Fonctionnalités

#### Fenêtres (yabai)

- **Mosaïque automatique** : chaque nouvelle fenêtre partage l'espace avec la fenêtre active (à droite ou en dessous).
- **Pas de marges** autour de l'écran et 2 px entre les fenêtres.
- **Les ratios restent** quand on ouvre ou ferme une fenêtre. On rééquilibre à la demande avec `⇧ ⌥ B`.
- **Le focus suit la souris** sans mettre la fenêtre au premier plan.
- **Les fenêtres inactives sont légèrement transparentes** (95 %).
- **Aucune animation** : les fenêtres bougent instantanément.
- **Fenêtres empilées** : plusieurs fenêtres peuvent partager la même place, on passe de l'une à l'autre avec `⌥ J` / `⌥ K`.
- **Apps flottantes** (hors mosaïque) : Réglages Système, Calculette, Moniteur d'activité, Finder, QuickTime Player, FaceTime.
- **Discord** s'ouvre toujours sur l'espace 6.
- **Espaces** : les espaces 1 à 8 sont permanents. On peut en créer deux de plus (9 et 10, gérés par la barre et les raccourcis), et seuls ceux-là peuvent être supprimés.

#### Barre (sketchybar)

La barre est transparente, comme la barre de menus de macOS 26. Ses éléments flottent sur le fond d'écran.

De gauche à droite :

| Élément | Affichage | Clic |
|---|---|---|
| Pomme | Logo Apple | Ouvre le vrai menu Apple |
| Espaces | Un segment par espace : son numéro et les icônes des apps ouvertes dessus (5 au plus, puis `+n`). L'espace actif est surligné. | Va sur l'espace. Clic sur une icône : va directement sur cette fenêtre. Clic droit sur l'espace 9 ou 10 : le supprime. |
| App active | Nom de l'app au premier plan, en gras | Ouvre le menu de l'app |
| Batterie | Pourcentage et jauge (verte en charge, rouge sous 20 %) | Ouvre les réglages Batterie |
| Wi-Fi | État de la connexion | Menu Wi-Fi : interrupteur, réseau ou partage de connexion, adresse IP, routeur, sécurité |
| Son | Volume, ou icône des AirPods / HomePod connectés | Menu Son : curseur de volume et choix de la sortie audio. Molette : volume (`⌃` + molette pour un réglage fin). Clic droit : réglages Son. |
| Horloge | Date et heure (`Sat Oct 31  15:20`) | Ouvre Calendrier |

- **Mises à jour en temps réel** : l'horloge change à la seconde 00 de chaque minute, la batterie dès que macOS signale un changement. Rien n'est interrogé en boucle, la barre ne consomme presque rien au repos.
- **Icônes des apps** : elles apparaissent et disparaissent dès qu'une fenêtre s'ouvre, se ferme, est réduite ou change d'espace.
- **Menus Son et Wi-Fi** : au style des menus macOS, ils suivent le thème clair ou sombre du système et se ferment quand la souris quitte la barre.

### Raccourcis clavier

`⌥` = Option, `⇧` = Maj, `⌃` = Contrôle. Les directions suivent Vim : `H` gauche, `J` bas, `K` haut, `L` droite.

#### Fenêtres

| Raccourci | Action |
|---|---|
| `⌥ H` / `⌥ L` | Fenêtre à gauche / à droite (passe à l'écran voisin au bord) |
| `⌥ J` / `⌥ K` | Fenêtre suivante / précédente dans la pile, sinon fenêtre en bas / en haut |
| `⇧ ⌥ H J K L` | Échange la fenêtre avec sa voisine |
| `⌃ ⌥ H J K L` | Redimensionne la fenêtre (40 px) |
| `⌃ ⇧ ⌥ H J K L` | Empile la fenêtre sur sa voisine |
| `⌃ ⇧ ⌥ U` | Sort la fenêtre de la pile |
| `⇧ ⌥ F` | Plein écran (en gardant la barre) |
| `⇧ ⌥ Espace` | Fait flotter la fenêtre au centre de l'écran, ou la remet dans la mosaïque |
| `⌥ Q` | Ferme la fenêtre |

Avec la souris, en maintenant `⌥` :

- **Clic gauche et glisser** : déplace la fenêtre. La lâcher sur une autre fenêtre les échange.
- **Clic droit et glisser** : redimensionne la fenêtre.

#### Disposition

| Raccourci | Action |
|---|---|
| `⇧ ⌥ B` | Rééquilibre les fenêtres de l'espace |
| `⇧ ⌥ Y` / `⇧ ⌥ X` | Retourne la disposition horizontalement / verticalement |

#### Espaces

| Raccourci | Action |
|---|---|
| `⌥ 1` … `⌥ 9`, `⌥ 0` | Va sur l'espace 1 à 10. Rappuyer sur le même chiffre revient à l'espace précédent. |
| `⇧ ⌥ 1` … `⇧ ⌥ 0` | Envoie la fenêtre sur l'espace 1 à 10 |
| `⇧ ⌥ →` / `⇧ ⌥ ←` | Envoie la fenêtre sur l'espace suivant / précédent |
| `⇧ ⌥ N` | Crée un espace |
| `⇧ ⌥ D` | Supprime l'espace actif (9 ou 10 uniquement) |

#### Apps et système

| Raccourci | Action |
|---|---|
| `⌥ B` | Nouvelle fenêtre Firefox |
| `⌥ T` | Nouvelle fenêtre Terminal |
| `⌃ ⇧ ⌥ R` | Recharge yabai, sketchybar et skhd |

### Installation

Dépendances :

```sh
brew install asmvik/formulae/yabai asmvik/formulae/skhd
brew install FelixKratz/formulae/sketchybar lua jq switchaudio-osx
brew install --cask sf-symbols font-sf-pro font-sketchybar-app-font

# SbarLua (Lua module for sketchybar, installed in ~/.local/share/sketchybar_lua)
(git clone https://github.com/FelixKratz/SbarLua.git /tmp/SbarLua && cd /tmp/SbarLua && make install && rm -rf /tmp/SbarLua)
```

Les deux petits programmes de sketchybar (`menus` pour les menus Apple et des apps, `bar_events` pour l'horloge et la batterie) sont compilés au démarrage. Il faut donc les Xcode Command Line Tools.

sketchybar est recompilé avec un correctif (`sketchybar/patches/`) : sans lui, il détruit et recrée toute la barre à chaque sortie de veille et à chaque déverrouillage. Le script recompile la version installée par Homebrew et la remplace. Il est à relancer après chaque `brew upgrade sketchybar` (annulation : `brew reinstall sketchybar`) :

```sh
~/.config/sketchybar/patches/install.sh
```

Le scripting addition de yabai demande de désactiver SIP en partie, et une règle sudoers liée au sha256 du binaire. Elle est à régénérer après chaque `brew upgrade yabai` :

```sh
echo "$(whoami) ALL=(root) NOPASSWD: sha256:$(shasum -a 256 $(which yabai) | cut -d " " -f 1) $(which yabai) --load-sa" | sudo tee /private/etc/sudoers.d/yabai
```

Après une mise à jour, yabai doit aussi être autorisé de nouveau dans Réglages Système → Confidentialité et sécurité → Accessibilité.

### Compatibilité

Testé sur macOS 26.5 avec yabai 7.1.25 et sketchybar 2.24.1. Aucune version officielle de yabai ne gère macOS 27 pour l'instant : le changement d'espace et le scripting addition n'y fonctionnent pas.
