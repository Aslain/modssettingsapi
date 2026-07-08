# Image component + live menu updates

These additive pieces let a mod:
- show an **image directly in the settings menu body** (not only inside a tooltip),
- update that image **live** while the window is open (`updateImage`),
- **animate a sprite sheet** in that image slot, both on open and live (`createImage(atlas=...)` / `updateImageAtlas`),
- react to **uncommitted** in-menu changes before Apply (`registerLiveSettingsChange`),
- **re-render its whole component subtree in place** without closing the window
  (`reloadModTemplate`) — e.g. to switch the menu language instantly.
- **keep conditionally-shown controls correct across reopens** (`visibleWhen` /
  `createControlsGroup`), and react to the window opening / closing for lightweight tasks
  (`onWindowOpened` / `onWindowClosed`).

Everything is backward compatible: mods that don't use these are unaffected, and you
can feature-detect with `hasattr(...)` so your mod still runs on older API builds.

---

## 1. `templates.createImage(source, width=None, height=None, tooltip=None, tooltipIcon=None, varName=None, align=None, valign=None, containerWidth=None, containerHeight=None, collapsed=False)`

Creates a component that renders an image in the menu body.

| param | meaning |
|---|---|
| `source` | Plain root-relative image path resolved from the WoT root: `gui/maps/...` for resources (including images packed in your mod's `res/`) or `mods/configs/<yourmod>/<file>.png` for files on disk. No `img://` prefix, no `../` climbing. |
| `width`, `height` | Maximum render size in px: the image is fitted (aspect-correct) within `width`×`height`, **never upscaled**. Optional; when omitted the image renders at its natural size, shrunk to fit the container if oversized. |
| `tooltip`, `tooltipIcon` | Optional, like other components. |
| `varName` | Optional. **Only** needed if you want to live-update this image via `updateImage()`. It is *not* a value field — it never appears in your settings dict. |
| `align` | `'left'` (default), `'center'` or `'right'` — horizontal position inside the box. |
| `valign` | `'top'` (default), `'center'` or `'bottom'` — vertical position inside the box. |
| `containerWidth` | Width in px of the box the image is positioned within (defaults to the image width). |
| `containerHeight` | Height in px of the box the image is positioned within (defaults to the image height). |
| `collapsed` | `True` starts the slot **collapsed** (zero height) instead of reserving the full box; expand it later with `updateImage(..., source)`. Default `False` keeps the reserved slot. |
| `label` | Optional text label rendered **above the image, inside the component** — it collapses/expands together with the image (no orphaned caption over a collapsed preview) and can be live-updated via `updateImage(..., label=...)`. Same html markup as other menu labels (e.g. `<font color='#80D639'>`). Pass `''` to reserve an empty label slot; omitted = no label slot. |
| `labelAlign` | `'left'` (default), `'center'` or `'right'` — horizontal alignment of the label within the container box, independent of the image's own `align`. |
| `atlas` | Optional dict — makes this image a **looping sprite-sheet animation** that starts the moment the menu opens: `{source, frameWidth, frameHeight, columns, count, fps, loop}`. See the **Sprite-sheet animation** section below. Omit it for a normal static image (backward-compatible). |

The image is fitted (aspect-correct, never upscaled) within `width`×`height` and
placed inside the `containerWidth`×`containerHeight` box per `align`/`valign`. A
**fixed `containerHeight` gives the component a fixed layout slot**, so live updates
that change the image size do not shift the components below it. `align`/`valign`/
`containerWidth`/`containerHeight` are preserved across `updateImage()` calls.

Pass **`collapsed=True`** to start with no reserved slot at all — handy when the
mod's default option shows no image (e.g. a "Deactivated" state): the placeholder
takes zero height until the first `updateImage()` with a source expands it.

```python
# fixed 240x110 slot, image centered — live updates never shift the layout below
templates.createImage(src, w, h, varName='iconPreview',
                      align='center', valign='center',
                      containerWidth=240, containerHeight=110)
```

```python
templates.createImage('mods/configs/mymod/icon.png', 96, 72, varName='iconPreview')
```

### Image path
- Plain root-relative paths resolved from the WoT root: `gui/maps/...` for resources
  (including images packed in your mod's `res/`), `mods/configs/...` for physical
  files on disk. The API does the climbing internally — pass clean paths.
- Spaces in the path are fine (do **not** URL-encode them).

### Sizing
Aspect ratio is always preserved and the image is **never upscaled**, so
`width`×`height` act as a maximum box: an oversized image is shrunk to fit, a smaller
one renders at its natural size. Omit both to simply fit the container. A fixed,
slightly larger `containerWidth`/`containerHeight` box (with `align`/`valign`) keeps
the layout stable when switching between images of different sizes, and `scrollRect`
clipping guarantees nothing can overflow it.

---

## 2. `g_modsSettingsApi.updateImage(linkage, varName, source, width=None, height=None, removeImage=False, label=None)`

Replaces an already-displayed Image **in place** — no full menu re-render, so scroll
position and focus are preserved. The target is matched by `linkage` + `varName`.
`width`/`height` work like in `createImage`: a maximum fit box, optional — omitted
means natural size, shrunk to fit the container if oversized.

```python
g_modsSettingsApi.updateImage('MyMod', 'iconPreview', newSrc, w, h)
```

Pass **`label`** to change the text of the image's label slot on the fly (e.g.
`label='Preview (unsaved)'` while the user has uncommitted changes). `None` (default)
keeps the current text, `''` clears it. The slot itself must exist — create the Image
with `label=...` (use `label=''` to reserve an empty slot); its height is fixed at
creation so text changes never shift the layout. Passing `label` for an Image created
**without** a label slot is a safe no-op: the text is silently ignored (no error) and
the image itself still updates.

Pass **`removeImage=True`** to **collapse** the image container to zero height (the
`source`/`width`/`height` are ignored): the controls below it — and the mods below this
one — jump up to fill the gap. Default `False` keeps the reserved slot. Set a `source` again later to bring it back
(the slot re-expands).

Returns nothing; safe to call whenever the window is open.

Since 1.6.1 a pushed image also **survives layout rebuilds**: the API remembers the last
`updateImage` / `updateImageAtlas` per control and replays it after the window rebuilds
the mods (the multi-column toggle, or a resize crossing a column boundary). Before that,
a rebuild silently dropped the runtime image and showed the template's initial one again.
Nothing to do on the mod side — pushing on every change (as below) keeps working and is
still the right pattern.

---

## 3. Sprite-sheet animation — `createImage(atlas={...})` + `g_modsSettingsApi.updateImageAtlas(...)`

Animate an `Image` slot from a **single sprite sheet** (a grid of frames in one image) instead of swapping hundreds of separate frame files. The sheet is loaded **once** and animated by blitting one grid cell per frame with `copyPixels` on a timer, so it stays light even at a high `fps`.

The sheet is a **row-major grid**: `count` frames, `columns` per row, each cell `frameWidth`×`frameHeight`. Frame *i* sits at column `i % columns`, row `i // columns` (the last row may be partial). `width`/`height` scale the displayed frame to fit, never upscaled, exactly like a static image.

Two entry points, mirroring the static `createImage` / `updateImage` pair:

**`createImage(..., atlas={...})`** — the image **starts animating at build time**, so it plays the instant the menu opens. Use it for the animation that is current when the template is built. `atlas` is a dict: `source` (the sheet path, root-relative like any image source), `frameWidth`, `frameHeight`, `columns`, `count`, `fps`, `loop` (`True` loops; `False` plays once and holds the last frame). The component's own first positional `source` is unused when `atlas` is given — pass `''`.

**`updateImageAtlas(linkage, varName, atlasSource, frameWidth, frameHeight, columns, count, fps, loop=True, width=None, height=None)`** — **switch the animation live** while the window is open (e.g. the user picked another animation in a dropdown), with no menu re-render. Same grid parameters, flat instead of a dict.

> **Why both?** The window fires your open/live callbacks **before** the Flash components are built, so a lone `updateImageAtlas` on open targets a component that does not exist yet (the slot stays empty until the first live change). `createImage(atlas=...)` renders inside the build pass — just as a static `createImage(source=...)` shows its image on open — so the animation is there immediately. Use `createImage(atlas=...)` for the initial animation and `updateImageAtlas(...)` for later live switches.

```python
# initial animation — plays as soon as the menu opens (source='' is unused with atlas=)
templates.createImage('', 96, 96, varName='preview',
                      align='center', valign='center',
                      containerWidth=120, containerHeight=120,
                      atlas={'source': 'mods/configs/mymod/spin_atlas.png',
                             'frameWidth': 64, 'frameHeight': 64,
                             'columns': 8, 'count': 60, 'fps': 30, 'loop': True})

# later, when the user selects a different animation in a dropdown (live, before Apply):
g_modsSettingsApi.updateImageAtlas('MyMod', 'preview',
                                   'mods/configs/mymod/other_atlas.png',
                                   64, 64, 8, 48, 24, True, 96, 96)
```

Both are aslainMenu-only and backward-compatible — feature-detect with `hasattr(g_modsSettingsApi, 'updateImageAtlas')`; the `atlas` kwarg is silently ignored by older `createImage` builds, so guard the same way before relying on it.

---

## 4. `g_modsSettingsApi.registerLiveSettingsChange(linkage, callback, fullsettings=True)`

Registers a callback fired on **every** in-menu value change (dropdown / slider /
checkbox / …) **immediately, before the user presses Apply**. Use it to drive live
previews.

- `callback(linkage, settings)` — `settings` is a dict of the **current
  (uncommitted)** values of that mod's components (same shape as the
  `onModSettingsChanged` settings, minus value-less components such as Image).
- **`fullsettings=False`** — `settings` then holds **only the keys whose value changed**
  since the previous live event, so you don't have to cache and diff yourself. The
  default `fullsettings=True` keeps the full dict; the callback signature is always
  `(linkage, dict)`, only the content differs. Setting a value back to its previous value
  yields an **empty dict `{}`** (treat as a no-op). The first change after the window
  opens is diffed against your committed settings, later changes against the previous
  live value.
- Filter by `linkage == YOUR_LINKAGE`.
- These changes are **not persisted** — pressing **Cancel** discards them. The normal
  `onModSettingsChanged` callback still fires on **Apply/OK** to commit.
- Detach with `g_modsSettingsApi.unregisterLiveSettingsChange(linkage, callback)`.

> **Deprecated:** the earlier `mode='changedOnly'` / `mode='fullsettings'` argument (and
> the `LIVE_SETTINGS_MODE` class) still work but are deprecated — passing `mode=` logs a
> one-time-per-linkage warning to `python.log` and will be removed in a future version.
> Switch to the `fullsettings` flag (`mode='changedOnly'` → `fullsettings=False`).

---

## 5. `g_modsSettingsApi.reloadModTemplate(linkage, template)`

Re-renders **one mod's component subtree in place** in the open window, from a
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
- The re-render is **incremental**: only controls whose type, variable, label or value
  changed are rebuilt — unchanged controls are reused in place (an instant language switch,
  for example, rebuilds the labels and keeps the controls whose values did not change).
- Re-rendered **hotkey** controls are re-filled automatically — the API re-applies the
  stored keysets after a reload.
- No effect if the window is closed — it re-renders the open window only. For conditional structure that should **persist** across reopens, gate the controls with `visibleWhen` / `createControlsGroup` (section 6); `reloadModTemplate` is for transient re-renders of the open window.

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

## 6. `g_modsSettingsApi.onWindowOpened` / `onWindowClosed`

Two `Event` hooks fired when the settings window opens and closes. Subscribe with `+=` and a **no-argument** handler; `hasattr`-guard them for older builds:

```python
if hasattr(g_modsSettingsApi, 'onWindowOpened'):
    g_modsSettingsApi.onWindowOpened += self._onWindowOpened   # def _onWindowOpened(self): ...
```

The two hooks are for **lightweight, non-UI reactions** — reset a live-preview baseline, log, start/stop a timer. Build and update components from the template and the live-update calls rather than from these hooks: they fire before the window's components are built.

For **conditional structure that should persist across reopens**, keep the controls in the template and **gate** them with `visibleWhen` (hide + reflow) or `createControlsGroup` (grey out). The API restores the controlling value on open and re-evaluates the gate, so they show/hide correctly both live and on every reopen, with no extra code:

```python
column += [
    templates.createCheckbox('Show extras', 'showExtras', False),
    templates.visibleWhen(templates.createSlider('Extra A', 'extraA', 5, 1, 10, 1), 'showExtras', True),
    templates.visibleWhen(templates.createSlider('Extra B', 'extraB', 5, 1, 10, 1), 'showExtras', True),
]
```

On open the menu shows the template registered with `setModTemplate`, so gating is what makes conditional structure persist; `reloadModTemplate` is for transient re-renders of the open window (e.g. a language switch). For a genuinely variable count, bake the maximum set into the template and toggle each row's `visibleWhen`.

`onWindowClosed` is the symmetric hook (e.g. to drop caches or stop a timer). Both are no-arg and backward-compatible.

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
  -> per-linkage callbacks (registerLiveSettingsChange)  ->  mod callback  ->  g_modsSettingsApi.updateImage(...)
  -> view.__onImageUpdate -> as_updateImage -> ModsSettingsComponent.updateImage
       -> ComponentsFactory.loadImageInto(holder, source)
```

The Image component loads through a plain `flash.display.Loader` (which reads both
`res/` and `mods/config`) and renders the decoded `Bitmap`, scaled to fit its container
while keeping aspect ratio and clipped (`scrollRect`) so it can never overflow the box;
decoded images are cached by source. Components with a `varName` but no
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
