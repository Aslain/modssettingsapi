
import BigWorld
import game
import Keys
try:
	from gui.aslainMenu import g_modsSettingsApi
except ImportError:
	from gui.modsSettingsApi import g_modsSettingsApi

modLinkage = 'test_iamspotted'
modDataVersion = 1

template  = {
	'modDisplayName': 'I Am Spotted',
	'enabled': True,
	'column1': [
		{
			'type': 'CheckBox',
			'text': 'Show the spotted square on the minimap',
			'value': True,
			'tooltip': '{HEADER}Show the spotted square on the minimap{/HEADER}{BODY}When you get spotted, the mod automatically clicks the minimap cell where you are{/BODY}',
			'varName': 'minimapClick'
		},
		{
			'type': 'CheckBox',
			'text': 'Send "Need help!" to team chat',
			'value': True,
			'tooltip': '{HEADER}Send "Need help!" to team chat{/HEADER}{BODY}When you get spotted, the mod automatically sends the "Need help!" command to your allies{/BODY}',
			'varName': 'neadHelp'
		},
		{
			'type': 'Dropdown',
			'text': 'Sixth Sense voice line',
			'tooltip': '{HEADER}Sixth Sense voice line{/HEADER}{BODY}When the Sixth Sense perk triggers, one of several voice lines is played.{/BODY}',
			'options':  [
				{ 'label': 'Standard' },
				{ 'label': 'Quiet' },
				{ 'label': 'Loud' }
			],
			'button': {
				'width': 30,
				'height': 23,
				'offsetTop': 0,
				'offsetLeft': 0,
				'iconSource': '../maps/icons/buttons/sound.png',
				'iconOffsetTop': 0,
				'iconOffsetLeft': 1,
			},
			'width': 200,
			'value': 0,
			'varName': 'sixthSenseSound'
		}
	],
		
	'column2': [
		{
			'type': 'Slider',
			'text': 'Number of alive allies required to activate the mod',
			'minimum': 1,
			'maximum': 15,
			'snapInterval': 1,
			'value': 5,
			'format': '{{value}}',
			'varName': 'aliveCounter'
		},
		{
			'type': 'StepSlider',
			'text': 'StepSlider example',
			'value': 0,
			'options':  [
				{ 'label': 'Standard' },
				{ 'label': 'Quiet' },
				{ 'label': 'Loud' }
			],
			'varName': 'stepSliderTest'
		},
		{
			'type': 'CheckBox',
			'text': 'Always warn about being spotted when playing artillery',
			'tooltip': '{HEADER}Always warn about being spotted when playing artillery{/HEADER}{BODY}If you enter a battle in an SPG, the mod always warns you about being spotted, regardless of the configured limit on the number of allies left alive{/BODY}',
			'value': True,
			'varName': 'alwaysOnArty'
		},
		{
			'type': 'HotKey',
			'text': 'Toggle on/off with a key',
			'tooltip': '{HEADER}Toggle on/off with a key{/HEADER}{BODY}Activates or deactivates the mod when the key / key combination is pressed{/BODY}',
			'value': [Keys.KEY_J],
			'varName': 'stateKeyset'
		},
		{
			'type': 'NumericStepper',
			'text': 'NumericStepper test',
			'tooltip': '{HEADER}NumericStepper tooltip header{/HEADER}{BODY}NumericStepper tooltip body{/BODY}',
			'minimum': 1,
			'maximum': 15,
			'snapInterval': 0.1,
			'value': 5,
			'varName': 'numStepperTest'
		},
		{
			'type': 'ColorChoice',
			'text': 'ColorChoice test',
			'tooltip': '{HEADER}ColorChoice tooltip header{/HEADER}{BODY}ColorChoice tooltip body{/BODY}',
			'value': "FFFFFF",
			'varName': 'colorChoice'
		},
		{
			'type': 'RangeSlider',
			'text': 'RangeSlider test',
			'divisionLabelPostfix': '',
			'divisionLabelStep': 50,
			'divisionStep': 50,
			'maximum': 100,
			'minimum': 0,
			'minRangeDistance': 10,
			'snapInterval': 1,
			'value': [20, 50],
			'varName': 'rangeSlider'
		},
	]
}

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
