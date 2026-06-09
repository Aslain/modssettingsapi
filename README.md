# Aslain's ModsSettings API

An enhanced fork of [izeberg's modsSettingsApi](https://github.com/izeberg/modssettingsapi), the in-garage settings menu for World of Tanks mods. It keeps the same template format and API, and adds features for navigating long mod lists and a richer settings UI.

It ships under its own package `gui.aslainMenu` with its own `aslainmenu.dat`, so it runs independently of izeberg and never touches izeberg's `modsettings.dat`. Mods import `gui.aslainMenu` (with a fallback to izeberg) to use this menu and its new features.

## Enhancements over the original

- **Collapse / expand** each mod, plus a **Collapse All / Expand All** toolbar button, to keep a long settings list tidy.
- **A-Z quick-jump bar** above the list: click a letter to jump to the first mod with that initial.
- Mods list **sorted by display name** (case-insensitive), ignoring a leading badge or symbol before the name.
- **Grouped sub-options** via `templates.createControlsGroup(master, children)`: tie sub-controls to a master control so they are indented and **greyed-out / disabled while the master is off**, then enabled when it is on.
- **`Image` component** to render an image in the menu body, with `updateImage(...)` to refresh it in place (live previews).
- **Live in-menu updates**: `registerLiveSettingsChange(...)` (per-linkage) and a global `onLiveSettingsChange` event for uncommitted value changes; `reloadModTemplate(...)` re-renders one mod in place (e.g. instant language switch) without closing the window.

See [`CHANGELOG.md`](./CHANGELOG.md) for the full list, and [`docs/LIVE_MENU_UPDATES.md`](./docs/LIVE_MENU_UPDATES.md) for the live-update and image API.

## Screenshots

![Settings menu with the A-Z jump bar and collapsed mods](./assets/aslainMenu_1.png)

![A mod expanded to show only its options](./assets/aslainMenu_2.png)

![Per-mod settings with image preview and language switch](./assets/aslainMenu_3.png)

![Sub-options grouped under a master toggle - they grey out while it is off](./assets/aslainMenu_4.png)

## Using it in your mod

Import the fork first, with a fallback to izeberg, so your mod also runs where only the original is installed. Importing `gui.aslainMenu` first means it wins when both are present:

```python
g_modsSettingsApi = None
templates = None
try:
    from gui.aslainMenu import g_modsSettingsApi, templates
except ImportError:
    pass
if g_modsSettingsApi is None:
    try:
        from gui.modsSettingsApi import g_modsSettingsApi, templates
    except ImportError:
        pass
```

The extra features (image previews, instant language switch, controls grouping) work when `gui.aslainMenu` is the one loaded. Feature-detect new methods with `hasattr(g_modsSettingsApi, ...)` so your mod still runs on older API builds. See [`examples/`](./examples) for full templates.

### Grouping sub-options

Tie sub-controls to a master control so they grey out while the master is off:

```python
templates.createControlsGroup(
    templates.createCheckbox('Enable feature', 'featureOn', True),
    [
        templates.createSlider('Intensity', 'intensity', 5, 1, 10, 1),
        templates.createCheckbox('Verbose logging', 'verbose', False),
    ],
)
```

### Staying compatible with plain izeberg

The import above lets your mod *run* on either menu, but the features below exist **only** on `gui.aslainMenu`. Calling them on plain izeberg raises an error (and can blank the whole settings window), so feature-detect each one with `hasattr(...)` and skip it when missing. A skipped control is simply left out of the template - no error, and no empty slot: the layout just closes up.

```python
column = [
    templates.createCheckbox('Sixth Sense enabled', 'enabled', True),
    templates.createDropdown('Icon', 'icon', ICON_NAMES, 0),
]

# createImage is aslainMenu-only -> add the preview only when available,
# otherwise it is simply omitted (no error, no empty gap).
if hasattr(templates, 'createImage'):
    column.append(templates.createImage('myicons/%s.png' % ICON_NAMES[0],
                                        containerHeight=96, align='center'))

# createControlsGroup (grey-out sub-options under a master) is aslainMenu-only too.
master = templates.createCheckbox('Enable extras', 'extrasOn', True)
children = [templates.createSlider('Glow size', 'glow', 24, 8, 64, 1)]
if hasattr(templates, 'createControlsGroup'):
    column += templates.createControlsGroup(master, children)  # grouped + greyed when off
else:
    column += [master] + children                              # flat fallback on izeberg
```

Guard the singleton's new methods the same way, e.g. the live image preview:

```python
if hasattr(g_modsSettingsApi, 'updateImage'):
    g_modsSettingsApi.registerLiveSettingsChange(MOD_LINKAGE, onLiveChange)
    # inside onLiveChange call g_modsSettingsApi.updateImage(MOD_LINKAGE, 'icon', newSource)
```

**aslainMenu-only - guard before use:**

- `templates`: `createImage`, `createControlsGroup`
- `g_modsSettingsApi`: `updateImage`, `registerLiveSettingsChange` / `unregisterLiveSettingsChange`, `notifyLiveSettingsChange`, `reloadModTemplate`, `setModCollapsed`, and the `onLiveSettingsChange` event

Everything else (checkboxes, sliders, dropdowns, radio button groups, step sliders, hotkeys, color choice, range slider, labels, `setModTemplate`, `getModSettings`, ...) exists on both menus, so it needs no guard.

## Dependencies

- [ModsList API](https://gitlab.com/wot-public-mods/mods-list) by poliroid, opens the settings window.
- `net.openwg.gameface`, renders the menu UI.

## Build

See [`build.py`](./build.py) and [`build.json`](./build.json); build requirements are in [`requirements_build.txt`](./requirements_build.txt).

## Credits

- Original **ModsSettings API** by **izeberg (Renat Iliev)**, [izeberg/modssettingsapi](https://github.com/izeberg/modssettingsapi). All original credit and copyright remain with the author.
- **ModsList API** dependency by **poliroid**, [wot-public-mods/mods-list](https://gitlab.com/wot-public-mods/mods-list).
- This enhanced fork is maintained by **Aslain** ([aslain.com](https://aslain.com)). It adds the features listed above on top of izeberg's API, and does not remove or replace the original work.

See [`AUTHORS.md`](./AUTHORS.md).

## Contributing

Issues and pull requests welcome, especially new settings UI components and compatibility fixes.
