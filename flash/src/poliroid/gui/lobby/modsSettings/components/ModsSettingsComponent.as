package poliroid.gui.lobby.modsSettings.components
{
	import flash.display.DisplayObject;
	import flash.display.Graphics;
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
	import net.wg.gui.components.controls.NumericStepper;
	import poliroid.gui.lobby.modsSettings.controls.ColorChoiceButton;
	import poliroid.gui.lobby.modsSettings.controls.HotkeyControl;
	import poliroid.gui.lobby.modsSettings.controls.StateSwitcher;
	import poliroid.gui.lobby.modsSettings.events.InteractiveEvent;
	import poliroid.gui.lobby.modsSettings.lang.STRINGS;
	import poliroid.gui.lobby.modsSettings.shared.ComponentsFactory;
	import poliroid.gui.lobby.modsSettings.shared.Constants;
	import poliroid.gui.lobby.modsSettings.shared.HoverBrightener;

	public class ModsSettingsComponent extends UIComponent
	{
		private static const HOTKEY_GAP_BEFORE_COL2:Number = 20;
		private static const SWITCHER_RIGHT_OFFSET:Number = 41;
		private static const GAP_BEFORE_SWITCHER:Number = 18;
		private static const RESET_SIZE:Number = 14;
		private static const RESET_STACK_GAP:Number = 8;
		private static const RESET_DIM_ALPHA:Number = 0.4;
		private static var _switcherWidthCache:Number = NaN;

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
		private var _resetButton:Sprite;
		private var _resetColor:uint = 0xCCCCCC;
		private var _resetting:Boolean = false;

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

		public function resetToValues(values:Object):void
		{
			if (values == null)
				return;

			_resetting = true;


			for (var i:int = 0; i < components.length; i++)
			{
				var entry:Object = components[i];

				if (!('varName' in entry.data) || entry.data.type == 'HotKey')
					continue;

				var vn:String = entry.data.varName;
				if (!values.hasOwnProperty(vn))
					continue;

				var co:Object = entry.componentObject;
				if (co != null && co['setValue'] is Function)
				{
					try { co['setValue'](values[vn]); }
					catch (err:Error) { DebugUtils.LOG_ERROR('[ModsSettings] reset setValue failed for var ' + vn); }
				}
			}

			_resetting = false;

			updateComponentsState();
			dispatchEvent(new InteractiveEvent(InteractiveEvent.SETTINGS_CHANGED, modLinkage));
			updateResetState();
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

			var rightmostLimit:Number = Constants.MOD_COMPONENT_WIDTH - SWITCHER_RIGHT_OFFSET - GAP_BEFORE_SWITCHER;

			if (column1)
			{
				var limitCol1:Number = (column2)
					? (Constants.MOD_COMPONENT_WIDTH / 2 - HOTKEY_GAP_BEFORE_COL2)
					: rightmostLimit;
				lastPos = createComponents(this, column1, Constants.MOD_PADDING_LEFT, paddingTop, limitCol1);
			}

			if (column2)
			{
				var lastPosTemp:Number = createComponents(this, column2, Constants.MOD_COMPONENT_WIDTH / 2, paddingTop, rightmostLimit);
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
			fieldSet.textField.htmlText = String(data.modDisplayName).replace(/<img[^>]*>/gi, "");
			fieldSet.textField.autoSize = TextFieldAutoSize.LEFT;
			fieldSet.width = Constants.MOD_COMPONENT_WIDTH;
			fieldSet.height = lastPos + Constants.MOD_PADDING_BOTTOM;
			fieldSet.textField.y = fieldSet.textField.y - 2;

			var textFormat:TextFormat = fieldSet.textField.getTextFormat();

			textFormat.bold = true;
			textFormat.size = 15;
			textFormat.leftMargin = 32;
			fieldSet.textField.setTextFormat(textFormat);

			addChildAt(fieldSet, 0);
			height = fieldSet.height;

			_fieldSet = fieldSet;
			_fullHeight = fieldSet.height;
			createCollapseArrow();
			createResetButton();

			_collapsedHeight = Constants.MOD_COLLAPSED_HEIGHT;
			if (_stateSwitcher != null && _stateSwitcher.height > 0)
				_collapsedHeight = Math.max(_collapsedHeight, _stateSwitcher.y * 2 + _stateSwitcher.height);

			updateComponentsState();
			updateResetState();

			addEventListener(InteractiveEvent.HEIGHT_CHANGED, handleChildHeightChanged);

			if (data.hasOwnProperty('collapsed') && data.collapsed)
				applyCollapsed(true);
		}

		private function handleComponentEvent(event:InteractiveEvent = null):void
		{
			if (_resetting)
				return;

			updateComponentsState();
			dispatchEvent(new InteractiveEvent(InteractiveEvent.SETTINGS_CHANGED, modLinkage));
			updateResetState();
		}

		private function handleChildHeightChanged(event:InteractiveEvent):void
		{
			if (event.target == this)
				return;
			event.stopImmediatePropagation();
			reflow();
		}

		private function createComponents(parentObj:UIComponent, column:Array, x:Number, y:Number, rightLimit:Number = NaN):Number
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

				component.x = ((componentConfig.hasOwnProperty('masterVarName') || componentConfig.hasOwnProperty('conditions')) && componentConfig.masterIndent != false) ? x + Constants.MOD_CHILD_INDENT : x;
				component.y = lastPos + Constants.COMPONENT_MARGIN_BOTTOM;

				applyControlRightLimit(component, rightLimit);

				lastPos = component.y + component.height;
				parentObj.addChild(component);
			}

			return lastPos;
		}

		private function createStateSwitcher():void
		{
			_stateSwitcher = App.utils.classFactory.getComponent('StateSwitcherUI', StateSwitcher);
			_stateSwitcher.selected = modEnabled;
			_stateSwitcher.x = Constants.MOD_COMPONENT_WIDTH - SWITCHER_RIGHT_OFFSET;
			_stateSwitcher.y = 16;
			addChild(_stateSwitcher);
			if (_stateSwitcher.width > 0)
				_switcherWidthCache = _stateSwitcher.width;
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
			var visChanged:Boolean = false;

			for (var i:Number = 0; i < components.length; i++)
			{
				var entry:Object = components[i];
				var component:MovieClip = MovieClip(entry.componentObject);
				var enabled:Boolean = isEntryEnabled(entry, {});

				if (entry.data.gateHides == true)
				{
					var newHidden:Boolean = !enabled;

					if ((entry.gateHidden == true) != newHidden)
					{
						entry.gateHidden = newHidden;
						visChanged = true;
					}

					component.alpha = 1;
					component.mouseEnabled = true;
					component.mouseChildren = true;
					component.tabChildren = true;
				}
				else
				{
					component.alpha = enabled ? 1 : 0.5;
					component.mouseEnabled = enabled;
					component.mouseChildren = enabled;
					component.tabChildren = enabled;
				}
			}

			if (visChanged)
			{
				applyVisibility();
				reflow();
			}
		}

		private function isEntryEnabled(entry:Object, visiting:Object):Boolean
		{
			if (entry == null)
				return true;

			if (!modEnabled)
				return false;

			var d:Object = entry.data;

			if (d.hasOwnProperty('conditions'))
				return checkConditions(d.conditions, d.hasOwnProperty('conditionsLogic') ? String(d.conditionsLogic) : "AND", visiting);

			if (!d.hasOwnProperty('masterVarName'))
				return true;

			return checkOneMaster(
				String(d.masterVarName),
				d.hasOwnProperty('masterValue'), d.masterValue,
				d.hasOwnProperty('condition') ? String(d.condition) : "==",
				visiting);
		}

		private function checkConditions(conditions:Object, logic:String, visiting:Object):Boolean
		{
			if (!(conditions is Array))
				return true;

			var arr:Array = conditions as Array;

			if (arr.length == 0)
				return true;

			var isOr:Boolean = (logic == "OR");

			for (var i:int = 0; i < arr.length; i++)
			{
				var c:Object = arr[i];

				if (c == null || !c.hasOwnProperty('masterVarName'))
					continue;

				var ok:Boolean = checkOneMaster(
					String(c.masterVarName),
					c.hasOwnProperty('masterValue'), c.masterValue,
					c.hasOwnProperty('condition') ? String(c.condition) : "==",
					cloneVisiting(visiting));

				if (isOr && ok)
					return true;

				if (!isOr && !ok)
					return false;
			}

			return !isOr;
		}

		private function checkOneMaster(masterVar:String, hasValue:Boolean, value:Object, condition:String, visiting:Object):Boolean
		{
			var ownOk:Boolean = hasValue ? masterValueMatches(masterVar, value, condition) : isMasterOn(masterVar);

			if (!ownOk)
				return false;

			var masterEntry:Object = _componentsByVar[masterVar];

			if (masterEntry == null)
				return true;

			if (visiting[masterVar])
				return true;
			visiting[masterVar] = true;

			var masterComp:MovieClip = MovieClip(masterEntry.componentObject);
			if (masterComp != null && !masterComp.visible)
				return false;

			return isEntryEnabled(masterEntry, visiting);
		}

		private function cloneVisiting(visiting:Object):Object
		{
			var copy:Object = {};
			for (var k:String in visiting)
				copy[k] = true;
			return copy;
		}

		private function isMasterOn(varName:String):Boolean
		{
			var entry:Object = _componentsByVar[varName];

			if (entry == null)
				return true;

			var returnValue:Object = entry.componentObject[Constants.COMPONENT_RETURN_VALUE_KEY];

			if (returnValue == null)
				return true;

			return Boolean(gateScalar(returnValue.value));
		}

		private function isCompound(v:*):Boolean
		{
			if (v == null || v is Boolean || v is Number || v is int || v is uint || v is String || v is Array)
				return false;

			return v.hasOwnProperty('enabled') && v.hasOwnProperty('color');
		}

		private function gateScalar(v:*):*
		{
			return isCompound(v) ? v.enabled : v;
		}

		private function getMasterValue(varName:String):Object
		{
			var entry:Object = _componentsByVar[varName];

			if (entry == null)
				return null;

			var returnValue:Object = entry.componentObject[Constants.COMPONENT_RETURN_VALUE_KEY];

			return returnValue == null ? null : gateScalar(returnValue.value);
		}

		private function masterValueMatches(varName:String, allowed:Object, condition:String):Boolean
		{
			var value:Object = getMasterValue(varName);
			var op:String = (condition == null || condition == "") ? "==" : condition;

			switch (op)
			{
				case "!=":
					return (allowed is Array) ? ((allowed as Array).indexOf(value) == -1) : (value != allowed);
				case ">":
					return Number(value) > Number(allowed);
				case ">=":
					return Number(value) >= Number(allowed);
				case "<":
					return Number(value) < Number(allowed);
				case "<=":
					return Number(value) <= Number(allowed);
				case "==":
				default:
					return (allowed is Array) ? ((allowed as Array).indexOf(value) != -1) : (value == allowed);
			}
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
				_arrowColor = _fieldSet.textField.textColor;
				_collapseArrow.x = _fieldSet.textField.x + 3;
				_collapseArrow.y = _fieldSet.textField.y + (_fieldSet.textField.height - Constants.MOD_COLLAPSE_ARROW_SIZE) / 2;

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

		private function createResetButton():void
		{
			_resetButton = new Sprite();
			_resetButton.buttonMode = true;
			_resetButton.useHandCursor = true;

			if (_stateSwitcher != null)
			{
				var sw:Number = (_stateSwitcher.width > 0) ? _stateSwitcher.width : RESET_SIZE;
				var sh:Number = (_stateSwitcher.height > 0) ? _stateSwitcher.height : RESET_SIZE;
				_resetButton.x = _stateSwitcher.x + (sw - RESET_SIZE) / 2;
				_resetButton.y = _stateSwitcher.y + sh + RESET_STACK_GAP;
			}
			else
			{
				var slotW:Number = isNaN(_switcherWidthCache) ? SWITCHER_RIGHT_OFFSET : _switcherWidthCache;
				_resetButton.x = (Constants.MOD_COMPONENT_WIDTH - SWITCHER_RIGHT_OFFSET) + (slotW - RESET_SIZE) / 2;
				_resetButton.y = 16;
			}

			if (_fieldSet != null)
				_resetColor = _fieldSet.textField.textColor;

			_resetButton.addEventListener(MouseEvent.CLICK, handleResetClick);
			_resetButton.addEventListener(MouseEvent.ROLL_OVER, onResetOver);
			_resetButton.addEventListener(MouseEvent.ROLL_OUT, onResetOut);

			addChild(_resetButton);

			drawResetIcon();
		}

		private function drawResetIcon():void
		{
			if (_resetButton == null)
				return;

			var g:Graphics = _resetButton.graphics;
			g.clear();

			g.beginFill(0, 0);
			g.drawRect(-3, -3, RESET_SIZE + 6, RESET_SIZE + 6);
			g.endFill();

			var cx:Number = RESET_SIZE / 2;
			var cy:Number = RESET_SIZE / 2;
			var r:Number = RESET_SIZE / 2 - 1.5;

			var startA:Number = -55 * Math.PI / 180;
			var endA:Number = 215 * Math.PI / 180;
			var steps:int = 28;
			g.lineStyle(1.5, _resetColor, 1, true);
			g.moveTo(cx + r * Math.cos(startA), cy + r * Math.sin(startA));
			for (var i:int = 1; i <= steps; i++)
			{
				var a:Number = startA + (endA - startA) * i / steps;
				g.lineTo(cx + r * Math.cos(a), cy + r * Math.sin(a));
			}
			g.lineStyle();

			var px:Number = cx + r * Math.cos(startA);
			var py:Number = cy + r * Math.sin(startA);
			var tx:Number = Math.sin(startA);
			var ty:Number = -Math.cos(startA);
			var nx:Number = Math.cos(startA);
			var ny:Number = Math.sin(startA);
			var head:Number = RESET_SIZE * 0.34;
			var halfBase:Number = head * 0.7;
			g.beginFill(_resetColor, 1);
			g.moveTo(px + tx * head, py + ty * head);
			g.lineTo(px + nx * halfBase, py + ny * halfBase);
			g.lineTo(px - nx * halfBase, py - ny * halfBase);
			g.endFill();
		}

		private function handleResetClick(event:MouseEvent):void
		{
			event.stopPropagation();
			dispatchEvent(new InteractiveEvent(InteractiveEvent.RESET_REQUESTED, modLinkage));
		}

		private function onResetOver(event:MouseEvent):void
		{
			if (_resetButton != null && modEnabled)
				_resetButton.alpha = 1.0;
			try { App.toolTipMgr.showComplex(STRINGS.BUTTON_RESET_TOOLTIP); } catch (err:Error) {}
		}

		private function onResetOut(event:MouseEvent):void
		{
			updateResetState();
			try { App.toolTipMgr.hide(); } catch (err:Error) {}
		}

		private function differsFromDefaults():Boolean
		{
			if (data == null || data.defaults == null)
				return true;

			var defaults:Object = data.defaults;
			var current:Object = getConfigData();


			for (var i:int = 0; i < components.length; i++)
			{
				var entry:Object = components[i];

				if (!('varName' in entry.data) || entry.data.type == 'HotKey')
					continue;

				var vn:String = entry.data.varName;
				if (!defaults.hasOwnProperty(vn) || !current.hasOwnProperty(vn))
					continue;
				if (!valuesEqual(current[vn], defaults[vn]))
					return true;
			}

			return false;
		}

		private function valuesEqual(a:*, b:*):Boolean
		{
			if (isCompound(a) && isCompound(b))
				return String(a.enabled) == String(b.enabled) && String(a.color) == String(b.color);

			if ((a is Number) != (b is Number))
				return int(a) == int(b);
			return String(a) == String(b);
		}

		private function updateResetState():void
		{
			if (_resetButton == null)
				return;
			_resetButton.visible = !_collapsed;
			_resetButton.mouseEnabled = modEnabled;
			_resetButton.buttonMode = modEnabled;
			_resetButton.useHandCursor = modEnabled;
			_resetButton.alpha = (modEnabled && differsFromDefaults()) ? 1.0 : RESET_DIM_ALPHA;
		}

		private function applyVisibility():void
		{
			for (var i:Number = 0; i < components.length; i++)
			{
				var entry:Object = components[i];
				MovieClip(entry.componentObject).visible = !_collapsed && !(entry.gateHidden == true);
			}
		}

		private function applyCollapsed(value:Boolean):void
		{
			_collapsed = value;

			updateResetState();

			applyVisibility();

			var h:Number = _collapsed ? _collapsedHeight : _fullHeight;

			if (_fieldSet != null)
			{
				_fieldSet.height = h;
				if (_fieldSet.bg != null)
					_fieldSet.bg.height = h;
			}

			height = h;

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

		public function get layoutHeight():Number
		{
			return _collapsed ? _collapsedHeight : _fullHeight;
		}

		public function revalidateHotkeys():void
		{
			for (var i:int = 0; i < components.length; i++)
			{
				var co:Object = components[i].componentObject;
				if (co != null && co['control'] is HotkeyControl)
					HotkeyControl(co['control']).relayout();
			}
		}

		private function applyControlRightLimit(component:DisplayObject, rightLimit:Number):void
		{
			if (isNaN(rightLimit) || component == null)
				return;
			var ctrl:Object = component['control'];
			if (ctrl is HotkeyControl)
			{
				HotkeyControl(ctrl).maxRightLocal = rightLimit - component.x - HotkeyControl(ctrl).x;
			}
			else if (ctrl is ColorChoiceButton || ctrl is NumericStepper)
			{
				var fixed:DisplayObject = DisplayObject(ctrl);
				var bnds:Rectangle = fixed.getBounds(fixed.parent);
				if (bnds.width > 0)
					fixed.x += (rightLimit - component.x) - bnds.right;
			}
		}

		private function reuseKey(cfg:Object):String
		{
			if (cfg == null)
				return null;
			var t:String = String(cfg.type);
			if ('varName' in cfg)
				return t + "|" + String(cfg.varName) + "|" + valStr(cfg.text) + "|" + valStr(cfg.value);
			if (t == 'Label')
				return "Label|" + valStr(cfg.text);
			return null;
		}

		private function valStr(v:*):String
		{
			if (isCompound(v))
				return String(v.enabled) + ":" + String(v.color);

			return (v == null) ? "" : String(v);
		}

		private function reconcileColumn(col:Array, colX:Number, rightLimit:Number, existing:Object, used:Object, newComps:Array, newByVar:Object):Boolean
		{
			var y:Number = Constants.MOD_PADDING_TOP;
			for (var i:int = 0; i < col.length; i++)
			{
				var cfg:Object = col[i];
				var key:String = reuseKey(cfg);
				var comp:DisplayObject;
				if (key != null && existing.hasOwnProperty(key) && !used.hasOwnProperty(key))
				{
					comp = DisplayObject(existing[key].componentObject);
					used[key] = true;
				}
				else
				{
					comp = getComponentByType(cfg);
					if (comp == null)
						return false;
					comp.addEventListener(InteractiveEvent.VALUE_CHANGED, handleComponentEvent);
				}
				comp.x = ((cfg.hasOwnProperty('masterVarName') || cfg.hasOwnProperty('conditions')) && cfg.masterIndent != false) ? colX + Constants.MOD_CHILD_INDENT : colX;
				comp.y = y + Constants.COMPONENT_MARGIN_BOTTOM;
				applyControlRightLimit(comp, rightLimit);
				if (comp.parent != this)
					addChild(comp);
				y = comp.y + comp.height;
				var entry:Object = {'componentObject': comp, 'data': cfg};
				newComps.push(entry);
				if ('varName' in cfg)
					newByVar[cfg.varName] = entry;
			}
			return true;
		}

		public function applyTemplate(newData:Object):Boolean
		{
			if (data == null || newData == null)
				return false;
			if (Boolean(newData.hasOwnProperty('enabled')) != Boolean(data.hasOwnProperty('enabled')))
				return false;
			if (String(newData.modDisplayName) != String(data.modDisplayName))
				return false;

			var existing:Object = {};
			var i:int, e:Object, key:String;
			for (i = 0; i < components.length; i++)
			{
				e = components[i];
				key = reuseKey(e.data);
				if (key != null && !existing.hasOwnProperty(key))
					existing[key] = e;
			}

			var used:Object = {};
			var newComps:Array = [];
			var newByVar:Object = {};

			var rightmost:Number = Constants.MOD_COMPONENT_WIDTH - SWITCHER_RIGHT_OFFSET - GAP_BEFORE_SWITCHER;
			var col2Exists:Boolean = (newData.column2 != null);

			if (newData.column1)
			{
				var limitCol1:Number = col2Exists
					? (Constants.MOD_COMPONENT_WIDTH / 2 - HOTKEY_GAP_BEFORE_COL2)
					: rightmost;
				if (!reconcileColumn(newData.column1 as Array, Constants.MOD_PADDING_LEFT, limitCol1, existing, used, newComps, newByVar))
					return false;
			}
			if (newData.column2)
			{
				if (!reconcileColumn(newData.column2 as Array, Constants.MOD_COMPONENT_WIDTH / 2, rightmost, existing, used, newComps, newByVar))
					return false;
			}

			for (i = 0; i < components.length; i++)
			{
				e = components[i];
				key = reuseKey(e.data);
				if (key == null || !used.hasOwnProperty(key))
				{
					var old:DisplayObject = DisplayObject(e.componentObject);
					old.removeEventListener(InteractiveEvent.VALUE_CHANGED, handleComponentEvent);
					if (old.parent == this)
						removeChild(old);
				}
			}

			components = newComps;
			_componentsByVar = newByVar;
			data = newData;

			updateComponentsState();
			reflow();
			return true;
		}

		private function getComponentByType(componentConfig:Object):DisplayObject
		{
			switch (componentConfig.type)
			{
				case 'Label':
					return ComponentsFactory.createLabel(componentConfig.text, componentConfig.tooltip, componentConfig.tooltipIcon, componentConfig.useHTML != false);
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
				case 'CheckBoxColor':
					return ComponentsFactory.createCheckboxColor(componentConfig, modLinkage, componentConfig.value, componentConfig.text, componentConfig.tooltip, componentConfig.tooltipIcon);
				case 'RangeSlider':
					return ComponentsFactory.createRangeSlider(componentConfig, modLinkage);
				case 'Image':
					return ComponentsFactory.createImage(componentConfig);
				default:
					DebugUtils.LOG_ERROR('[ModsSettings API] Unexpected type of component: ', componentConfig.type);
					return new MovieClip();
			}
		}

		private function reflow():void
		{
			var c1len:int = (data && data.column1) ? data.column1.length : 0;
			var pos1:Number = Constants.MOD_PADDING_TOP;
			var pos2:Number = Constants.MOD_PADDING_TOP;

			for (var i:int = 0; i < components.length; i++)
			{
				var comp:DisplayObject = DisplayObject(components[i].componentObject);

				if (components[i].gateHidden == true)
				{
					comp.scaleY = 0;
					comp.y = 0;
					continue;
				}

				comp.scaleY = 1;

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

		public function updateImageAtlas(varName:String, atlasSrc:String, frameW:int, frameH:int, cols:int, count:int, fps:Number, loop:Boolean, w:int, h:int):Boolean
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
						holder['imgW'] = w;
						holder['imgH'] = h;
						ComponentsFactory.playAtlasInto(holder, atlasSrc, frameW, frameH, cols, count, fps, loop);
						if (wasCollapsed)
							reflow();
						return true;
					}
				}
			}
			return false;
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
