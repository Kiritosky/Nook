# -*- coding: utf-8 -*-
#
# dmgbuild-Konfiguration für die Nook-DMG.
# Aufruf über scripts/build-dmg.sh:
#   python3 -m dmgbuild -s scripts/dmg_settings.py \
#       -D app=<Nook.app> -D bg=<background.tiff> -D icon=<icon.png> "Nook" out.dmg
#
import os.path

application = defines.get("app", "Nook.app")
appname = os.path.basename(application)
background_img = defines.get("bg", "scripts/dmg-assets/background.tiff")
badge = defines.get("icon", "")

# Komprimiertes Image
format = "UDZO"

# Inhalt: App + Verknüpfung auf den Programme-Ordner
files = [application]
symlinks = {"Applications": "/Applications"}

# Volume-Icon: App-Icon auf ein Laufwerks-Badge legen
if badge:
    badge_icon = badge

# Fenster & Icon-Ansicht (Koordinaten von oben-links, decken sich mit dem
# Hintergrundbild 540×380 und dem darin gezeichneten Pfeil)
background = background_img
window_rect = ((240, 180), (540, 380))
default_view = "icon-view"
show_icon_preview = False

icon_size = 128
text_size = 13
icon_locations = {
    appname: (135, 168),
    "Applications": (405, 168),
}

# Finder-Chrome ausblenden für einen ruhigen Installer-Look
show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
