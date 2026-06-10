from ._constants import COMPONENT_TYPE


def createBase(type, text, tooltip=None, tooltipIcon=None):
	""" Helper to create base component

	:param type: Component type, MUST be one of COMPONENT_TYPE
	:param text: Component text
	:param tooltip: Component tooltip, optional
	:param tooltipIcon: Component tooltip icon, optional
	
	:return: Base component
	"""
	base = {'type': type, 'text': text}
	if tooltip is not None:
		base['tooltip'] = tooltip
	if tooltipIcon is not None:
		base['tooltipIcon'] = tooltipIcon
	return base


def createControl(type, text, varName, value, tooltip=None, tooltipIcon=None, button=None):
	""" Helper to create control component

	:param type: Component type, MUST be one of COMPONENT_TYPE
	:param text: Component text
	:param varName: Variable name bound to this component that will store component's value in onModSettingsChanged callback
	:param value: Component value
	:param tooltip: Component tooltip, optional
	:param tooltipIcon: Component tooltip icon, optional
	:param button: Component button, optional
	
	:return: Control component
	"""
	control = createBase(type, text, tooltip, tooltipIcon)
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


def createOptionsControl(type, text, varName, options, value, tooltip=None, tooltipIcon=None, button=None):
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
	
	:return: Control component with options
	"""
	control = createControl(type, text, varName, value, tooltip, tooltipIcon, button)
	control['options'] = generateOptions(options)
	return control


def createStepper(type, text, varName, value, min, max, interval, tooltip=None, tooltipIcon=None, button=None):
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
	
	:return: Stepper component
	"""
	stepper = createControl(type, text, varName, value, tooltip, tooltipIcon, button)
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


def createLabel(text, tooltip=None, tooltipIcon=None):
	""" Helper to create Label component

	:param text: Component text
	:param tooltip: Component tooltip, optional
	:param tooltipIcon: Component tooltip icon, optional

	:return: Label component
	"""
	return createBase(COMPONENT_TYPE.LABEL, text, tooltip, tooltipIcon)


def createImage(source, width=None, height=None, tooltip=None, tooltipIcon=None, varName=None,
				align=None, valign=None, containerWidth=None, containerHeight=None,
				collapsed=False, label=None, labelAlign=None):
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

	:return: Image component
	"""
	component = createBase(COMPONENT_TYPE.IMAGE, '', tooltip, tooltipIcon)
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
	return component


def createCheckbox(text, varName, value, tooltip=None, tooltipIcon=None, button=None):
	""" Helper to create Checkbox component

	:param text: Component text
	:param varName: Variable name bound to this component that will store component's value in onModSettingsChanged callback
	:param value: Component value
	:type value: bool
	:param tooltip: Component tooltip, optional
	:param tooltipIcon: Component tooltip icon, optional
	:param button: Component button, optional

	:return: Checkbox component
	"""
	return createControl(COMPONENT_TYPE.CHECKBOX, text, varName, value, tooltip, tooltipIcon, button)


def createRadioButtonGroup(text, varName, options, value, tooltip=None, tooltipIcon=None, button=None):
	""" Helper to create RadioButtonGroup component

	:param text: Component text
	:param varName: Variable name bound to this component that will store component's value in onModSettingsChanged callback
	:param value: Component value, index of options
	:type value: int
	:param tooltip: Component tooltip, optional
	:param tooltipIcon: Component tooltip icon, optional
	:param button: Component button, optional

	:return: RadioButtonGroup component
	"""
	return createOptionsControl(COMPONENT_TYPE.RADIO_BUTTON_GROUP, text, varName, options, value, tooltip, tooltipIcon, button)


def createDropdown(text, varName, options, value, tooltip=None, tooltipIcon=None, button=None, width=None):
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
	:param width: Component width, optional

	:return: Dropdown component
	"""
	control = createOptionsControl(
		COMPONENT_TYPE.DROPDOWN, text, varName, options, value, tooltip, tooltipIcon, button)
	if width is not None:
		control['width'] = width
	return control


def createSlider(text, varName, value, min, max, interval, format='{{value}}', tooltip=None, tooltipIcon=None, button=None, width=None):
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
	:param width: Component width, optional

	:return: Slider component
	"""
	stepper = createStepper(COMPONENT_TYPE.SLIDER, text,
							varName, value, min, max, interval, tooltip, tooltipIcon, button)
	stepper['format'] = format
	if width is not None:
		stepper['width'] = width
	return stepper


def createStepSlider(text, varName, options, value, format='{{value}}', tooltip=None, tooltipIcon=None, button=None, width=None):
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
	:param width: Component width, optional
	
	:return: StepSlider component
	"""
	stepper = createOptionsControl(COMPONENT_TYPE.STEP_SLIDER, text, 
								varName, options, value, tooltip, tooltipIcon, button)
	stepper['format'] = format
	if width is not None:
		stepper['width'] = width
	return stepper


def createInput(text, varName, value, tooltip=None, tooltipIcon=None, button=None, width=None):
	""" Helper to create Input component

	:param text: Component text
	:param varName: Variable name bound to this component that will store component's value in onModSettingsChanged callback
	:param value: Component value
	:type value: str
	:param tooltip: Component tooltip, optional
	:param tooltipIcon: Component tooltip icon, optional
	:param button: Component button, optional
	:param width: Component width, optional

	:return: Input component
	"""
	control = createControl(COMPONENT_TYPE.TEXT_INPUT, text,
							varName, value, tooltip, tooltipIcon, button)
	if width is not None:
		control['width'] = width
	return control


def createNumericStepper(text, varName, value, min, max, interval, tooltip=None, tooltipIcon=None, button=None, manual=False):
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
	:param manual: Defines if user can manually type value, optional

	:return: NumericStepper component
	"""
	stepper = createStepper(COMPONENT_TYPE.NUMERIC_STEPPER,
							text, varName, value, min, max, interval, tooltip, tooltipIcon, button)
	stepper['canManualInput'] = manual
	return stepper


def createHotkey(text, varName, value, tooltip=None, tooltipIcon=None, button=None):
	""" Helper to create Hotkey component

	:param text: Component text
	:param varName: Variable name bound to this component that will store component's value in onModSettingsChanged callback
	:param value: Component value
	:type value: list of BigWorld keys
	:param tooltip: Component tooltip, optional
	:param tooltipIcon: Component tooltip icon, optional
	:param button: Component button, optional

	:return: Hotkey component
	"""
	return createControl(COMPONENT_TYPE.HOTKEY, text, varName, value, tooltip, tooltipIcon, button)


def createColorChoice(text, varName, value, tooltip=None, tooltipIcon=None, button=None):
	""" Helper to create Hotkey component

	:param text: Component text
	:param varName: Variable name bound to this component that will store component's value in onModSettingsChanged callback
	:param value: Component value
	:type value: str of hex color code with or without hash
	:param tooltip: Component tooltip, optional
	:param tooltipIcon: Component tooltip icon, optional
	:param button: Component button, optional

	:return: Hotkey component
	"""
	if value.startswith('#'):
		value = value.lstrip('#')
	return createControl(COMPONENT_TYPE.COLOR_CHOICE, text, varName, value, tooltip, tooltipIcon, button)


def createRangeSlider(text, varName, value, min, max, interval, step, minRange, labelStep, labelPostfix, tooltip=None, tooltipIcon=None, button=None):
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
	:param minRange: int
	:param labelStep: Steps of component labels
	:param labelStep: int
	:param labelPostfix: Postfix of component labels
	:param labelPostfix: str
	:param tooltip: Component tooltip, optional
	:param tooltipIcon: Component tooltip icon, optional
	:param button: Component button, optional

	:return: RangeSlider component
	"""
	stepper = createStepper(COMPONENT_TYPE.RANGE_SLIDER, text,
							varName, value, min, max, interval, tooltip, tooltipIcon, button)
	stepper.update({
		'divisionStep': step,
		'minRangeDistance': minRange,
		'divisionLabelStep': labelStep,
		'divisionLabelPostfix': labelPostfix,
	})
	return stepper


def createControlsGroup(master, children):
	""" Bind a group of sub-option components to a master control

	While the master control's (boolean) value is False, every child is shown
	greyed-out and disabled (not editable); children keep their stored values.
	Children are rendered indented under the master. The master is typically a
	Checkbox, the children any control type, including a RadioButtonGroup
	(single choice) or several Checkboxes (multiple choice).

	:param master: Master control component (e.g. createCheckbox(...)), must have a 'varName'
	:param children: List of sub-option components bound to the master

	:return: Flat list [master, child1, ...] ready to splice into a column

	Note: the binding is just a 'masterVarName' key (= master's varName) set on
	each child, so you can also set that key by hand instead of using this helper.
	"""
	masterVarName = master['varName']
	group = [master]
	for child in children:
		child['masterVarName'] = masterVarName
		group.append(child)
	return group


def enableWhen(control, masterVarName, value, indent=False):
	""" Enable a control only while a master control holds a given value

	Where createControlsGroup greys its children while a *boolean* master is Off,
	this binds a control to a *specific value* of any master - e.g. grey a slider
	unless a RadioButtonGroup / Dropdown sits on a given option. The control is
	enabled (editable, full opacity) when the master's current value equals
	`value` (or is one of them when `value` is a list), and greyed-out / disabled
	otherwise. Ideal for mutually-exclusive controls (each branch gated on its own
	value). The grey-out updates live as the master changes.

	The control is treated as a sibling, not a sub-option, so by default it is NOT
	indented (pass indent=True to indent it like createControlsGroup does).

	Backward compatible: the binding is just plain keys ('masterVarName',
	'masterValue', 'masterIndent') so they can also be set by hand, and a control
	without the binding is unaffected. On older API builds that predate this
	feature the keys are ignored and the control stays always-enabled, so
	feature-detect with hasattr(templates, 'enableWhen') and skip it when missing.

	:param control: The control component to gate (e.g. createSlider(...))
	:param masterVarName: varName of the master control whose value gates this one
	:param value: Master value (or list of values) that keeps this control enabled
	:param indent: Indent the control under the master like a sub-option (default False)

	:return: The same control, so it can be used inline inside a column
	"""
	control['masterVarName'] = masterVarName
	control['masterValue'] = value
	control['masterIndent'] = indent
	return control
