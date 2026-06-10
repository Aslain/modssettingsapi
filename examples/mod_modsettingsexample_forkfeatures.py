"""Example of the aslainMenu fork-only features:
- createImage with a built-in label + live updateImage (incl. removeImage)
- registerLiveSettingsChange with mode='changedOnly'
- enableWhen (value-conditional grey-out)
- createControlsGroup (sub-options greyed while the master is off)
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
	# mode='changedOnly': 'changed' holds only the keys whose value changed
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
if hasattr(g_modsSettingsApi, 'registerLiveSettingsChange'):
	g_modsSettingsApi.registerLiveSettingsChange(modLinkage, onLiveSettingsChange, mode='changedOnly')
