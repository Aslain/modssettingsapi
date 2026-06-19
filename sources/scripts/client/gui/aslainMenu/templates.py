from ._constants import COMPONENT_TYPE, CONDITION


def createBase(type, text, tooltip=None, tooltipIcon=None, useHTML=True):
	""" Helper to create base component

	:param type: Component type, MUST be one of COMPONENT_TYPE
	:param text: Component text
	:param tooltip: Component tooltip, optional
	:param tooltipIcon: Component tooltip icon, optional
	
	:return: Base component
	"""
	base = {'type': type, 'text': text}
	if not useHTML:
		base['useHTML'] = False
	if tooltip is not None:
		base['tooltip'] = tooltip
	if tooltipIcon is not None:
		base['tooltipIcon'] = tooltipIcon
	return base


def createControl(type, text, varName, value, tooltip=None, tooltipIcon=None, button=None, useHTML=True):
	""" Helper to create control component

	:param type: Component type, MUST be one of COMPONENT_TYPE
	:param text: Component text
	:param varName: Variable name bound to this component that will store component's value in onModSettingsChanged callback
	:param value: Component value
	:param tooltip: Component tooltip, optional
	:param tooltipIcon: Component tooltip icon, optional
	:param button: Component button, optional
	:param useHTML: When False, the label renders as plain text (the API escapes
		<, > and & so they show verbatim) instead of HTML. Default True keeps HTML
		labels (icons, <font>, <b>).
	
	:return: Control component
	"""
	control = createBase(type, text, tooltip, tooltipIcon, useHTML)
	control.update({'varName': varName, 'value': value})
	if button is not None:
		control['button'] = button
	return control


def generateOptions(entries):
	""" Options generator for supported controls with tooltip generation support 
	
	:param entries: Option entries
	:type list-like of str, dict or list-like, i.e. (('label', 'tooltip', ), ('label', ), 'label', { 'label': 'label5' }, { 'label': 'label6', 'tooltip': 'tooltip' })

	:return: Options dictionary for supported AS3 components (dropdown and radio button group)
	"""
	options = []
	for entry in entries:
		label = ''
		tooltip = None
		if isinstance(entry, (list, tuple, set)):
			try:
				label, tooltip = entry
			except:
				label = entry[0]
		elif isinstance(entry, dict):
			label = entry.get('label', '')
			tooltip = entry.get('tooltip', None)
		else:
			label = entry
		option = {}
		option['label'] = label
		if tooltip is not None:
			option['tooltip'] = tooltip
		options.append(option)
	return options


def createOptionsControl(type, text, varName, options, value, tooltip=None, tooltipIcon=None, button=None, useHTML=True):
	""" Helper to create control with options component

	:param type: Component type, MUST be one of COMPONENT_TYPE
	:param text: Component text
	:param varName: Variable name bound to this component that will store component's value in onModSettingsChanged callback
	:param options: List of string value for component options
	:type options: list or tuple of str
	:param value: Component value
	:param tooltip: Component tooltip, optional
	:param tooltipIcon: Component tooltip icon, optional
	:param button: Component button, optional
	:param useHTML: When False, the label renders as plain text (the API escapes
		<, > and & so they show verbatim) instead of HTML. Default True keeps HTML
		labels (icons, <font>, <b>).
	
	:return: Control component with options
	"""
	control = createControl(type, text, varName, value, tooltip, tooltipIcon, button, useHTML)
	control['options'] = generateOptions(options)
	return control


def createStepper(type, text, varName, value, min, max, interval, tooltip=None, tooltipIcon=None, button=None, useHTML=True):
	""" Helper to create stepper component (Slider, NumericStepper and RangeSlider)

	:param type: Component type, MUST be one of COMPONENT_TYPE
	:param text: Component text
	:param varName: Variable name bound to this component that will store component's value in onModSettingsChanged callback
	:param value: Component value
	:param min: Minimum value of stepper component
	:type min: int
	:param max: Maximum value of stepper component
	:type max: int
	:param interval: Step interval value
	:type interval: int
	:param tooltip: Component tooltip, optional
	:param tooltipIcon: Component tooltip icon, optional
	:param button: Component button, optional
	:param useHTML: When False, the label renders as plain text (the API escapes
		<, > and & so they show verbatim) instead of HTML. Default True keeps HTML
		labels (icons, <font>, <b>).
	
	:return: Stepper component
	"""
	stepper = createControl(type, text, varName, value, tooltip, tooltipIcon, button, useHTML)
	stepper.update({'minimum': min, 'maximum': max, 'snapInterval': interval})
	return stepper


def createButton(width=None, height=None, text=None, offsetTop=None, offsetLeft=None,
				 icon=None, iconOffsetTop=None, iconOffsetLeft=None):
	""" Helper to create button for component
	
	:param width: Button width, optional
	:param height: Button height, optional
	:param text: Button text content, optional
	:param offsetTop: Button top offset relatively to component, optional
	:param offsetLeft: Button left offset relatively to component, optional
	:param icon: Path to icon location, optional
	:param iconOffsetTop: Icon top offset relatively to button, optional
	:param iconOffsetLeft: Icon left offset relatively to button, optional

	:return: Component button
	"""
	button = {}
	if width is not None:
		button['width'] = width
	if height is not None:
		button['height'] = height
	if text is not None:
		button['text'] = text
	if offsetTop is not None:
		button['offsetTop'] = offsetTop
	if offsetLeft is not None:
		button['offsetLeft'] = offsetLeft
	if icon is not None and text is None:
		button['iconSource'] = icon
	if iconOffsetTop is not None:
		button['iconOffsetTop'] = iconOffsetTop
	if iconOffsetLeft is not None:
		button['iconOffsetLeft'] = iconOffsetLeft
	return button


def createEmpty(height=None):
	""" Helper to create empty component
	
	:param height: Component height, useful for necessary margins, optional, default: 20px

	:return: Empty component
	"""
	component = {'type': 'Empty'}
	if height is not None and isinstance(height, int):
		component['height'] = height
	return component


def createLabel(text, tooltip=None, tooltipIcon=None, useHTML=True):
	""" Helper to create Label component

	:param text: Component text
	:param tooltip: Component tooltip, optional
	:param tooltipIcon: Component tooltip icon, optional
	:param useHTML: When False, the label renders as plain text (the API escapes
		<, > and & so they show verbatim) instead of HTML. Default True keeps HTML
		labels (icons, <font>, <b>).

	:return: Label component
	"""
	return createBase(COMPONENT_TYPE.LABEL, text, tooltip, tooltipIcon, useHTML)


def createImage(source, width=None, height=None, tooltip=None, tooltipIcon=None, varName=None,
				align=None, valign=None, containerWidth=None, containerHeight=None,
				collapsed=False, label=None, labelAlign=None, atlas=None, useHTML=True):
	""" Helper to create Image component (displays an image in the menu body)

	:param source: Image path readable by the game's image loader, e.g.
		'gui/maps/icons/...' or a path inside a mod's res, optionally with the
		'img://' prefix
	:param width: Image width in pixels, optional
	:param height: Image height in pixels, optional
	:param tooltip: Component tooltip, optional
	:param tooltipIcon: Component tooltip icon, optional
	:param varName: Optional identifier; required only for live updates via
		g_modsSettingsApi.updateImage()
	:param align: Horizontal alignment inside the box, 'left' (default), 'center'
		or 'right'
	:param valign: Vertical alignment inside the box, 'top' (default), 'center'
		or 'bottom'
	:param containerWidth: Width in px of the box the image is aligned within
		(defaults to the image width). Use it together with align.
	:param containerHeight: Height in px of the box the image is aligned within
		(defaults to the image height). A fixed containerHeight gives the
		component a fixed layout slot, so live updates that change the image
		size do not shift the components below it.
	:param collapsed: When True the image starts collapsed (a zero-height slot)
		instead of reserving the full container; call updateImage() with a path
		to expand it. Default False keeps the full reserved slot (current
		behaviour). Useful when the default state shows no image.
	:param label: Optional text label rendered above the image, inside the
		component - it collapses and expands together with the image (unlike a
		separate createLabel) and can be live-updated via updateImage(). Supports
		the same html markup as other menu labels (e.g. font color). Pass '' to
		reserve an empty label slot; None (default) = no label slot at all.
	:param labelAlign: 'left' (default), 'center' or 'right' - horizontal
		alignment of the label within the container box, independent of the
		image's own align.
	:param atlas: Optional dict to start the image already animating a sprite
		sheet at build time (plays the moment the menu opens). Keys: 'source'
		(the sheet image), 'frameWidth', 'frameHeight', 'columns' (cells per
		row), 'count' (total cells), 'fps', and optional 'loop' (default True;
		False plays once and holds the last frame). Pair with
		g_modsSettingsApi.updateImageAtlas() to switch the animation live.
		Default None keeps a static image from 'source'.
	:param useHTML: When False, the label renders as plain text (the API escapes
		<, > and & so they show verbatim) instead of HTML. Default True keeps HTML
		labels (icons, <font>, <b>).

	:return: Image component
	"""
	component = createBase(COMPONENT_TYPE.IMAGE, '', tooltip, tooltipIcon, useHTML)
	component['source'] = source
	if width is not None:
		component['width'] = width
	if height is not None:
		component['height'] = height
	if varName is not None:
		component['varName'] = varName
	if align is not None:
		component['align'] = align
	if valign is not None:
		component['valign'] = valign
	if containerWidth is not None:
		component['containerWidth'] = containerWidth
	if containerHeight is not None:
		component['containerHeight'] = containerHeight
	if collapsed:
		component['collapsed'] = True
	if label is not None:
		component['label'] = label
	if labelAlign is not None:
		component['labelAlign'] = labelAlign
	if atlas is not None:
		component['atlas'] = atlas
	return component


def createCheckbox(text, varName, value, tooltip=None, tooltipIcon=None, button=None, useHTML=True):
	""" Helper to create Checkbox component

	:param text: Component text
	:param varName: Variable name bound to this component that will store component's value in onModSettingsChanged callback
	:param value: Component value
	:type value: bool
	:param tooltip: Component tooltip, optional
	:param tooltipIcon: Component tooltip icon, optional
	:param button: Component button, optional
	:param useHTML: When False, the label renders as plain text (the API escapes
		<, > and & so they show verbatim) instead of HTML. Default True keeps HTML
		labels (icons, <font>, <b>).

	:return: Checkbox component
	"""
	return createControl(COMPONENT_TYPE.CHECKBOX, text, varName, value, tooltip, tooltipIcon, button, useHTML)


def createRadioButtonGroup(text, varName, options, value, tooltip=None, tooltipIcon=None, button=None, useHTML=True):
	""" Helper to create RadioButtonGroup component

	:param text: Component text
	:param varName: Variable name bound to this component that will store component's value in onModSettingsChanged callback
	:param value: Component value, index of options
	:type value: int
	:param tooltip: Component tooltip, optional
	:param tooltipIcon: Component tooltip icon, optional
	:param button: Component button, optional
	:param useHTML: When False, the label renders as plain text (the API escapes
		<, > and & so they show verbatim) instead of HTML. Default True keeps HTML
		labels (icons, <font>, <b>).

	:return: RadioButtonGroup component
	"""
	return createOptionsControl(COMPONENT_TYPE.RADIO_BUTTON_GROUP, text, varName, options, value, tooltip, tooltipIcon, button, useHTML)


def createDropdown(text, varName, options, value, tooltip=None, tooltipIcon=None, button=None, width=None, useHTML=True):
	""" Helper to create Dropdown component

	:param text: Component text
	:param varName: Variable name bound to this component that will store component's value in onModSettingsChanged callback
	:param options: List of string value for component options
	:type options: list or tuple of str
	:param value: Component value, index of options
	:type value: int
	:param tooltip: Component tooltip, optional
	:param tooltipIcon: Component tooltip icon, optional
	:param button: Component button, optional
	:param useHTML: When False, the label renders as plain text (the API escapes
		<, > and & so they show verbatim) instead of HTML. Default True keeps HTML
		labels (icons, <font>, <b>).
	:param width: Component width, optional

	:return: Dropdown component
	"""
	control = createOptionsControl(
		COMPONENT_TYPE.DROPDOWN, text, varName, options, value, tooltip, tooltipIcon, button, useHTML)
	if width is not None:
		control['width'] = width
	return control


def createSlider(text, varName, value, min, max, interval, format='{{value}}', tooltip=None, tooltipIcon=None, button=None, width=None, useHTML=True):
	""" Helper to create Slider component

	:param text: Component text
	:param varName: Variable name bound to this component that will store component's value in onModSettingsChanged callback
	:param value: Component value
	:type value: int
	:param min: Minimum value of stepper component
	:type min: int
	:param max: Maximum value of stepper component
	:type max: int
	:param interval: Step interval value
	:type interval: int
	:param format: Component value format template, defaults to '{{value}}' optional
	:param tooltip: Component tooltip, optional
	:param tooltipIcon: Component tooltip icon, optional
	:param button: Component button, optional
	:param useHTML: When False, the label renders as plain text (the API escapes
		<, > and & so they show verbatim) instead of HTML. Default True keeps HTML
		labels (icons, <font>, <b>).
	:param width: Component width, optional

	:return: Slider component
	"""
	stepper = createStepper(COMPONENT_TYPE.SLIDER, text,
							varName, value, min, max, interval, tooltip, tooltipIcon, button, useHTML)
	stepper['format'] = format
	if width is not None:
		stepper['width'] = width
	return stepper


def createStepSlider(text, varName, options, value, format='{{value}}', tooltip=None, tooltipIcon=None, button=None, width=None, useHTML=True):
	""" Helper to create StepSlider component

	:param text: Component text
	:param varName: Variable name bound to this component that will store component's value in onModSettingsChanged callback
	:param options: List of string value for component options
	:type options: list or tuple of str
	:param value: Component value
	:param format: Component value format template, defaults to '{{value}}' optional
	:param tooltip: Component tooltip, optional
	:param tooltipIcon: Component tooltip icon, optional
	:param button: Component button, optional
	:param useHTML: When False, the label renders as plain text (the API escapes
		<, > and & so they show verbatim) instead of HTML. Default True keeps HTML
		labels (icons, <font>, <b>).
	:param width: Component width, optional
	
	:return: StepSlider component
	"""
	stepper = createOptionsControl(COMPONENT_TYPE.STEP_SLIDER, text, 
								varName, options, value, tooltip, tooltipIcon, button, useHTML)
	stepper['format'] = format
	if width is not None:
		stepper['width'] = width
	return stepper


def createInput(text, varName, value, tooltip=None, tooltipIcon=None, button=None, width=None, useHTML=True):
	""" Helper to create Input component

	:param text: Component text
	:param varName: Variable name bound to this component that will store component's value in onModSettingsChanged callback
	:param value: Component value
	:type value: str
	:param tooltip: Component tooltip, optional
	:param tooltipIcon: Component tooltip icon, optional
	:param button: Component button, optional
	:param useHTML: When False, the label renders as plain text (the API escapes
		<, > and & so they show verbatim) instead of HTML. Default True keeps HTML
		labels (icons, <font>, <b>).
	:param width: Component width, optional

	:return: Input component
	"""
	control = createControl(COMPONENT_TYPE.TEXT_INPUT, text,
							varName, value, tooltip, tooltipIcon, button, useHTML)
	if width is not None:
		control['width'] = width
	return control


def createNumericStepper(text, varName, value, min, max, interval, tooltip=None, tooltipIcon=None, button=None, manual=False, useHTML=True):
	""" Helper to create NumericStepper component

	:param text: Component text
	:param varName: Variable name bound to this component that will store component's value in onModSettingsChanged callback
	:param value: Component value
	:type value: int
	:param min: Minimum value of stepper component
	:type min: int
	:param max: Maximum value of stepper component
	:type max: int
	:param interval: Step interval value
	:type interval: int
	:param tooltip: Component tooltip, optional
	:param tooltipIcon: Component tooltip icon, optional
	:param button: Component button, optional
	:param useHTML: When False, the label renders as plain text (the API escapes
		<, > and & so they show verbatim) instead of HTML. Default True keeps HTML
		labels (icons, <font>, <b>).
	:param manual: Defines if user can manually type value, optional

	:return: NumericStepper component
	"""
	stepper = createStepper(COMPONENT_TYPE.NUMERIC_STEPPER,
							text, varName, value, min, max, interval, tooltip, tooltipIcon, button, useHTML)
	stepper['canManualInput'] = manual
	return stepper


def createHotkey(text, varName, value, tooltip=None, tooltipIcon=None, button=None, float='none', useHTML=True):
	""" Helper to create Hotkey component

	:param text: Component text
	:param varName: Variable name bound to this component that will store component's value in onModSettingsChanged callback
	:param value: Component value
	:type value: list of BigWorld keys
	:param tooltip: Component tooltip, optional
	:param tooltipIcon: Component tooltip icon, optional
	:param button: Component button, optional
	:param useHTML: When False, the label renders as plain text (the API escapes
		<, > and & so they show verbatim) instead of HTML. Default True keeps HTML
		labels (icons, <font>, <b>).
	:param float: CSS-like float for the keys when the label is long. 'none' (default) keeps
		the label in the narrow column left of the keys. 'right' floats the keys to the right
		and wraps the label around them - narrow beside them on top, full row width underneath.
		Plain-text labels only; a label that contains HTML markup keeps the 'none' layout.

	:return: Hotkey component
	"""
	control = createControl(COMPONENT_TYPE.HOTKEY, text, varName, value, tooltip, tooltipIcon, button, useHTML)
	control['float'] = float
	return control


def createColorChoice(text, varName, value, tooltip=None, tooltipIcon=None, button=None, useHTML=True):
	""" Helper to create ColorChoice component

	:param text: Component text
	:param varName: Variable name bound to this component that will store component's value in onModSettingsChanged callback
	:param value: Component value
	:type value: str of hex color code with or without hash
	:param tooltip: Component tooltip, optional
	:param tooltipIcon: Component tooltip icon, optional
	:param button: Component button, optional
	:param useHTML: When False, the label renders as plain text (the API escapes
		<, > and & so they show verbatim) instead of HTML. Default True keeps HTML
		labels (icons, <font>, <b>).

	:return: ColorChoice component
	"""
	if value.startswith('#'):
		value = value.lstrip('#')
	return createControl(COMPONENT_TYPE.COLOR_CHOICE, text, varName, value, tooltip, tooltipIcon, button, useHTML)


def createRangeSlider(text, varName, value, min, max, interval, step, minRange, labelStep, labelPostfix, tooltip=None, tooltipIcon=None, button=None, useHTML=True):
	""" Helper to create RangeSlider component

	:param text: Component text
	:param varName: Variable name bound to this component that will store component's value in onModSettingsChanged callback
	:param value: Component value
	:type value: list[int, int]
	:param min: Minimum value of stepper component
	:type min: int
	:param max: Maximum value of stepper component
	:type max: int
	:param interval: Step interval value
	:type interval: int
	:param step: Step
	:param minRange: Minimal range of values
	:type minRange: int
	:param labelStep: Steps of component labels
	:type labelStep: int
	:param labelPostfix: Postfix of component labels
	:type labelPostfix: str
	:param tooltip: Component tooltip, optional
	:param tooltipIcon: Component tooltip icon, optional
	:param button: Component button, optional
	:param useHTML: When False, the label renders as plain text (the API escapes
		<, > and & so they show verbatim) instead of HTML. Default True keeps HTML
		labels (icons, <font>, <b>).

	:return: RangeSlider component
	"""
	stepper = createStepper(COMPONENT_TYPE.RANGE_SLIDER, text,
							varName, value, min, max, interval, tooltip, tooltipIcon, button, useHTML)
	stepper.update({
		'divisionStep': step,
		'minRangeDistance': minRange,
		'divisionLabelStep': labelStep,
		'divisionLabelPostfix': labelPostfix,
	})
	return stepper


def createControlsGroup(master, children, indent=True):
	""" Bind a group of sub-option components to a master control

	While the master control's (boolean) value is False, every child is shown
	greyed-out and disabled (not editable); children keep their stored values.
	Children are rendered indented under the master. The master is typically a
	Checkbox, the children any control type, including a RadioButtonGroup
	(single choice) or several Checkboxes (multiple choice).

	:param master: Master control component (e.g. createCheckbox(...)), must have a 'varName'
	:param children: List of sub-option components bound to the master
	:param indent: When False the children are not indented (kept at the master's x),
		handy to avoid crowding the second column. Defaults to True. Maps to the
		'masterIndent' key, which you can also set on a child by hand.

	:return: Flat list [master, child1, ...] ready to splice into a column

	Note: the binding is just a 'masterVarName' key (= master's varName) set on
	each child, so you can also set that key by hand instead of using this helper.
	"""
	masterVarName = master['varName']
	group = [master]
	for child in children:
		child['masterVarName'] = masterVarName
		if not indent:
			child['masterIndent'] = False
		group.append(child)
	return group


def enableWhen(control, masterVarName, value, indent=False, condition=CONDITION.EQUAL):
	""" Enable a control only while a master control's value satisfies a condition

	Where createControlsGroup greys its children while a *boolean* master is Off,
	this binds a control to a *condition* on any master's value - e.g. grey a slider
	unless a RadioButtonGroup / Dropdown sits on a given option, or unless a numeric
	master is >= some threshold. The control is enabled (editable, full opacity) when
	the condition holds and greyed-out / disabled otherwise. Ideal for mutually-
	exclusive controls (each branch gated on its own value). The grey-out updates live
	as the master changes.

	`condition` is a standard comparison applied as `masterValue <condition> value`:
	  '=='  master equals value (or is one of them when `value` is a list)  [default]
	  '!='  master differs from value (or is none of them when `value` is a list)
	  '>'  '>='  '<'  '<='   numeric comparison against a single `value`
	The default '==' is exactly the original behaviour, so existing calls are unchanged.
	The CONDITION constants are aliases for these strings, so you can write
	condition=CONDITION.GREATER_EQUAL instead of condition='>=' (EQUAL, NOT_EQUAL, GREATER,
	GREATER_EQUAL, LESS, LESS_EQUAL). Import it alongside templates: `from gui.aslainMenu
	import templates, CONDITION`.

	The control is treated as a sibling, not a sub-option, so by default it is NOT
	indented (pass indent=True to indent it like createControlsGroup does).

	Backward compatible: the binding is just plain keys ('masterVarName', 'masterValue',
	'masterIndent', 'condition') so they can also be set by hand, and a control without
	the binding is unaffected. On older API builds that predate this feature the keys are
	ignored and the control stays always-enabled, so feature-detect with
	hasattr(templates, 'enableWhen') and skip it when missing. Builds that have enableWhen
	but predate `condition` treat every binding as '=='.

	:param control: The control component to gate (e.g. createSlider(...))
	:param masterVarName: varName of the master control whose value gates this one
	:param value: Value compared against the master (a list is allowed for '==' / '!=')
	:param indent: Indent the control under the master like a sub-option (default False)
	:param condition: Comparison operator: '==' (default), '!=', '>', '>=', '<', '<='

	:return: The same control, so it can be used inline inside a column
	"""
	control['masterVarName'] = masterVarName
	control['masterValue'] = value
	control['masterIndent'] = indent
	control['condition'] = condition
	return control


def visibleWhen(control, masterVarName, value, indent=False, condition=CONDITION.EQUAL):
	""" Show a control only while a master control's value satisfies a condition

	Sibling of enableWhen with the same gating logic, but when the condition fails the
	control is HIDDEN and the mod reflows so the controls below close the gap, instead of
	being greyed out in place. Use it for options that make no sense in a given mode (e.g.
	a shape-specific field that only applies to one dropdown choice).

	Parameters are identical to enableWhen (masterVarName, value, indent, condition).

	Backward compatible: the binding is the same keys as enableWhen plus a 'gateHides'
	flag. On API builds that predate visibleWhen the flag is ignored, so the control
	degrades to enableWhen behaviour (greyed instead of hidden). Feature-detect with
	hasattr(templates, 'visibleWhen').

	:return: The same control, so it can be used inline inside a column
	"""
	control['masterVarName'] = masterVarName
	control['masterValue'] = value
	control['masterIndent'] = indent
	control['condition'] = condition
	control['gateHides'] = True
	return control


def enableWhenAll(control, conditions, indent=False):
	""" Enable a control only while ALL of several conditions match (logical AND)

	Where enableWhen gates on a single master, this gates on more than one - e.g. enabled
	only when A >= 0 AND B is True. `conditions` is a list of dicts, one per master:
	  {'varName': <master varName>, 'value': <compared value>, 'condition': <operator>}
	'condition' defaults to '==' (the CONDITION constants are the same aliases as
	enableWhen); omit 'value' to test that a boolean master is On. The control is enabled
	when every condition holds and greyed-out otherwise, updating live as any master
	changes.

	Backward compatible: the binding is a single 'conditions' key (plus 'conditionsLogic'
	and 'masterIndent'). On API builds that predate multi-conditions the keys are ignored
	and the control stays always-enabled, so feature-detect with
	hasattr(templates, 'enableWhenAll').

	:return: The same control, so it can be used inline inside a column
	"""
	return _setConditions(control, conditions, 'AND', False, indent)


def enableWhenAny(control, conditions, indent=False):
	""" Enable a control while ANY of several conditions match (logical OR)

	Same as enableWhenAll but the control is enabled when at least one condition holds.
	See enableWhenAll for the `conditions` format and backward-compatibility notes.

	:return: The same control, so it can be used inline inside a column
	"""
	return _setConditions(control, conditions, 'OR', False, indent)


def visibleWhenAll(control, conditions, indent=False):
	""" Show a control only while ALL conditions match (AND); hide + reflow otherwise

	Multi-condition sibling of visibleWhen: same as enableWhenAll but the control is
	hidden (and the mod reflows) when the AND of the conditions is false, instead of
	being greyed. See enableWhenAll for the `conditions` format and visibleWhen for the
	hide-vs-grey behaviour.

	:return: The same control, so it can be used inline inside a column
	"""
	return _setConditions(control, conditions, 'AND', True, indent)


def visibleWhenAny(control, conditions, indent=False):
	""" Show a control while ANY condition matches (OR); hide + reflow otherwise

	Multi-condition sibling of visibleWhen with OR logic. See enableWhenAll for the
	`conditions` format and visibleWhen for the hide-vs-grey behaviour.

	:return: The same control, so it can be used inline inside a column
	"""
	return _setConditions(control, conditions, 'OR', True, indent)


def _setConditions(control, conditions, logic, hide, indent):
	normalized = []
	for c in conditions:
		entry = {'masterVarName': c['varName'], 'condition': c.get('condition', CONDITION.EQUAL)}
		if 'value' in c:
			entry['masterValue'] = c['value']
		normalized.append(entry)
	control['conditions'] = normalized
	control['conditionsLogic'] = logic
	control['masterIndent'] = indent
	if hide:
		control['gateHides'] = True
	return control


def escape(text):
	"""Escape &, < and > so literal text renders verbatim in an HTML menu label.

	Labels render as HTML, so a literal '<' (and to be safe '>' and '&') in label text is
	parsed as markup and the rest of the label is lost (e.g. 'master <= 5' shows as just
	'master'). Wrap literal text: templates.createSlider(escape('master <= 5'), ...).
	"""
	return text.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
