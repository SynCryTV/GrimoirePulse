# GrimoirePulse

An original World of Warcraft addon for personal **Bloodlust/Heroism** and **Power Infusion** tracking. It shows two compact countdown bars, optionally plays separate sounds, has a minimap button, and uses German automatically on German clients (English otherwise).

## Install

Copy `GrimoirePulse` into `_retail_/Interface/AddOns/`, then enable it from the character-selection AddOns panel.

Open settings with `/gp` or the minimap button. Use `/gp test` to test configured sounds.

The package includes one initial alert sound, with the user's permission, to make the tracker immediately usable.

## Custom sounds

1. Put an `.ogg` or `.mp3` into `GrimoirePulse/Sounds/Custom/`.
2. Add its filename to `GrimoirePulse/UserSounds.lua` using the included example.
3. Run `/reload`, then choose it in `/gp`.

This explicit list is required because WoW addons cannot inspect or browse local files at runtime.

## Development

No code, libraries, sound files, textures, or UI layouts were copied from the reference addons. The generated `Media/grimoire-pulse.png` is a new project asset. Contributions are welcome under the MIT license.
