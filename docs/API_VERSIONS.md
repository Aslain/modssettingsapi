# API availability by version

Every public function and argument of Aslain's ModsSettings API (aslainMenu), with the
version that introduced it - so a mod can gate a feature with **one version comparison**
instead of a chain of `try` / `except` probes.

## The one gate you need

```python
try:
    from gui.aslainMenu import g_modsSettingsApi, templates        # Aslain's API
except ImportError:
    from gui.modsSettingsApi import g_modsSettingsApi, templates   # plain izeberg fallback

API_VER = (g_modsSettingsApi.getVersionTuple()
           if hasattr(g_modsSettingsApi, 'getVersionTuple') else (0, 0, 0))
# (0, 0, 0) = plain izeberg, or an aslainMenu build older than 1.2.0 -
# treat every aslainMenu-only feature below as absent.
```

Then gate each feature once, against the table below:

```python
if API_VER >= (1, 6, 1):
    radio = templates.createRadioButtonGroup('Mode', 'mode', OPTS, 0, inline=True)
else:
    radio = templates.createRadioButtonGroup('Mode', 'mode', OPTS, 0)
```

`try` / `except TypeError` around a single call remains a valid alternative for one added
argument - but the version gate scales: one `API_VER` constant, plain `if`s, no probing.

## Compatibility promise

- New capabilities arrive as **new functions** or **trailing optional keyword arguments**.
  Existing parameters are never renamed, reordered or removed, and deprecated names stay
  as working aliases (e.g. `checkKeySet` → `checkKeyset`). A call that works today keeps
  working on every later build - so one `>=` check per feature is enough, never a chain.
- **Template keys** (e.g. `column3` / `column4`) are simply ignored by older builds -
  they need no gating at all.
- Adding an argument to *your* calls is the only thing that can break on an *older* build
  (Python raises `TypeError` for an unknown keyword) - which is exactly what the version
  gate above prevents.

## Available everywhere (plain izeberg and every aslainMenu build)

`g_modsSettingsApi`: `setModTemplate(linkage, template, callback, buttonHandler=None)`,
`updateModSettings`, `registerCallback`, `getModSettings`, `getModData`, `saveModData`,
`checkKeyset` (with `checkKeySet` as a deprecated alias), `getAllHotkeys`.

`templates`: `createEmpty`, `createLabel`, `createCheckbox`, `createRadioButtonGroup`,
`createDropdown`, `createSlider`, `createRangeSlider`, `createStepSlider`,
`createNumericStepper`, `createInput`, `createHotkey`, `createColorChoice`,
`createButton` (plus the low-level `createBase` / `createControl` /
`createOptionsControl` / `createStepper` / `generateOptions` they build on).

Template basics: `modDisplayName`, `column1` / `column2`, `enabled`, `settingsVersion`,
`{HEADER}` / `{BODY}` tooltips.

## aslainMenu additions, by version

| Since | Feature |
|---|---|
| 1.0.0 | `reloadModTemplate(linkage, template)` - re-render one mod in place |
| 1.0.0 | `registerLiveSettingsChange(linkage, callback)` / `unregisterLiveSettingsChange` - uncommitted value changes, live |
| 1.0.0 | `updateImage(linkage, varName, source, width, height)` - live image swap |
| 1.0.0 | `templates.createImage(source, width, height, ...)` - image in the menu body |
| 1.0.0 | `templates.createControlsGroup(master, children)` - sub-options greyed while the master is off |
| 1.1.0 | `templates.enableWhen(control, masterVar, value)` - value-conditional grey-out |
| 1.1.0 | `updateImage(..., removeImage=True)` - collapse the image slot |
| 1.1.0 | `registerLiveSettingsChange(..., mode='changedOnly')` - deprecated, use `fullsettings=False` (1.2.0) |
| 1.1.1 | `createImage(..., collapsed=, label=, labelAlign=)` and `updateImage(..., label=)` |
| 1.2.0 | `getVersion()` / `getVersionTuple()` + importable `VERSION` / `VERSION_TUPLE` |
| 1.2.0 | `createHotkey(..., float='right')` - long label wraps around the keys |
| 1.2.0 | `enableWhen(..., condition=...)` + the `CONDITION` constants (`==`, `!=`, `>`, `>=`, `<`, `<=`) |
| 1.2.0 | `registerLiveSettingsChange(..., fullsettings=False)` - changed-only payload |
| 1.2.1 | `updateImageAtlas(...)` and `createImage(atlas={...})` - sprite-sheet animation |
| 1.3.0 | `templates.visibleWhen` (hide + reflow), `enableWhenAll` / `enableWhenAny`, `visibleWhenAll` / `visibleWhenAny` |
| 1.3.0 | `templates.escape(text)` and `useHTML=False` on every `create*` control |
| 1.3.0 | `createControlsGroup(..., indent=False)` |
| 1.3.0 | `resetModToDefaults(linkage)` (the per-mod reset button uses it) |
| 1.3.1 | `registerModTranslation(linkage, mapping)` - display-only label translation |
| 1.4.0 | `templates.createCheckboxColor(text, varName, value, color, ...)` |
| 1.5.0 | `createColorChoice` / `createCheckboxColor` `presets=[...]` and `presetsOnly=True` |
| 1.6.0 | `setModTemplate(..., multiColumnTemplate=...)` and `reloadModTemplate(..., multiColumnTemplate=...)` |
| 1.6.0 | Template keys `column3` / `column4` (ignored by older builds - no gating needed) |
| 1.6.0 | `templates.markNew(control)` and `markNew(control, token='...')` |
| 1.6.1 | `createRadioButtonGroup(..., inline=True)` - options in one horizontal row |
| 1.6.1 | Behavior: images pushed via `updateImage` / `updateImageAtlas` survive layout rebuilds (the multi-column switch replays them) |

Functions detectable with `hasattr()` (new *names*, e.g. `markNew`, `updateImageAtlas`)
can also be feature-detected directly; new *arguments* on existing functions (`inline`,
`float`, `presets`, `multiColumnTemplate`, ...) cannot - use the version gate for those.
