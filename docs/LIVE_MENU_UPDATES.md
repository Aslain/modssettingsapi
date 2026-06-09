# Image component + live menu updates

These additive pieces let a mod:
- show an **image directly in the settings menu body** (not only inside a tooltip),
- update that image **live** while the window is open (`updateImage`),
- react to **uncommitted** in-menu changes before Apply (`registerLiveSettingsChange`),
- **re-render its whole component subtree in place** without closing the window
  (`reloadModTemplate`) — e.g. to switch the menu language instantly.

Everything is backward compatible: mods that don't use these are unaffected, and you
can feature-detect with `hasattr(...)` so your mod still runs on older API builds.

---

## 1. `templates.createImage(source, width=None, height=None, tooltip=None, tooltipIcon=None, varName=None)`

Creates a component that renders an image in the menu body.

| param | meaning |
|---|---|
| `source` | Image path readable by the game's image loader (the **same loader** tooltips use for `<img src="img://...">`). Pass the path **without** the `img://` prefix. |
| `width`, `height` | Render size in px. Pass an **aspect-correct** pair to avoid distortion (see below). Optional; default 96×96. |
| `tooltip`, `tooltipIcon` | Optional, like other components. |
| `varName` | Optional. **Only** needed if you want to live-update this image via `updateImage()`. It is *not* a value field — it never appears in your settings dict. |
| `align` | `'left'` (default), `'center'` or `'right'` — horizontal position inside the box. |
| `valign` | `'top'` (default), `'center'` or `'bottom'` — vertical position inside the box. |
| `containerWidth` | Width in px of the box the image is positioned within (defaults to the image width). |
| `containerHeight` | Height in px of the box the image is positioned within (defaults to the image height). |

The image keeps its `width`×`height` (aspect-correct) and is placed inside the
`containerWidth`×`containerHeight` box per `align`/`valign`. A **fixed
`containerHeight` gives the component a fixed layout slot**, so live updates that
change the image size do not shift the components below it. `align`/`valign`/
`containerWidth`/`containerHeight` are preserved across `updateImage()` calls.

```python
# fixed 240x110 slot, image centered — live updates never shift the layout below
templates.createImage(src, w, h, varName='iconPreview',
                      align='center', valign='center',
                      containerWidth=240, containerHeight=110)
```

```python
templates.createImage('../../mods/config/mymod/icon.png', 96, 72, varName='iconPreview')
```

### Image path
- Resolved **relative to the menu SWF** (`res/gui/flash/`). For files under
  `mods/config` use `../../mods/config/<yourmod>/<file>.png`.
- Works for images packed in your mod's `res/` **and** physical files in `mods/config`.
- Spaces in the path are fine (do **not** URL-encode them).

### Keep proportions yourself
The image is rendered at exactly `width`×`height` (no auto-fit), so compute an
aspect-correct size from the real pixel dimensions to fit your box:

```python
BOX_W, BOX_H = 200.0, 96.0
scale = min(BOX_W / imgW, BOX_H / imgH)
w, h = max(1, int(round(imgW * scale))), max(1, int(round(imgH * scale)))
```

Then place that `w`×`h` image inside a slightly larger fixed box with
`containerWidth`/`containerHeight` + `align`/`valign`. Keeping the box larger than the
biggest image (and fixed) means switching between images of different sizes never
clips them and never shifts the layout.

---

## 2. `g_modsSettingsApi.updateImage(linkage, varName, source, width=96, height=96)`

Replaces an already-displayed Image **in place** — no full menu re-render, so scroll
position and focus are preserved. The target is matched by `linkage` + `varName`.

```python
g_modsSettingsApi.updateImage('MyMod', 'iconPreview', newSrc, w, h)
```

Returns nothing; safe to call whenever the window is open.

---

## 3. `g_modsSettingsApi.registerLiveSettingsChange(linkage, callback)`

Registers a callback fired on **every** in-menu value change (dropdown / slider /
checkbox / …) **immediately, before the user presses Apply**. Use it to drive live
previews.

- `callback(linkage, settings)` — `settings` is a dict of the **current
  (uncommitted)** values of that mod's components (same shape as the
  `onModSettingsChanged` settings, minus value-less components such as Image).
- Filter by `linkage == YOUR_LINKAGE`.
- These changes are **not persisted** — pressing **Cancel** discards them. The normal
  `onModSettingsChanged` callback still fires on **Apply/OK** to commit.
- Detach with `g_modsSettingsApi.unregisterLiveSettingsChange(linkage, callback)`.

---

## 4. `g_modsSettingsApi.reloadModTemplate(linkage, template)`

Re-renders **one mod's whole component subtree in place** in the open window, from a
fresh template — without closing/reopening it and without touching other mods. The
typical use is an **instant language switch**: rebuild the template with new-language
labels and the current values, then call this.

- The mod owns the template: fill it with the **values you want shown** (e.g. the
  current uncommitted values from `registerLiveSettingsChange`), because the re-render uses
  the template's own component values.
- Does **not** persist anything and does **not** modify the stored template, so it is
  purely visual — Apply/OK still commits via the normal `onModSettingsChanged`, and
  Cancel/Close still discards.
- Other mods are untouched; the components below are re-flowed to the new height.
- Re-rendered **hotkey** controls are re-filled automatically (the API re-applies the
  stored keysets after the reload), so a reload never wipes hotkeys.
- No effect if the window is closed.

**Re-entrancy:** call it from a deferred callback (e.g. `BigWorld.callback(0, ...)`),
not directly inside the `registerLiveSettingsChange` handler — the reload removes/recreates
the components whose event is still on the stack.

```python
def onLiveSettingsChange(self, linkage, settings):
    if linkage != LINKAGE:
        return
    newLang = settings.get('language')
    if newLang is not None and newLang != self._shownLang and hasattr(g_modsSettingsApi, 'reloadModTemplate'):
        self._shownLang = newLang
        self._loadLanguage(newLang)                       # swap i18n, do NOT persist
        state = dict(self.state); state.update(settings)  # keep current values
        template = self._buildTemplate(values=state)       # new labels + current values
        BigWorld.callback(0.0, lambda: g_modsSettingsApi.reloadModTemplate(LINKAGE, template))
```

---

## Complete example — icon preview that updates the instant you change the dropdown

```python
class MyMod(object):

    def _setup(self):
        self.template = self._buildTemplate()
        g_modsSettingsApi.setModTemplate(LINKAGE, self.template, self.onSettingsChanged)
        # Live preview is optional — feature-detect for older API builds.
        if hasattr(g_modsSettingsApi, 'registerLiveSettingsChange'):
            g_modsSettingsApi.registerLiveSettingsChange(LINKAGE, self.onLiveSettingsChange)

    def _previewColumn(self):
        w, h = self._previewSize(self.state)            # aspect-correct, fits 200x96
        return [
            templates.createDropdown('Icon', 'icon', OPTIONS, self.state['icon']),
            # Fixed 240x110 slot, image centered: switching icons never shifts the
            # slider below, regardless of each icon's size.
            templates.createImage(self._previewSrc(self.state), w, h,
                                  varName='iconPreview',
                                  align='center', valign='center',
                                  containerWidth=240, containerHeight=110),
            templates.createSlider('Scale', 'scale', 1.0, 0.5, 2.0, 0.1),
        ]

    # Fires on every change, BEFORE Apply — live preview only, not persisted.
    def onLiveSettingsChange(self, linkage, settings):
        if linkage != LINKAGE:
            return
        state = dict(self.state)
        state.update(settings)                          # do NOT mutate self.state
        w, h = self._previewSize(state)
        # The image re-centers in the same fixed slot; align/valign/container* are
        # remembered from createImage, so updateImage only needs the new size.
        g_modsSettingsApi.updateImage(LINKAGE, 'iconPreview',
                                      self._previewSrc(state), w, h)

    # Fires on Apply/OK — commit & persist.
    def onSettingsChanged(self, linkage, settings):
        if linkage != LINKAGE:
            return
        self.state.update(settings)
        self._persist()
        self._apply()
```

---

## Internals (for maintainers)

Data flow of the live channel:

```
dropdown change (AS3)
  -> InteractiveEvent.VALUE_CHANGED
  -> ModsSettingsComponent.handleComponentEvent -> SETTINGS_CHANGED(linkage)
  -> ModsSettingsWindow.handleModSettingsChanged
       -> notifyLiveChange(linkage): componentChanged(JSON of mod.getConfigData())
  -> view.componentChanged  ->  api.notifyLiveSettingsChange(linkage, settings)
  -> api.onLiveSettingsChange event  ->  mod callback  ->  g_modsSettingsApi.updateImage(...)
  -> view.__onImageUpdate -> as_updateImage -> ModsSettingsComponent.updateImage
       -> TextField.htmlText = "<img src='img://...'>"
```

The Image component renders through a plain `flash.text.TextField` (multiline) with an
`<img>` tag — the same path Scaleform uses for tooltip images — rather than a
`UILoaderAlt`, which cannot read from `mods/config`. Components with a `varName` but no
return value (Image) are guarded in `getConfigData` (AS3) and `generateSettingsData`
(Python) so they don't break settings collection.

Data flow of `reloadModTemplate`:

```
mod -> api.reloadModTemplate(linkage, template)   (adds 'linkage' to template)
  -> api.onReloadMod event -> view.__onReloadMod -> as_reloadModS
  -> ModsSettingsWindow.as_reloadMod(linkage, template)
       -> content.reloadMod: find old ModsSettingsComponent by linkage, remove it,
          create a new one at the same index, reflowMods() re-lays out all mods
       -> replace the entry in modsArray
  -> api.onHotkeysUpdated() -> view re-sends getAllHotkeys() -> as_setHotkeys
       (re-fills the freshly created hotkey controls with their stored keysets)
```

`getHotkeyData` treats a missing/`None` keyset as empty instead of raising, so a
partially-populated hotkey can never crash `getAllHotkeys` (which would otherwise abort
`requestModsData` and blank every mod's hotkeys).
