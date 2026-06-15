"""Example of the aslainMenu fork-only features:
- createImage with a built-in label + live updateImage (incl. removeImage)
- createImage(atlas=...) + updateImageAtlas: sprite-sheet animation (illustrative, at the bottom)
- registerLiveSettingsChange with fullsettings=False (changed-only payload)
- enableWhen (value-conditional grey-out)
- createControlsGroup (sub-options greyed while the master is off)
- getVersionTuple() version-gating (guarded for older builds)
Every fork-only call is feature-detected with hasattr(), so this mod still
loads (without the extras) on the plain izeberg menu.
"""
import BigWorld

try:
	from gui.aslainMenu import g_modsSettingsApi, templates
except ImportError:
	from gui.modsSettingsApi import g_modsSettingsApi, templates

modLinkage = 'test_forkfeatures'

# Shipped with this API, so the example works out of the box. Image sources are
# plain root-relative paths (gui/maps/... or mods/configs/...) - no img://, no ../
PREVIEW_ICON = 'gui/maps/icons/aslainMenu/icon.png'

settings = {
	'enabled': True,
	'alertsOn': True,
	'alertVolume': 5,
	'previewMode': 0,
	'iconSize': 50,
}


def buildTemplate():
	column1 = []

	# Grouped sub-options: the slider is indented and greyed-out while
	# 'alertsOn' is unchecked.
	master = templates.createCheckbox('Enable alerts', 'alertsOn', settings['alertsOn'])
	children = [templates.createSlider('Alert volume', 'alertVolume', settings['alertVolume'], 1, 10, 1)]
	if hasattr(templates, 'createControlsGroup'):
		column1 += templates.createControlsGroup(master, children)
	else:
		column1 += [master] + children

	column2 = [
		templates.createRadioButtonGroup('Preview', 'previewMode', ['Icon', 'No image'], settings['previewMode']),
	]

	# Value-conditional grey-out: the size slider is editable only while
	# 'previewMode' sits on 'Icon' (value 0), updating live as it changes.
	sizeSlider = templates.createSlider('Icon size', 'iconSize', settings['iconSize'], 25, 100, 1)
	if hasattr(templates, 'enableWhen'):
		templates.enableWhen(sizeSlider, 'previewMode', 0)
	column2.append(sizeSlider)

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
		'modDisplayName': 'Fork Features Example',
		'enabled': settings['enabled'],
		'column1': column1,
		'column2': column2,
	}


def onLiveSettingsChange(linkage, changed):
	# fullsettings=False: 'changed' holds only the keys whose value changed
	# since the previous live event (uncommitted - Cancel discards them).
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
		# Older fork builds used the now-deprecated mode= argument for the same thing.
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
