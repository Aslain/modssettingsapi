package poliroid.gui.lobby.modsSettings.components
{
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Rectangle;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import scaleform.clik.constants.InvalidationType;
	import scaleform.clik.core.UIComponent;
	import net.wg.gui.components.advanced.FieldSet;
	import poliroid.gui.lobby.modsSettings.controls.StateSwitcher;
	import poliroid.gui.lobby.modsSettings.events.InteractiveEvent;
	import poliroid.gui.lobby.modsSettings.shared.ComponentsFactory;
	import poliroid.gui.lobby.modsSettings.shared.Constants;
	import poliroid.gui.lobby.modsSettings.shared.HoverBrightener;

	public class ModsSettingsComponent extends UIComponent
	{
		public var modLinkage:String;
		public var modEnabled:Boolean = true;
		public var data:Object;
		public var components:Array;

		private var _stateSwitcher:StateSwitcher;
		private var _componentsByVar:Object;
		private var _fieldSet:FieldSet;
		private var _collapseArrow:Sprite;
		private var _collapsed:Boolean = false;
		private var _fullHeight:Number = 0;
		private var _collapsedHeight:Number = 52;
		private var _arrowColor:uint = 0xCCCCCC;
		private var _arrowHovered:Boolean = false;
		private var _nameHovered:Boolean = false;
		private var _arrowBright:HoverBrightener;
		private var _nameBright:HoverBrightener;

		public function ModsSettingsComponent(linkage:String)
		{
			super();

			modLinkage = linkage;
			components = new Array();
			_componentsByVar = new Object();
		}

		public function setData(newData:Object):void
		{
			if (newData != null)
			{
				data = newData;
				invalidate(InvalidationType.DATA);
			}
		}

		public function getConfigData():Object
		{
			var result:Object = new Object();

			for (var i:Number = 0; i < components.length; i++)
			{
				var component:Object = components[i];

				if ('varName' in component.data && component.componentObject[Constants.COMPONENT_RETURN_VALUE_KEY] != null)
					result[component.data.varName] = component.componentObject[Constants.COMPONENT_RETURN_VALUE_KEY].value;
			}

			if (data.hasOwnProperty('enabled'))
				result['enabled'] = modEnabled;

			return result;
		}

		override protected function draw():void
		{
			if (isInvalid(InvalidationType.DATA))
				setup();
		}

		private function setup():void
		{
			if (!data)
				return;

			var column1:Array = data.column1;
			var column2:Array = data.column2;
			var paddingTop:Number = Constants.MOD_PADDING_TOP;
			var lastPos:Number = 0;

			if (column1)
				lastPos = createComponents(this, column1, Constants.MOD_PADDING_LEFT, paddingTop);

			if (column2)
			{
				var lastPosTemp:Number = createComponents(this, column2, Constants.MOD_COMPONENT_WIDTH / 2, paddingTop);
				if (lastPosTemp > lastPos)
					lastPos = lastPosTemp;
			}

			if (data.hasOwnProperty('enabled'))
			{
				modEnabled = data.enabled;
				createStateSwitcher();
			}

			var fieldSet:FieldSet = FieldSet(App.utils.classFactory.getObject('FieldSet'));

			fieldSet.textField.condenseWhite = false;
			fieldSet.textField.htmlText = Constants.MOD_TITLE_INDENT + String(data.modDisplayName).replace(/<img[^>]*>/gi, "");
			fieldSet.textField.autoSize = TextFieldAutoSize.LEFT;
			fieldSet.width = Constants.MOD_COMPONENT_WIDTH;
			fieldSet.height = lastPos + Constants.MOD_PADDING_BOTTOM;
			fieldSet.textField.y = fieldSet.textField.y - 2;

			var textFormat:TextFormat = fieldSet.textField.getTextFormat();

			textFormat.bold = true;
			textFormat.size = 15;
			fieldSet.textField.setTextFormat(textFormat);

			addChildAt(fieldSet, 0);
			height = fieldSet.height;

			_fieldSet = fieldSet;
			_fullHeight = fieldSet.height;
			createCollapseArrow();

			// Collapsed height keeps a symmetric margin around the on/off switcher
			// (top margin == bottom margin) so the green button doesn't touch the border
			_collapsedHeight = Constants.MOD_COLLAPSED_HEIGHT;
			if (_stateSwitcher != null && _stateSwitcher.height > 0)
				_collapsedHeight = Math.max(_collapsedHeight, _stateSwitcher.y * 2 + _stateSwitcher.height);

			updateComponentsState();

			if (data.hasOwnProperty('collapsed') && data.collapsed)
				applyCollapsed(true);
		}

		private function handleComponentEvent(event:InteractiveEvent = null):void
		{
			updateComponentsState();
			dispatchEvent(new InteractiveEvent(InteractiveEvent.SETTINGS_CHANGED, modLinkage));
		}

		private function createComponents(parentObj:UIComponent, column:Array, x:Number, y:Number):Number
		{
			var lastPos:Number = y;

			for (var i:Number = 0; i < column.length; i++)
			{
				var componentConfig:Object = column[i];
				var component:DisplayObject = getComponentByType(componentConfig);

				component.addEventListener(InteractiveEvent.VALUE_CHANGED, handleComponentEvent);

				var entry:Object = {'componentObject': component, 'data': componentConfig};
				components.push(entry);

				if ('varName' in componentConfig)
					_componentsByVar[componentConfig.varName] = entry;

				component.x = (componentConfig.hasOwnProperty('masterVarName') && componentConfig.masterIndent != false) ? x + Constants.MOD_CHILD_INDENT : x;
				component.y = lastPos + Constants.COMPONENT_MARGIN_BOTTOM;
				lastPos = component.y + component.height;
				parentObj.addChild(component);
			}

			return lastPos;
		}

		private function createStateSwitcher():void
		{
			_stateSwitcher = App.utils.classFactory.getComponent('StateSwitcherUI', StateSwitcher);
			_stateSwitcher.selected = modEnabled;
			_stateSwitcher.x = Constants.MOD_COMPONENT_WIDTH - 41;
			_stateSwitcher.y = 16;
			addChild(_stateSwitcher);
			_stateSwitcher.addEventListener(Event.SELECT, handleStateSwitcherClick);
		}

		private function handleStateSwitcherClick(event:Event):void
		{
			App.utils.focusHandler.setFocus(this);

			var switcher:StateSwitcher = StateSwitcher(event.target);
			modEnabled = switcher.selected;

			handleComponentEvent();
			updateComponentsState();
		}

		private function updateComponentsState():void
		{
			for (var i:Number = 0; i < components.length; i++)
			{
				var entry:Object = components[i];
				var component:MovieClip = MovieClip(entry.componentObject);
				var enabled:Boolean = modEnabled;

				if (enabled && entry.data.hasOwnProperty('masterVarName'))
					enabled = entry.data.hasOwnProperty('masterValue') ? masterValueMatches(String(entry.data.masterVarName), entry.data.masterValue) : isMasterOn(String(entry.data.masterVarName));

				component.alpha = enabled ? 1 : 0.5;
				component.mouseEnabled = enabled;
				component.mouseChildren = enabled;
				component.tabChildren = enabled;
			}
		}

		private function isMasterOn(varName:String):Boolean
		{
			var entry:Object = _componentsByVar[varName];

			if (entry == null)
				return true;

			var returnValue:Object = entry.componentObject[Constants.COMPONENT_RETURN_VALUE_KEY];

			if (returnValue == null)
				return true;

			return Boolean(returnValue.value);
		}

		private function getMasterValue(varName:String):Object
		{
			var entry:Object = _componentsByVar[varName];

			if (entry == null)
				return null;

			var returnValue:Object = entry.componentObject[Constants.COMPONENT_RETURN_VALUE_KEY];

			return returnValue == null ? null : returnValue.value;
		}

		private function masterValueMatches(varName:String, allowed:Object):Boolean
		{
			var value:Object = getMasterValue(varName);

			if (allowed is Array)
				return (allowed as Array).indexOf(value) != -1;

			return value == allowed;
		}

		private function createCollapseArrow():void
		{
			_collapseArrow = new Sprite();
			_collapseArrow.buttonMode = true;
			_collapseArrow.useHandCursor = true;
			_collapseArrow.addEventListener(MouseEvent.CLICK, handleCollapseClick);
			_collapseArrow.addEventListener(MouseEvent.ROLL_OVER, onArrowOver);
			_collapseArrow.addEventListener(MouseEvent.ROLL_OUT, onArrowOut);
			addChild(_collapseArrow);
			_arrowBright = new HoverBrightener(_collapseArrow, Constants.HOVER_BRIGHTEN);

			if (_fieldSet != null)
			{
				// Inherit the mod title's text colour so the arrow matches the menu text
				_arrowColor = _fieldSet.textField.textColor;
				_collapseArrow.x = _fieldSet.textField.x + 3;
				_collapseArrow.y = _fieldSet.textField.y + (_fieldSet.textField.height - Constants.MOD_COLLAPSE_ARROW_SIZE) / 2;

				// Make the mod name itself toggle collapse (in addition to the arrow)
				_fieldSet.textField.selectable = false;
				_fieldSet.textField.mouseEnabled = true;
				_fieldSet.textField.addEventListener(MouseEvent.CLICK, handleCollapseClick);
				_fieldSet.textField.addEventListener(MouseEvent.ROLL_OVER, onNameOver);
				_fieldSet.textField.addEventListener(MouseEvent.ROLL_OUT, onNameOut);
				_nameBright = new HoverBrightener(_fieldSet.textField, Constants.HOVER_BRIGHTEN);
			}

			drawCollapseArrow();
		}

		private function drawCollapseArrow():void
		{
			if (_collapseArrow == null)
				return;

			var s:Number = Constants.MOD_COLLAPSE_ARROW_SIZE;

			_collapseArrow.graphics.clear();
			_collapseArrow.graphics.beginFill(0, 0);
			_collapseArrow.graphics.drawRect(-4, -4, s + 8, s + 8);
			_collapseArrow.graphics.endFill();
			_collapseArrow.graphics.beginFill(_arrowColor, 1);

			if (_collapsed)
			{
				_collapseArrow.graphics.moveTo(0, 0);
				_collapseArrow.graphics.lineTo(0, s);
				_collapseArrow.graphics.lineTo(s * 0.85, s / 2);
			}
			else
			{
				_collapseArrow.graphics.moveTo(0, 0);
				_collapseArrow.graphics.lineTo(s, 0);
				_collapseArrow.graphics.lineTo(s / 2, s * 0.85);
			}

			_collapseArrow.graphics.endFill();
		}

		private function onArrowOver(event:MouseEvent):void
		{
			_arrowHovered = true;
			refreshHeaderHighlight();
		}

		private function onArrowOut(event:MouseEvent):void
		{
			_arrowHovered = false;
			refreshHeaderHighlight();
		}

		private function onNameOver(event:MouseEvent):void
		{
			_nameHovered = true;
			refreshHeaderHighlight();
		}

		private function onNameOut(event:MouseEvent):void
		{
			_nameHovered = false;
			refreshHeaderHighlight();
		}

		private function refreshHeaderHighlight():void
		{
			var on:Boolean = _arrowHovered || _nameHovered;
			if (_arrowBright != null)
				_arrowBright.on = on;
			if (_nameBright != null)
				_nameBright.on = on;
		}

		private function handleCollapseClick(event:MouseEvent):void
		{
			applyCollapsed(!_collapsed);
			dispatchEvent(new InteractiveEvent(InteractiveEvent.COLLAPSE_CHANGED, modLinkage, '', _collapsed));
		}

		private function applyCollapsed(value:Boolean):void
		{
			_collapsed = value;

			for (var i:Number = 0; i < components.length; i++)
				MovieClip(components[i].componentObject).visible = !_collapsed;

			var h:Number = _collapsed ? _collapsedHeight : _fullHeight;

			if (_fieldSet != null)
			{
				_fieldSet.height = h;
				// FieldSet.draw() does not resize its background box, so resize the
				// 9-slice bg sprite directly to keep the border wrapping the content
				if (_fieldSet.bg != null)
					_fieldSet.bg.height = h;
			}

			height = h;

			// Clip a collapsed mod to its header height so its hidden controls don't
			// inflate the scroll content bounds (which would leave an empty scroll gap)
			if (_collapsed)
				scrollRect = new Rectangle(0, 0, Constants.MOD_COMPONENT_WIDTH, h);
			else
				scrollRect = null;

			drawCollapseArrow();
		}

		public function setCollapsed(value:Boolean):void
		{
			applyCollapsed(value);
		}

		public function get isCollapsed():Boolean
		{
			return _collapsed;
		}

		private function getComponentByType(componentConfig:Object):DisplayObject
		{
			switch (componentConfig.type)
			{
				case 'Label':
					return ComponentsFactory.createLabel(componentConfig.text, componentConfig.tooltip, componentConfig.tooltipIcon);
				case 'Empty':
					return ComponentsFactory.createEmpty(400, componentConfig.height);
				case 'CheckBox':
					return ComponentsFactory.createCheckBox(componentConfig, modLinkage, componentConfig.text, componentConfig.value, componentConfig.tooltip, componentConfig.tooltipIcon);
				case 'RadioButtonGroup':
					return ComponentsFactory.createRadioButtonGroup(componentConfig, modLinkage, componentConfig.varName, componentConfig.options, componentConfig.text, componentConfig.tooltip, componentConfig.tooltipIcon, componentConfig.value);
				case 'Slider':
					return ComponentsFactory.createSlider(componentConfig, modLinkage, componentConfig.minimum, componentConfig.maximum, componentConfig.snapInterval, componentConfig.value, componentConfig.format, componentConfig.text, componentConfig.tooltip, componentConfig.tooltipIcon);
				case 'StepSlider':
					return ComponentsFactory.createStepSlider(componentConfig, modLinkage, componentConfig.options, componentConfig.format, componentConfig.text, componentConfig.tooltip, componentConfig.tooltipIcon, componentConfig.value);
				case 'Dropdown':
					return ComponentsFactory.createDropdown(componentConfig, modLinkage, componentConfig.options, componentConfig.text, componentConfig.tooltip, componentConfig.tooltipIcon, componentConfig.value);
				case 'TextInput':
					return ComponentsFactory.createTextInput(componentConfig, componentConfig.text, componentConfig.tooltip, componentConfig.tooltipIcon, componentConfig.value);
				case 'HotKey':
					return ComponentsFactory.createHotKey(componentConfig, modLinkage, componentConfig.value, componentConfig.text, componentConfig.tooltip, componentConfig.tooltipIcon);
				case 'NumericStepper':
					return ComponentsFactory.createNumericStepper(componentConfig, modLinkage, componentConfig.minimum, componentConfig.maximum, componentConfig.snapInterval, componentConfig.value, componentConfig.text, componentConfig.tooltip, componentConfig.tooltipIcon);
				case 'ColorChoice':
					return ComponentsFactory.createColorChoice(componentConfig, modLinkage, componentConfig.value, componentConfig.text, componentConfig.tooltip, componentConfig.tooltipIcon);
				case 'RangeSlider':
					return ComponentsFactory.createRangeSlider(componentConfig, modLinkage);
				case 'Image':
					return ComponentsFactory.createImage(componentConfig);
				default:
					DebugUtils.LOG_ERROR('[ModsSettings API] Unexpected type of component: ', componentConfig.type);
					return new MovieClip();
			}
		}

		// Re-stack both columns by their current heights and recompute the mod height, then ask the
		// window to reflow the list. Used after an Image collapses/expands (removeImage) so the
		// controls below it - and the mods below this one - move up to fit.
		private function reflow():void
		{
			var c1len:int = (data && data.column1) ? data.column1.length : 0;
			var pos1:Number = Constants.MOD_PADDING_TOP;
			var pos2:Number = Constants.MOD_PADDING_TOP;

			for (var i:int = 0; i < components.length; i++)
			{
				var comp:DisplayObject = DisplayObject(components[i].componentObject);

				if (i < c1len)
				{
					comp.y = pos1 + Constants.COMPONENT_MARGIN_BOTTOM;
					pos1 = comp.y + comp.height;
				}
				else
				{
					comp.y = pos2 + Constants.COMPONENT_MARGIN_BOTTOM;
					pos2 = comp.y + comp.height;
				}
			}

			_fullHeight = Math.max(pos1, pos2) + Constants.MOD_PADDING_BOTTOM;

			var h:Number = _collapsed ? _collapsedHeight : _fullHeight;

			if (_fieldSet != null)
			{
				_fieldSet.height = h;
				if (_fieldSet.bg != null)
					_fieldSet.bg.height = h;
			}

			height = h;

			dispatchEvent(new InteractiveEvent(InteractiveEvent.HEIGHT_CHANGED, modLinkage));
		}

		public function updateImage(varName:String, source:String, w:int, h:int, removeImage:Boolean = false, label:String = null):Boolean
		{
			for (var i:Number = 0; i < components.length; i++)
			{
				var component:Object = components[i];

				if (component.data.hasOwnProperty('varName') && component.data.varName == varName && component.data.type == 'Image')
				{
					var holder:MovieClip = component.componentObject as MovieClip;

					if (holder != null)
					{
						var wasCollapsed:Boolean = holder['collapsed'] == true;

						if (label != null)
							ComponentsFactory.setImageLabel(holder, label);
						if (removeImage)
						{
							ComponentsFactory.collapseImage(holder);
							if (!wasCollapsed)
								reflow();
						}
						else
						{
							holder['imgW'] = w;
							holder['imgH'] = h;
							ComponentsFactory.loadImageInto(holder, source);
							if (wasCollapsed)
								reflow();
						}
						return true;
					}
				}
			}
			return false;
		}
	}
}
