"""Example of the Aslain Menu only features:
- createImage with a built-in label + live updateImage (incl. removeImage)
- createImage(atlas=...) + updateImageAtlas: sprite-sheet animation (illustrative, at the bottom)
- registerLiveSettingsChange with fullsettings=False (changed-only payload)
- enableWhen (value-conditional grey-out) + enableWhenAll (gate on several masters)
- visibleWhen (hide + reflow instead of greying)
- createControlsGroup (sub-options greyed while the master is off; indent=False keeps them flush)
- createCheckboxColor (1.4.0): a checkbox + color picker on one row, here doubling as a gating master
- presets / presetsOnly (1.5.0): the picker offers only the mod's own palette, optionally exclusively
- markNew (1.6.0): flag a freshly added option so the window shows a red flare + a title counter
- useHTML=False / templates.escape (literal <, >, & in a label)
- getVersionTuple() version-gating (guarded for older builds)
Every Aslain Menu only call is feature-detected with hasattr(), so this mod still
loads (without the extras) on the plain izeberg menu.
"""
import BigWorld

try:
	from gui.aslainMenu import g_modsSettingsApi, templates
except ImportError:
	from gui.modsSettingsApi import g_modsSettingsApi, templates

modLinkage = 'test_aslainfeatures'

# Shipped with this API, so the example works out of the box. Image sources are
# plain root-relative paths (gui/maps/... or mods/configs/...) - no img://, no ../
PREVIEW_ICON = 'gui/maps/icons/aslainMenu/icon.png'

settings = {
	'enabled': True,
	'alertsOn': True,
	'alertVolume': 5,
	'previewMode': 0,
	'iconSize': 50,
	'iconOpacity': 100,
	'iconPulse': False,
	'hpWarn': True,
	'dmgNumbers': {'enabled': True, 'color': 'F23030'},
	'dmgSize': 5,
	'teamColor': 'F23030',
	'fadeTime': 5,
}


def buildTemplate():
	column1 = []

	# Grouped sub-options: the slider is indented and greyed-out while
	# 'alertsOn' is unchecked.
	master = templates.createCheckbox('Enable alerts', 'alertsOn', settings['alertsOn'])
	children = [templates.createSlider('Alert volume', 'alertVolume', settings['alertVolume'], 1, 10, 1)]
	if hasattr(templates, 'createControlsGroup'):
		# Pass indent=False to keep the children flush with the master instead of
		# indented - handy for a wide group that would crowd the second column.
		column1 += templates.createControlsGroup(master, children)
	else:
		column1 += [master] + children

	# Literal text in a label (useHTML=False, 1.3.0): the '<' shows verbatim instead of
	# being parsed as HTML markup; templates.escape(text) does the same for a fragment.
	try:
		column1.append(templates.createCheckbox('Warn when HP < 25%', 'hpWarn', settings['hpWarn'], useHTML=False))
	except TypeError:
		column1.append(templates.createCheckbox('Warn when HP below 25%', 'hpWarn', settings['hpWarn']))

	# markNew (1.6.0): flag an option a mod update just added, so the window shows a red
	# flare on its row + a red count on the mod's title (like the game's own Settings).
	# The highlight clears once the user clicks the row or changes the value, and is
	# remembered per user; a mod's first install never lights up. Wrap inline; older
	# builds ignore the flag, so guard with hasattr.
	fadeSlider = templates.createSlider('Fade time', 'fadeTime', settings['fadeTime'], 1, 15, 1)
	if hasattr(templates, 'markNew'):
		templates.markNew(fadeSlider)
	column1.append(fadeSlider)

	column2 = [
		templates.createRadioButtonGroup('Preview', 'previewMode', ['Icon', 'No image'], settings['previewMode']),
	]

	# Value-conditional grey-out: the size slider is editable only while
	# 'previewMode' sits on 'Icon' (value 0), updating live as it changes.
	sizeSlider = templates.createSlider('Icon size', 'iconSize', settings['iconSize'], 25, 100, 1)
	if hasattr(templates, 'enableWhen'):
		templates.enableWhen(sizeSlider, 'previewMode', 0)
	column2.append(sizeSlider)

	# Hide instead of grey (visibleWhen, 1.3.0): the opacity slider only shows while
	# 'previewMode' is on 'Icon' (value 0); the rows below close the gap when it hides.
	if hasattr(templates, 'visibleWhen'):
		opacity = templates.createSlider('Icon opacity', 'iconOpacity', settings['iconOpacity'], 0, 100, 5)
		templates.visibleWhen(opacity, 'previewMode', 0)
		column2.append(opacity)

	# Gate on several masters at once (enableWhenAll = AND; enableWhenAny = OR, 1.3.0):
	# editable only while alerts are on AND the preview shows the icon.
	if hasattr(templates, 'enableWhenAll'):
		pulse = templates.createCheckbox('Pulse the icon when spotted', 'iconPulse', settings['iconPulse'])
		templates.enableWhenAll(pulse, [{'varName': 'alertsOn', 'value': True},
										{'varName': 'previewMode', 'value': 0}])
		column2.append(pulse)

	# CheckBoxColor (1.4.0) as a gating master: a checkbox + color picker on one row, storing a
	# {'enabled', 'color'} pair. Its 'enabled' half greys the size slider below when unchecked.
	if hasattr(templates, 'createCheckboxColor'):
		column2.append(templates.createCheckboxColor('Damage numbers', 'dmgNumbers',
					settings['dmgNumbers']['enabled'], settings['dmgNumbers']['color']))
		dmgSize = templates.createSlider('Damage number size', 'dmgSize', settings['dmgSize'], 1, 10, 1)
		if hasattr(templates, 'enableWhen'):
			templates.enableWhen(dmgSize, 'dmgNumbers', True)
		column2.append(dmgSize)

	# presets / presetsOnly (1.5.0): the picker offers only this mod's palette; presetsOnly
	# shrinks it to the swatches + Apply, so the user picks exactly one of these colors.
	# Plain keyword arguments - version-gate them for older builds.
	if hasattr(g_modsSettingsApi, 'getVersionTuple') and g_modsSettingsApi.getVersionTuple() >= (1, 5):
		column2.append(templates.createColorChoice('Team color', 'teamColor', settings['teamColor'],
					presets=['F23030', '30F230', 'F230F2'], presetsOnly=True))
	else:
		column2.append(templates.createColorChoice('Team color', 'teamColor', settings['teamColor']))

	# Image with a built-in label: the caption collapses/expands together with
	# the image and can be live-updated via updateImage(label=...).
	if hasattr(templates, 'createImage'):
		column2.append(templates.createImage(
			PREVIEW_ICON, settings['iconSize'], settings['iconSize'],
			varName='preview', align='center', valign='center',
			containerWidth=120, containerHeight=120,
			label='Preview', labelAlign='center',
			collapsed=(settings['previewMode'] == 1)))

	return {
		'modDisplayName': 'Aslain Menu Features Example',
		'enabled': settings['enabled'],
		'column1': column1,
		'column2': column2,
	}


def onLiveSettingsChange(linkage, changed):
	# fullsettings=False: 'changed' holds only the keys the user just changed
	# (not the whole settings dict), so you refresh only those. It fires live
	# while the menu is open - use it to update previews as the user edits.
	if linkage != modLinkage:
		return
	if 'previewMode' in changed:
		if int(changed['previewMode']) == 1:
			g_modsSettingsApi.updateImage(modLinkage, 'preview', '', 0, 0, removeImage=True)
		else:
			size = settings['iconSize']
			g_modsSettingsApi.updateImage(modLinkage, 'preview', PREVIEW_ICON, size, size,
										  label="Preview: <font color='#80D639'>icon</font>")
	if 'iconSize' in changed:
		size = int(changed['iconSize'])
		g_modsSettingsApi.updateImage(modLinkage, 'preview', PREVIEW_ICON, size, size)


def onModSettingsChanged(linkage, newSettings):
	# Fires on Apply/OK - commit the values.
	if linkage == modLinkage:
		settings.update(newSettings)
		print('onModSettingsChanged', newSettings)


g_modsSettingsApi.setModTemplate(modLinkage, buildTemplate(), onModSettingsChanged)

# Read the API version when you need to adapt (guarded - older builds lack getVersionTuple;
# compare the tuple form, not the string).
getVer = getattr(g_modsSettingsApi, 'getVersionTuple', None)
apiVersion = getVer() if getVer else (0, 0, 0)

if hasattr(g_modsSettingsApi, 'registerLiveSettingsChange'):
	if apiVersion >= (1, 2):
		# 1.2.0+: choose the payload with the fullsettings flag (False = changed-only keys).
		g_modsSettingsApi.registerLiveSettingsChange(modLinkage, onLiveSettingsChange, fullsettings=False)
	else:
		# Older API builds used the now-deprecated mode= argument for the same thing.
		g_modsSettingsApi.registerLiveSettingsChange(modLinkage, onLiveSettingsChange, mode='changedOnly')


# --- Sprite-sheet animation (illustrative; supply your own sheet) -------------
# Animate an Image slot from ONE sprite sheet - a grid of frames in a single PNG -
# instead of swapping many separate frame files. Two calls, mirroring the static
# createImage / updateImage pair (1.2.1+, feature-detect with hasattr):
#
#   # 1) initial animation - starts the moment the menu opens (it renders at build
#   #    time, so no race with a post-open update). The positional source is unused
#   #    when atlas= is given, so pass ''.
#   if hasattr(templates, 'createImage'):
#       column2.append(templates.createImage(
#           '', 96, 96, varName='anim', align='center', valign='center',
#           containerWidth=120, containerHeight=120,
#           atlas={'source': 'mods/configs/mymod/spin_atlas.png',
#                  'frameWidth': 64, 'frameHeight': 64,   # one cell's size
#                  'columns': 8, 'count': 60,             # 8 cells per row, 60 frames, row-major
#                  'fps': 30, 'loop': True}))             # loop=False plays once, holds last frame
#
#   # 2) switch the animation live, e.g. inside onLiveSettingsChange when a dropdown
#   #    changes - same grid parameters, flat instead of a dict:
#   if hasattr(g_modsSettingsApi, 'updateImageAtlas'):
#       g_modsSettingsApi.updateImageAtlas(modLinkage, 'anim',
#           'mods/configs/mymod/other_atlas.png', 64, 64, 8, 48, 24, True, 96, 96)
