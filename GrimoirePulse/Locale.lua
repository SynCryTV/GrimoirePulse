local _, GP = ...

GP.L = {}
local de = GetLocale() == "deDE"
local strings = de and {
  TITLE = "GrimoirePulse", LUST = "Kampfrausch", PI = "Machtinfusion",
  ENABLED = "Aktiv", DISABLED = "Deaktiviert", TEST = "Testen", CLOSE = "Schließen",
  SOUND = "Sound", CHANNEL = "Audio-Kanal", MINIMAP = "Minimap-Symbol",
  LANGUAGE = "Sprache", TRACKERS = "Tracker", LUST_SOUND = "Kampfrausch-Sound",
  PI_SOUND = "Machtinfusions-Sound", NONE = "Keiner", CUSTOM_HELP = "Eigene Sounds: Lege .ogg oder .mp3 in Sounds/Custom/ ab, trage sie in UserSounds.lua ein und nutze /reload.",
  RELOAD = "Ein /reload ist nötig, damit neue Sounds erscheinen.",
  OPTIONS = "Einstellungen", MOVED = "Tracker entsperrt – ziehe ihn an die gewünschte Position.",
  UNLOCK = "Tracker positionieren", LOCK = "Positionen sperren", PREVIEW = "VORSCHAU · ZIEH MICH",
  GENERAL = "GRIMOIRE · ALLGEMEIN", ALERTS = "ARKANE WARNUNGEN", SOUNDS = "KLANGZAUBER",
  FOLDER = "Sounds-Pfad kopieren", FOLDER_HELP = "WoW darf den Windows-Explorer nicht direkt öffnen. Klicke in das Feld, drücke Strg+A und Strg+C. Danach kannst du den Pfad im WoW-Ordner verwenden.",
  COPY_PATH = "Kopierbarer Addon-Pfad:",
} or {
  TITLE = "GrimoirePulse", LUST = "Bloodlust", PI = "Power Infusion",
  ENABLED = "Enabled", DISABLED = "Disabled", TEST = "Test", CLOSE = "Close",
  SOUND = "Sound", CHANNEL = "Audio channel", MINIMAP = "Minimap button",
  LANGUAGE = "Language", TRACKERS = "Trackers", LUST_SOUND = "Bloodlust sound",
  PI_SOUND = "Power Infusion sound", NONE = "None", CUSTOM_HELP = "Custom sounds: place .ogg or .mp3 files in Sounds/Custom/, add them to UserSounds.lua, then use /reload.",
  RELOAD = "Use /reload before newly added sounds will appear.",
  OPTIONS = "Options", MOVED = "Tracker unlocked – drag it where you want it.",
  UNLOCK = "Position trackers", LOCK = "Lock positions", PREVIEW = "PREVIEW · DRAG ME",
  GENERAL = "GRIMOIRE · GENERAL", ALERTS = "ARCANE ALERTS", SOUNDS = "SOUNDCRAFT",
  FOLDER = "Copy sound path", FOLDER_HELP = "WoW cannot open Windows Explorer directly. Click the field, press Ctrl+A and Ctrl+C, then use the path inside your WoW folder.",
  COPY_PATH = "Copyable addon path:",
}
for k, v in pairs(strings) do GP.L[k] = v end
