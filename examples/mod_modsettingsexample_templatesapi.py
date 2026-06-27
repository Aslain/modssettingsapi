
import BigWorld
import game
import Keys
try:
	from gui.aslainMenu import g_modsSettingsApi, templates
except ImportError:
	from gui.modsSettingsApi import g_modsSettingsApi, templates

modLinkage = 'test_iamspotted_templatesAPI'
modDataVersion = 1

template = {
	'modDisplayName': 'I Am Spotted #2',
	'enabled': True,
	'column1': [
		templates.createCheckbox('Show the spotted square on the minimap', 
								 'minimapClick', 
								 True, 
								 tooltip='{HEADER}Show the spotted square on the minimap{/HEADER}{BODY}When you get spotted, the mod automatically clicks the minimap cell where you are{/BODY}'),
		templates.createCheckbox('Send "Need help!" to team chat', 
								 'neadHelp', 
								 True, 
								 tooltip='{HEADER}Send "Need help!" to team chat{/HEADER}{BODY}When you get spotted, the mod automatically sends the "Need help!" command to your allies{/BODY}'),
		templates.createDropdown('Sixth Sense voice line', 'sixthSenseSound', 
								 ['Standard', 'Quiet', 'Loud'], 0, 
								 tooltip='{HEADER}Sixth Sense voice line{/HEADER}{BODY}When the Sixth Sense perk triggers, one of several voice lines is played.{/BODY}', 
								 button=templates.createButton(width=30, height=23, offsetTop=0, offsetLeft=0, 
															   icon='../maps/icons/buttons/sound.png', 
															   iconOffsetTop=0, iconOffsetLeft=1), 
								 width=200)
	],
	'column2': [
		templates.createSlider('Number of alive allies required to activate the mod', 
							   'aliveCounter', 
							   5, 1, 15, 1),
		templates.createStepSlider('StepSlider example', 
								   'stepSliderTest', ['Standard', 'Quiet', 'Loud'], 0),
		templates.createCheckbox('Always warn about being spotted when playing artillery',
								 'alwaysOnArty', True,
								 tooltip='{HEADER}Always warn about being spotted when playing artillery{/HEADER}{BODY}If you enter a battle in an SPG, the mod always warns you about being spotted, regardless of the configured limit on the number of allies left alive{/BODY}'),
		templates.createHotkey('Toggle on/off with a key',
							   'stateKeyset', [Keys.KEY_J],
							   tooltip='{HEADER}Toggle on/off with a key{/HEADER}{BODY}Activates or deactivates the mod when the key / key combination is pressed{/BODY}'),
		templates.createNumericStepper('NumericStepper test',
									   'numStepperTest', 5,
									   1, 15, 0.1, 
									   tooltip='{HEADER}NumericStepper tooltip header{/HEADER}{BODY}NumericStepper tooltip body{/BODY}'),
		templates.createColorChoice('ColorChoice test',
									'colorChoice', '#ffffff',
									tooltip='{HEADER}ColorChoice tooltip header{/HEADER}{BODY}ColorChoice tooltip body{/BODY}'),
		templates.createRangeSlider('RangeSlider test',
									'rangeSlider', [20, 50], 0, 100, 1,
									50, 10, 50, '')
	]
}

# enableWhen (aslainMenu-only): grey a control unless a master control holds a value
if hasattr(templates, 'enableWhen'):
	template['column2'].append(templates.createRadioButtonGroup('Spot mode', 'spotMode', ['Minimap', 'Chat'], 0))
	template['column2'].append(templates.enableWhen(templates.createSlider('Minimap blink count', 'blinkCount', 3, 1, 10, 1), 'spotMode', 0))
	template['column2'].append(templates.enableWhen(templates.createDropdown('Chat phrase', 'chatPhrase', ['Help!', 'SOS', 'Spotted'], 0), 'spotMode', 1))

# createCheckboxColor (aslainMenu-only): a checkbox paired with a colour picker on one row. The
# stored value is a dict, read as settings['checkboxColor']['enabled'] and ['color'].
if hasattr(templates, 'createCheckboxColor'):
	template['column2'].append(templates.createCheckboxColor('CheckBoxColor test', 'checkboxColor', True, 'FFCC00',
								tooltip='{HEADER}CheckBoxColor tooltip header{/HEADER}{BODY}A checkbox and a colour picker on one row; the value is a dict with enabled and color{/BODY}'))


settings = {
	'sixthSenseSound' : 0,
	'stateKeyset' : [Keys.KEY_J],
	'alwaysOnArty' : True,
	'neadHelp' : True,
	'enabled' : True,
	'minimapClick' : True,
	'aliveCounter' : 5,
	'numStepperTest' : 5,
	'colorChoice' : 'FFFFFF',
	'checkboxColor' : {'enabled': True, 'color': 'FFCC00'},
	'rangeSlider' : [20, 50],
	'stepSliderTest': 0
}

def onModSettingsChanged(linkage, newSettings):
	if linkage == modLinkage:
		print('onModSettingsChanged', newSettings)


def onButtonClicked(linkage, varName, value):
	if linkage == modLinkage:
		clicks = g_modsSettingsApi.getModData(modLinkage, modDataVersion, 0)
		clicks += 1
		g_modsSettingsApi.saveModData(modLinkage, modDataVersion, clicks)
		print('onButtonClicked', linkage, varName, value, clicks)


def onGameKeyDown(event):
	if g_modsSettingsApi.checkKeyset(settings['stateKeyset']):
		print('onHandleKeyEvent', settings['stateKeyset'])


savedSettings = g_modsSettingsApi.getModSettings(modLinkage, template)
if savedSettings:
	settings = savedSettings
	g_modsSettingsApi.registerCallback(modLinkage, onModSettingsChanged, onButtonClicked)
else:
	settings = g_modsSettingsApi.setModTemplate(modLinkage, template, onModSettingsChanged, onButtonClicked)


