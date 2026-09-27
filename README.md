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

## Version 2.0.0: private all-in-one build

At the repository owner's request, this version combines the provided LustAlert and MLG Power Infusion components into one addon folder, adds German UI text, and keeps their original functionality available through `/lust` and `/pi`.

The original authors retain rights to their respective source code, media, sounds, and artwork. Before redistributing or using this project outside a private setting, make sure you have the necessary permissions and comply with the original licenses.

## Releases

Pushing to `main` or `master` automatically creates a GitHub Release and installable ZIP when `## Version:` in `GrimoirePulse/GrimoirePulse.toc` is increased. The release is tagged as `v<version>`.
