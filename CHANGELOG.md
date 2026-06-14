# CHANGELOG

### 1.2.0
- `templates.enableWhen(control, masterVarName, value, condition='==')` — grey out a control unless another control's value satisfies a comparison, not just equality. `condition` is a standard operator: `'=='` (default — equals, or membership when `value` is a list), `'!='`, `'>'`, `'>='`, `'<'`, `'<='`; for example, enable a field only while a master slider or stepper is `>= 0`. It greys / ungreys live as the master changes. The `CONDITION` constants are aliases for these operators, so you can write `condition=CONDITION.GREATER_EQUAL` instead of `'>='` (EQUAL, NOT_EQUAL, GREATER, GREATER_EQUAL, LESS, LESS_EQUAL).
- `templates.createHotkey(..., float='right')` — for a long hotkey label, wrap the text around the keys instead of cramming it into the narrow column to their left. Like CSS `float`, the keys sit on the right and the label's overflow lines flow the full row width underneath them, so a long description reads naturally. Default `'none'` keeps the original layout; plain-text labels only.
- `reloadModTemplate` (e.g. an instant in-menu language switch) now re-renders only the controls whose type, label or value actually changed and reuses the rest in place, instead of rebuilding the whole mod — so the re-render no longer flickers.
- `registerLiveSettingsChange(linkage, callback, fullsettings=True)` — choose the live-callback payload with a plain flag: keep `True` (default) to receive the full settings dict on every uncommitted change, or pass `fullsettings=False` to receive only the keys that changed since the last live event. The previous `mode='changedOnly'` argument and the `LIVE_SETTINGS_MODE` class still work but are now deprecated and will be removed in a future version.
- `g_modsSettingsApi.getVersion()` / `getVersionTuple()` (and the importable `VERSION` / `VERSION_TUPLE` constants) — read the running API version so a mod can adapt to it, e.g. `if g_modsSettingsApi.getVersionTuple() >= (1, 2): ...`. Use the tuple form for comparisons; the string form (`'1.2.0'`) is for display. Guard the call with `hasattr(g_modsSettingsApi, 'getVersionTuple')` since older API builds don't provide it.
- Fixed: the mods-list scrollbar thumb could drift after an in-place re-render (toggling a mod on/off, or an in-menu language switch) — the scroll range is now pinned to the laid-out list height instead of the momentary rendering bounds, so the thumb stays exactly where it was.
- Fixed a bug in a scrollable dropdown, the highlight on the selected row was drawn over the scrollbar (from forked API)
- Fixed a bug: a long key name or modifier combination on a hotkey was clipped by the fixed-width key box; the box now grows to fit its contents and right-aligns to the column edge like the other controls. (from forked API)

### 1.1.2
- Fixed: the mods-list scrollbar could permanently stop responding to thumb dragging and arrow clicks (only the mouse wheel kept working) when the list height changed - e.g. a mod was collapsed - while a smooth wheel-scroll animation was still running
- Fixed: after Collapse All followed by Expand All on a long, deeply-scrolled list, a single wheel tick could jump the list back to its old (pre-collapse) scroll position

### 1.1.1
- The hangar entry and the settings window are now titled **"Mods settings+"** (localized in all 25 languages) and the menu icon carries a small "+" badge, so the enhanced menu is easy to tell apart from the original
- `templates.createImage(..., collapsed=True)` — start the image's slot collapsed (zero height) instead of reserving the full container; expand it later with `updateImage(..., source)`. Default `False` keeps the reserved slot (useful when the mod's default state shows no image)
- `templates.createImage(..., label='Preview', labelAlign='center')` — optional text label above the image, part of the component: it collapses/expands together with the image and supports the same html markup as other menu labels. `labelAlign` ('left'/'center'/'right') positions it within the container box, independent of the image's own `align`
- `updateImage(..., label=...)` — live-update the image's label text (e.g. "Preview (unsaved)"); `None` keeps the current text, `''` clears it
- `updateImage` width/height are now optional like in `createImage` — when omitted the image renders at its natural size, shrunk to fit the container if oversized (never upscaled)

### 1.1.0
- `templates.enableWhen(control, masterVarName, value)` — grey out a control unless another control holds a given value (not just a boolean On/Off); `value` may be a list
- `registerLiveSettingsChange(linkage, callback, mode='changedOnly')` — the callback receives only the keys whose value changed since the previous live event
- `updateImage(linkage, varName, source, width, height, removeImage=False)` — pass `removeImage=True` to collapse an Image's slot so the controls below it (and the mods below) move up
- `Image` now loads via `flash.display.Loader`; sources are plain root-relative paths (`gui/maps/...`, `mods/configs/...`) resolved from the WoT root

### 1.0.0
- Renamed to `aslain.modssettingsapi` (fork of `izeberg.modssettingsapi` 1.7.x), now under its own package `gui.aslainMenu` with its own `aslainmenu.dat`. Runs independently of izeberg and never modifies izeberg's `modsettings.dat`. Mods import `gui.aslainMenu` (with a fallback to `gui.modsSettingsApi`) to use this menu
- Added new component: `Image` — render an image in the menu body, positioned inside a box via `align` (left/center/right), `valign` (top/center/bottom), `containerWidth` and `containerHeight`. A fixed `containerHeight` keeps a constant layout slot so live updates don't shift the components below
- Added `g_modsSettingsApi.updateImage(linkage, varName, source, width, height)` — update a displayed `Image` in place, without re-rendering the menu (scroll/focus preserved)
- Added `g_modsSettingsApi.registerLiveSettingsChange` / `unregisterLiveSettingsChange(linkage, callback)` (and `notifyLiveSettingsChange`) — per-linkage callback fired on every uncommitted in-menu value change (before Apply), for live previews. Callbacks are kept in a protected (single-underscore) attribute so mods that subclass the API to override behaviour can still interoperate
- Added `g_modsSettingsApi.reloadModTemplate(linkage, template)` — re-render one mod's component subtree in place from a fresh template (e.g. instant language switch); other mods untouched, hotkey controls are re-applied after the reload
- Added per-mod collapse/expand: every mod in the settings list can be collapsed via the arrow in its header to reduce scrolling; the collapsed state is remembered between sessions
- Added a toolbar above the mods list: a Collapse All / Expand All toggle button and a horizontal A-Z quick-jump bar (click a letter to scroll to the first mod with that initial; letters with no mod are dimmed, and the hovered letter scales up)
- The mods list is now sorted by display name (case-insensitive), ignoring a leading image badge / symbols before the name so the A-Z jump stays consistent
- Added `templates.createControlsGroup(master, children)` — bind sub-option controls to a master control; while the master's (boolean) value is off, the children are shown indented, greyed-out and disabled (children may be checkboxes or a radio button group). The binding is a `masterVarName` key on each child, so it can also be set by hand
