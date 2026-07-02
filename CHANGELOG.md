# CHANGELOG

### 1.5.0

**New in the color picker**
- A personal **color palette**: up to 48 editable preset slots (rows of 12, revealed progressively — a fresh palette starts as a single row and grows as you fill it). Left-click a slot to pick its color, left-click an empty slot (+) to start defining it, right-click a filled slot for a context menu (**Edit preset / Copy hex code / Clear preset**), and **DEL** clears the slot being edited. While editing (gold frame) the slot follows every picked color live, and **Apply stores it without closing the picker**, so several presets can be defined in one go. The palette is shared by all mods, ships completely empty (the API hardcodes no colors) and is saved in `aslainmenu.dat`, so it survives game restarts and modpack reinstalls. The swatch matching the current color is always framed.
- **Live preview**: while the cursor moves over the spectrum, the COLOR box previews the color under it — before any click; rolling out restores the selected color.

**New in the settings window**
- **Search upgrades**: a refreshed search field (magnifier inside, modern style) and a hit counter showing `found X of Y mods` as you type.
- **Right-click menu on color controls**: right-click the color swatch next to any option to reset it to the mod's **default** or **copy its hex code** to the clipboard (bare value, e.g. `FF0000`).
- The **Apply button counts pending changes** — `Apply (3)` means three options currently differ from their saved state; reverting a value drops it back out of the count.
- **Jump highlight**: after clicking a letter on the A–Z bar (or when a search narrows to a single mod), the target mod's frame and title briefly pulse brighter, so the eye lands on it instantly.
- The window **remembers its scroll position** within the current game session; a fresh game start begins at the top.

**New for mod authors**
- `createColorChoice(..., presets=[...])` and `createCheckboxColor(..., presets=[...])`: give the picker your mod's own palette (up to 24 hex codes, shown as one or two pick-only rows). When a mod supplies presets, **only those colors are offered as presets** — the user's editable palette is hidden in that picker. `None` (default) shows the user's palette; an empty list shows no preset rows at all.
- `presetsOnly=True` (together with `presets`): reduce the picker to **just your preset swatches and the Apply button** — the spectrum, RGB sliders and hex input are hidden, so the user can only choose one of your colors (e.g. "pick 1 of these 8"). The popup width auto-fits the number of presets; the full picker's size is untouched.
- Both are plain keyword arguments — on older API builds gate them on the version: `g_modsSettingsApi.getVersionTuple() >= (1, 5)`.

**Fixed**
- Clicking the spectrum on a color whose code starts with zero bytes (e.g. pure blue `0000FF`) produced a shortened hex code (`ff`), which was then stored as the option's value. The spectrum now always yields a full 6-digit code. Present in every earlier version (inherited from the original picker).

### 1.4.1

**Fixed**
- A button attached to a `CheckBox` / `RadioButtonGroup` row (via `componentConfig.button`) can now be lined up by the row's configured `width` using an opt-in `button.fixedPositioning` flag, with an optional `button.align: 'right'`, instead of always sitting right after the label text. This lets a column of buttons align even when the labels have different lengths. The flag is opt-in, so existing mods are unchanged. Contributed by CH4MPi.

### 1.4.0

**New for mod authors**
- `templates.createCheckboxColor(text, varName, value, color, tooltip=None, tooltipIcon=None, button=None, useHTML=True)`: a checkbox paired with a color picker on one row, the tick box and its label on the left and the color swatch on the right. The stored value is a dict `{'enabled': <bool>, 'color': <hex str>}`, so read `settings[varName]['enabled']` and `settings[varName]['color']` in your callback. A long label wraps onto extra lines under the checkbox without ever running under the swatch. It works with `enableWhen` / `visibleWhen` (both as a gated control and as a master, where it gates on its `enabled` flag) and inside `createControlsGroup`, supports `tooltip` and `useHTML` like the other controls, and the per-mod reset button responds to its changes. Feature-detect with `hasattr(templates, 'createCheckboxColor')`.

### 1.3.3

**Improved**
- A template change that doesn't alter the structure now keeps the user's saved values for **every** mod — including mods with no `settingsVersion` (which previously reset on any edit) and a mod adopting `settingsVersion` for the first time. The new template is still applied so labels and tooltips refresh; only a `settingsVersion` bump, a first install, or a structural change resets values. Reordering controls counts as cosmetic (values are keyed by control name), so it no longer needs a bump.
- "Structural" now also covers changes that can invalidate a saved value: a dropdown / radio / step-slider's set of options, and a slider / numeric-stepper's min / max / interval. Changing those without a `settingsVersion` bump is no longer mistaken for cosmetic, so a stale or out-of-range saved value is never silently kept.

**Fixed**
- The per-mod "reset to defaults" button now targets the current template's defaults. Previously, after a control was added on an unversioned update or a shipped default value was changed, the reset button could restore an outdated default.

### 1.3.2

**Improved**
- `setModTemplate` now tells cosmetic template changes apart from structural ones. A cosmetic-only change — an edited label or tooltip, or a label that embeds the live API version — refreshes in place with the user's saved values preserved, with no `settingsVersion` bump and no warning. Only structural changes (controls added/removed or retyped, changed dropdown options) still need a bump.

**Fixed**
- Opening the settings window could crash (`AttributeError` on `_modTranslations`) when a mod-label translation had been registered via `registerModTranslation` but the active API instance had no translation table. The translation lookups are now defensive, so the window opens regardless of how the instance was resolved.

### 1.3.1

**New for mod authors**
- `g_modsSettingsApi.registerModTranslation(linkage, mapping)` — register a display-only label translation for another mod's settings page. `mapping` is a dict of `{original string: replacement string}`; the API applies it to the **copy** of the template shown in the settings window, so the target mod's stored template and saved values are never touched (no settings reset) and the mod's own code is not modified. Keys may be `str` (UTF-8) or `unicode`, and repeated calls for the same `linkage` merge. The API ships no translations of its own — it is the hook an optional, separate localization mod uses to translate a mod whose menu is only offered in one language. Feature-detect with `hasattr(g_modsSettingsApi, 'registerModTranslation')`.

**Improved**
- The mod list now sorts by the **shown** name. When a translation is registered for a mod (see `registerModTranslation`), the list orders it under its translated name instead of its original one. Mod names not written in the Latin alphabet (e.g. Cyrillic) now sort after the Latin-named mods, keeping their own order, instead of falling back to the mod's internal id.

**Fixed**
- Mod frames could overlap when the settings window was reopened with a saved mix of collapsed and expanded mods: the list positioned each mod by its momentary rendered height — unreliable while the window is still off-screen — instead of its laid-out height. It now uses the laid-out height, so mods stack correctly the first time the window opens. (Long-standing, present since per-mod collapse was added.)

### 1.3.0

**New in the settings window**
- Every mod in the settings window now has its own **reset button** — a rotate icon in the mod's header (below the on/off switch, or in its slot for mods without one; shown while the mod is expanded) that restores that mod's options **and hotkeys** to their defaults. It is dimmed when nothing differs from the defaults (or while the mod is switched off) and lights up once something changes. Clicking it opens a small **confirmation dialog** (showing the mod's name, with **Reset** / **Cancel**) drawn inside the menu so it always stays on top; on confirm the control reset is applied live like any manual change — **Apply / OK** keeps it, **Cancel** reverts it; hotkeys reset immediately (their own channel). It never changes the mod's on/off state. Both the tooltip and the dialog are localized in all 25 languages, and the confirmation can be skipped via the `resetSkipConfirm` user setting.
- A search box in the settings window header filters the mod list by name as you type — magnifier icon, an "×" clear button and a "Search mods" placeholder, styled to match the menu. Press **Ctrl+F** to jump to it and start typing; matching mods are revealed (auto-expanded) and the list scrolls to the top, and clearing it (the ×, or emptying the field) restores the previous view. Clicking an A-Z quick-jump letter while a search is active clears the search first, then jumps to that letter.

**New for mod authors**
- `templates.visibleWhen(control, masterVarName, value, condition='==')` — sibling of `enableWhen` that **hides** the control (and reflows the mod so the rows below close the gap) when the condition fails, instead of greying it out in place. For options that make no sense in a given mode.
- `templates.enableWhenAll` / `enableWhenAny` / `visibleWhenAll` / `visibleWhenAny(control, conditions)` — gate a control on more than one master at once. `conditions` is a list of `{'varName', 'value', 'condition'}` dicts; the `*All` variants require every condition (logical AND), the `*Any` variants require at least one (OR); the `enable*` pair greys the control while the `visible*` pair hides it. Backward-compatible — older API builds leave the control always-on.
- `templates.createControlsGroup(master, children, indent=False)` — group sub-options under a master **without indenting** the children, so a wide group doesn't crowd the second column (the master still greys / enables the whole group). Maps to the per-child `masterIndent` key, which you can also set by hand.
- `templates.escape(text)` — escape `&`, `<` and `>` in literal label text so it renders verbatim (menu labels are HTML, so a bare `<` would otherwise be parsed as markup and swallow the rest, e.g. `master <= 5` losing the `<= 5`). Returns a plain string; feature-detect with `hasattr(templates, 'escape')`.
- `useHTML=False` on any `create*` control — render that control's whole label as plain text instead of HTML, so a literal `<` / `>` / `&` shows verbatim (the API escapes it; the whole-label counterpart to `templates.escape`). Default `useHTML=True` keeps HTML labels (icons, `<font>`, `<b>`). It is a keyword argument, so gate it on the API version (`getVersionTuple() >= (1, 3)`) on older builds.

**Improved**
- `setModTemplate` now logs a warning to `python.log` when a mod's template changed but its `settingsVersion` was not bumped (so the stored template is kept and the change isn't applied), making the easy-to-forget bump obvious during development. No behaviour change.
- Documented the `g_modsSettingsApi.onWindowOpened` / `onWindowClosed` lifecycle hooks (for lightweight non-UI reactions) and clarified that conditional structure which must persist across reopens should be gated with `visibleWhen` / `createControlsGroup`, not rebuilt on open — see `docs/LIVE_MENU_UPDATES.md`.

**Fixed**
- A control gated with `enableWhen` (or `createControlsGroup`) stayed active when its master control was itself greyed out or hidden but still held a matching value. Gated controls now follow the whole master chain — a child greys out whenever its master is disabled, not only when the value fails the condition.

### 1.2.1
- `g_modsSettingsApi.updateImageAtlas(linkage, varName, atlasSource, frameWidth, frameHeight, columns, count, fps, loop=True, width=None, height=None)` — play a sprite sheet as a looping animation in an `Image` component, live, while the settings window is open. `atlasSource` is one image laid out as a `columns`-wide, row-major grid of `count` cells, each `frameWidth`×`frameHeight`; the sheet is loaded **once** and animated by blitting cells with `copyPixels`, so it stays light even at a high `fps` (one image instead of hundreds of frame files). `loop=False` plays once and holds the last frame. `width`/`height` fit it like `updateImage` (never upscaled). Feature-detect with `hasattr(g_modsSettingsApi, 'updateImageAtlas')`.
- `templates.createImage(..., atlas={...})` — start an `Image` **already animating** a sprite sheet at build time, so it plays the instant the menu opens (no race with a follow-up `updateImageAtlas`, which fires before the component exists). `atlas` is a dict `{source, frameWidth, frameHeight, columns, count, fps, loop}`. Use `createImage(atlas=...)` for the initially-shown animation and `updateImageAtlas(...)` to switch it live — together they mirror how a static `createImage(source=...)` pairs with `updateImage(...)`. Optional and backward-compatible: existing `createImage` calls are unchanged.

### 1.2.0
- `templates.enableWhen(control, masterVarName, value, condition='==')` — grey out a control unless another control's value satisfies a comparison, not just equality. `condition` is a standard operator: `'=='` (default — equals, or membership when `value` is a list), `'!='`, `'>'`, `'>='`, `'<'`, `'<='`; for example, enable a field only while a master slider or stepper is `>= 0`. It greys / ungreys live as the master changes. The `CONDITION` constants are aliases for these operators, so you can write `condition=CONDITION.GREATER_EQUAL` instead of `'>='` (EQUAL, NOT_EQUAL, GREATER, GREATER_EQUAL, LESS, LESS_EQUAL).
- `templates.createHotkey(..., float='right')` — for a long hotkey label, wrap the text around the keys instead of cramming it into the narrow column to their left. Like CSS `float`, the keys sit on the right and the label's overflow lines flow the full row width underneath them, so a long description reads naturally. Default `'none'` keeps the original layout; plain-text labels only.
- `reloadModTemplate` (e.g. an instant in-menu language switch) now re-renders only the controls whose type, label or value actually changed and reuses the rest in place, instead of rebuilding the whole mod — so the re-render no longer flickers.
- `registerLiveSettingsChange(linkage, callback, fullsettings=True)` — choose the live-callback payload with a plain flag: keep `True` (default) to receive the full settings dict on every uncommitted change, or pass `fullsettings=False` to receive only the keys that changed since the last live event. The previous `mode='changedOnly'` argument and the `LIVE_SETTINGS_MODE` class still work but are now deprecated and will be removed in a future version.
- `g_modsSettingsApi.getVersion()` / `getVersionTuple()` (and the importable `VERSION` / `VERSION_TUPLE` constants) — read the running API version so a mod can adapt to it, e.g. `if g_modsSettingsApi.getVersionTuple() >= (1, 2): ...`. Use the tuple form for comparisons; the string form (`'1.2.0'`) is for display. Guard the call with `hasattr(g_modsSettingsApi, 'getVersionTuple')` since older API builds don't provide it.
- Fixed: the mods-list scrollbar thumb could drift after an in-place re-render (toggling a mod on/off, or an in-menu language switch) — the scroll range is now pinned to the laid-out list height instead of the momentary rendering bounds, so the thumb stays exactly where it was.
- Fixed a bug in a scrollable dropdown, the highlight on the selected row was drawn over the scrollbar
- Fixed a bug: a long key name or modifier combination on a hotkey was clipped by the fixed-width key box; the box now grows to fit its contents and right-aligns to the column edge like the other controls.

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
- Renamed to `aslain.modssettingsapi` (based on `izeberg.modssettingsapi` 1.7.x), now under its own package `gui.aslainMenu` with its own `aslainmenu.dat`. Runs independently of izeberg and never modifies izeberg's `modsettings.dat`. Mods import `gui.aslainMenu` (with a fallback to `gui.modsSettingsApi`) to use this menu
- Added new component: `Image` — render an image in the menu body, positioned inside a box via `align` (left/center/right), `valign` (top/center/bottom), `containerWidth` and `containerHeight`. A fixed `containerHeight` keeps a constant layout slot so live updates don't shift the components below
- Added `g_modsSettingsApi.updateImage(linkage, varName, source, width, height)` — update a displayed `Image` in place, without re-rendering the menu (scroll/focus preserved)
- Added `g_modsSettingsApi.registerLiveSettingsChange` / `unregisterLiveSettingsChange(linkage, callback)` (and `notifyLiveSettingsChange`) — per-linkage callback fired on every uncommitted in-menu value change (before Apply), for live previews. Callbacks are kept in a protected (single-underscore) attribute so mods that subclass the API to override behaviour can still interoperate
- Added `g_modsSettingsApi.reloadModTemplate(linkage, template)` — re-render one mod's component subtree in place from a fresh template (e.g. instant language switch); other mods untouched, hotkey controls are re-applied after the reload
- Added per-mod collapse/expand: every mod in the settings list can be collapsed via the arrow in its header to reduce scrolling; the collapsed state is remembered between sessions
- Added a toolbar above the mods list: a Collapse All / Expand All toggle button and a horizontal A-Z quick-jump bar (click a letter to scroll to the first mod with that initial; letters with no mod are dimmed, and the hovered letter scales up)
- The mods list is now sorted by display name (case-insensitive), ignoring a leading image badge / symbols before the name so the A-Z jump stays consistent
- Added `templates.createControlsGroup(master, children)` — bind sub-option controls to a master control; while the master's (boolean) value is off, the children are shown indented, greyed-out and disabled (children may be checkboxes or a radio button group). The binding is a `masterVarName` key on each child, so it can also be set by hand
