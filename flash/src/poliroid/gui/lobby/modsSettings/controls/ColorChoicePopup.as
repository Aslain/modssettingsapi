package poliroid.gui.lobby.modsSettings.controls
{
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.ui.Keyboard;
	import scaleform.clik.constants.InvalidationType;
	import scaleform.clik.events.ButtonEvent;
	import scaleform.clik.events.SliderEvent;
	import scaleform.clik.events.InputEvent;
	import net.wg.gui.components.assets.GlowArrowAsset;
	import net.wg.gui.components.controls.Slider;
	import net.wg.gui.components.controls.TextInput;
	import net.wg.gui.components.controls.SoundButton;
	import net.wg.gui.components.popovers.PopOverConst;
	import net.wg.infrastructure.base.UIComponentEx;
	import poliroid.gui.lobby.modsSettings.lang.STRINGS;
	import poliroid.gui.lobby.modsSettings.shared.Constants;
	import poliroid.gui.lobby.modsSettings.shared.HoverBrightener;

	public class ColorChoicePopup extends UIComponentEx
	{
		private static const MAX_MOD_PRESETS:int = 24;
		private static const SLOTS_PER_ROW:int = 12;
		private static const USER_ROWS_MAX:int = 4;
		private static const SWATCH_SIZE:int = 18;
		private static const SWATCH_GAP:int = 4;
		private static const SWATCH_ROW_H:int = 22;
		private static const SWATCH_PAD:int = 6;
		private static const COMPACT_BTN_H:int = 24;
		private static const COMPACT_MIN_W:int = 134;
		private static const COMPACT_SIDE_PAD:int = 10;
		private static const EDIT_COLOR:uint = 0xFFC363;

		private static var _userPresets:Array = null;
		private static var _saveHandler:Function = null;
		private static var _activeInstance:ColorChoicePopup = null;

		public static function setUserPresets(data:Array):void
		{
			if (data == null)
			{
				_userPresets = null;
				return;
			}

			_userPresets = [];

			var total:int = SLOTS_PER_ROW * USER_ROWS_MAX;

			for (var i:int = 0; i < total; i++)
			{
				var entry:String = (i < data.length && data[i] != null) ? String(data[i]).split('#').join('').toLowerCase() : null;

				_userPresets.push((entry != null && /^[0-9a-f]{6}$/.test(entry)) ? entry : null);
			}

			if (_activeInstance != null)
				_activeInstance.updateSwatchSelection();
		}

		public static function set saveHandler(callback:Function):void
		{
			_saveHandler = callback;
		}

		public static function userPresetAction(action:String, slot:int):void
		{
			if (_activeInstance != null)
				_activeInstance.handlePresetAction(action, slot);
		}

		public var hitAreaA:MovieClip;
		public var background:MovieClip;
		public var arrowTop:GlowArrowAsset;
		public var arrowBottom:GlowArrowAsset;
		public var colorLabel:TextField;
		public var redSlider:Slider;
		public var greenSlider:Slider;
		public var blueSlider:Slider;
		public var hexTextInput:TextInput;
		public var colorSpectrum:MovieClip;
		public var colorPreview:MovieClip;
		public var acceptButton:SoundButton;

		private var _onValueChanged:Function;
		private var _color:String;
		private var _position:Point;
		private var _spectrumData:BitmapData;
		private var _presets:Array = null;
		private var _presetsOnly:Boolean = false;
		private var _presetsSized:Boolean = false;
		private var _uiConfigured:Boolean = false;
		private var _swatches:Array = [];
		private var _swatchBright:Array = [];
		private var _userSwatches:Array = [];
		private var _userBright:Array = [];
		private var _editSlot:int = -1;
		private var _editTouched:Boolean = false;
		private var _menuOpen:Boolean = false;

		public function ColorChoicePopup()
		{
			super();
		}

		override protected function configUI():void
		{
			super.configUI();

			_spectrumData = new BitmapData(colorSpectrum.width, colorSpectrum.height);
			_spectrumData.draw(colorSpectrum);

			colorSpectrum.buttonMode = true;

			arrowTop.buttonMode = false;
			arrowTop.mouseChildren = false;
			arrowTop.mouseEnabled = false;
			arrowBottom.buttonMode = false;
			arrowBottom.mouseChildren = false;
			arrowBottom.mouseEnabled = false;

			background.buttonMode = false;
			background.mouseChildren = false;
			background.mouseEnabled = false;
			background.width = hitAreaA.width + 120;
			background.height = hitAreaA.height + 120;

			hexTextInput.maxChars = 7;
			hexTextInput.textField.restrict = "#A-F0-9";

			colorLabel.text = STRINGS.POPUP_COLOR;
			acceptButton.label = STRINGS.BUTTON_APPLY;

			App.gameInputMgr.setKeyHandler(Keyboard.ESCAPE, KeyboardEvent.KEY_DOWN, _handleEscKey, true);
			App.gameInputMgr.setKeyHandler(Keyboard.DELETE, KeyboardEvent.KEY_DOWN, _handleDeleteKey, true);
			App.stage.addEventListener(MouseEvent.MOUSE_DOWN, onAppMouseHandler);
			App.stage.addEventListener(MouseEvent.MOUSE_WHEEL, onAppMouseHandler);
			App.stage.addEventListener(Event.RESIZE, handleClose);

			redSlider.addEventListener(SliderEvent.VALUE_CHANGE, handleSlider);
			greenSlider.addEventListener(SliderEvent.VALUE_CHANGE, handleSlider);
			blueSlider.addEventListener(SliderEvent.VALUE_CHANGE, handleSlider);
			acceptButton.addEventListener(ButtonEvent.PRESS, handleAccept);
			hexTextInput.addEventListener(InputEvent.INPUT, handleTextInput);
			colorSpectrum.addEventListener(MouseEvent.CLICK, handleSpectrumClick);
			colorSpectrum.addEventListener(MouseEvent.MOUSE_MOVE, handleSpectrumMove);
			colorSpectrum.addEventListener(MouseEvent.ROLL_OUT, handleSpectrumRollOut);

			arrowBottom.y = hitAreaA.height + 4;

			if (isCompact())
				applyCompactLayout();

			_uiConfigured = true;
			_activeInstance = this;
			buildSwatches();
		}

		private function isCompact():Boolean
		{
			return _presetsOnly && _presets != null;
		}

		private function applyCompactLayout():void
		{
			for (var i:int = 0; i < numChildren; i++)
			{
				var child:DisplayObject = getChildAt(i);

				if (child == background || child == hitAreaA || child == arrowTop || child == arrowBottom || child == acceptButton)
					continue;

				child.visible = false;
			}

			acceptButton.y = SWATCH_PAD + swatchRowCount() * SWATCH_ROW_H + 6;
			acceptButton.x = (hitAreaA.width - acceptButton.width) / 2;

			arrowTop.x = (hitAreaA.width - arrowTop.width) / 2;
			arrowBottom.x = (hitAreaA.width - arrowBottom.width) / 2;
		}

		override protected function onDispose():void
		{
			saveUserPresets();

			if (_activeInstance == this)
				_activeInstance = null;

			App.gameInputMgr.clearKeyHandler(Keyboard.ESCAPE, KeyboardEvent.KEY_DOWN, _handleEscKey);
			App.gameInputMgr.clearKeyHandler(Keyboard.DELETE, KeyboardEvent.KEY_DOWN, _handleDeleteKey);
			App.stage.removeEventListener(MouseEvent.MOUSE_DOWN, onAppMouseHandler);
			App.stage.removeEventListener(MouseEvent.MOUSE_WHEEL, onAppMouseHandler);
			App.stage.removeEventListener(Event.RESIZE, handleClose);

			redSlider.removeEventListener(SliderEvent.VALUE_CHANGE, handleSlider);
			greenSlider.removeEventListener(SliderEvent.VALUE_CHANGE, handleSlider);
			blueSlider.removeEventListener(SliderEvent.VALUE_CHANGE, handleSlider);
			acceptButton.removeEventListener(ButtonEvent.PRESS, handleAccept);
			hexTextInput.removeEventListener(InputEvent.INPUT, handleTextInput);
			colorSpectrum.removeEventListener(MouseEvent.CLICK, handleSpectrumClick);
			colorSpectrum.removeEventListener(MouseEvent.MOUSE_MOVE, handleSpectrumMove);
			colorSpectrum.removeEventListener(MouseEvent.ROLL_OUT, handleSpectrumRollOut);

			for each (var swatch:MovieClip in _swatches.concat(_userSwatches))
			{
				swatch.removeEventListener(MouseEvent.CLICK, handleSwatchClick);
				swatch.removeEventListener(MouseEvent.MOUSE_DOWN, handleSwatchMouseDown);
				swatch.removeEventListener(MouseEvent.ROLL_OVER, handleSwatchRoll);
				swatch.removeEventListener(MouseEvent.ROLL_OUT, handleSwatchRoll);
			}
			_swatches.length = 0;
			_swatchBright.length = 0;
			_userSwatches.length = 0;
			_userBright.length = 0;
			super.onDispose();
		}

		override protected function draw():void
		{
			super.draw();

			if (isInvalid(InvalidationType.DATA))
			{
				var colorHex:uint = parseInt(color, 16);
				var colorRgb:Object = {
					red: ((colorHex & 0xFF0000) >> 16),
					green: ((colorHex & 0x00FF00) >> 8),
					blue: ((colorHex & 0x0000FF))
				};

				drawPreview(colorHex);

				redSlider.value = colorRgb.red;
				greenSlider.value = colorRgb.green;
				blueSlider.value = colorRgb.blue;

				if (!hexTextInput.focused)
				{
					hexTextInput.text = "#" + color.toUpperCase();
				}

				if (_editSlot >= 0 && _editTouched && _userPresets != null && _color != null)
					_userPresets[_editSlot] = _color.toLowerCase();

				updateSwatchSelection();
			}
		}

		public function show():void
		{
			App.utils.popupMgr.removeAll();
			App.utils.popupMgr.show(DisplayObject(this), _position.x, _position.y);
		}

		private function handleSlider(event:SliderEvent):void
		{
			var hexVal:String = (redSlider.value << 16 | greenSlider.value << 8 | blueSlider.value).toString(16);

			while (hexVal.length < 6)
				hexVal = "0" + hexVal;

			color = hexVal;
		}

		private function handleTextInput(event:InputEvent):void
		{
			if (hexTextInput.focused)
			{
				var newColor:String = hexTextInput.text;

				newColor = newColor.split('#').join('');

				if (newColor.length == 6)
					color = newColor;
			}
		}

		private function endEdit():void
		{
			if (_editSlot < 0)
				return;

			_editSlot = -1;
			saveUserPresets();
		}

		private function handleAccept(event:ButtonEvent):void
		{
			if (_editSlot >= 0)
			{
				endEdit();

				if (_onValueChanged != null)
					_onValueChanged(_color);

				updateSwatchSelection();
				return;
			}

			if (_onValueChanged != null)
			{
				_onValueChanged(_color);
				handleClose();
			}
		}

		private function handleSpectrumClick(event:MouseEvent):void
		{
			var hexVal:String = _spectrumData.getPixel(event.localX, event.localY).toString(16);

			while (hexVal.length < 6)
				hexVal = "0" + hexVal;

			color = hexVal;
		}

		private function drawPreview(colorHex:uint):void
		{
			colorPreview.graphics.clear();
			colorPreview.graphics.beginFill(colorHex);
			colorPreview.graphics.drawRect(0, 0, 100, 100);
			colorPreview.graphics.endFill();
		}

		private function handleSpectrumMove(event:MouseEvent):void
		{
			if (_spectrumData != null)
				drawPreview(_spectrumData.getPixel(event.localX, event.localY));
		}

		private function handleSpectrumRollOut(event:MouseEvent):void
		{
			if (_color != null)
				drawPreview(parseInt(_color, 16));
		}

		private function _handleEscKey():void
		{
			App.popoverMgr.hide();
			dispose();
		}

		private function _handleDeleteKey():void
		{
			if (hexTextInput != null && hexTextInput.focused)
				return;

			if (_editSlot < 0 || _userPresets == null)
				return;

			clearUserSlot(_editSlot);
		}

		private function handleClose():void
		{
			dispose();
		}

		private function onAppMouseHandler(event:MouseEvent):void
		{
			if (_menuOpen)
			{
				if (event.type == MouseEvent.MOUSE_DOWN)
					_menuOpen = false;

				return;
			}

			if (!hitAreaA.hitTestPoint(App.stage.mouseX, App.stage.mouseY))
				handleClose();
		}

		private function modRowCount():int
		{
			if (_presets == null || _presets.length == 0)
				return 0;

			return (_presets.length > SLOTS_PER_ROW) ? 2 : 1;
		}

		private function userRowCount():int
		{
			if (_userPresets == null || _presets != null)
				return 0;

			var i:int;
			var lastColored:int = -1;

			for (i = 0; i < _userPresets.length; i++)
			{
				if (_userPresets[i] != null)
					lastColored = i;
			}

			var fullPrefix:int = _userPresets.length;

			for (i = 0; i < _userPresets.length; i++)
			{
				if (_userPresets[i] == null)
				{
					fullPrefix = i;
					break;
				}
			}

			var rows:int = Math.max(1, int(lastColored / SLOTS_PER_ROW) + 1, int(fullPrefix / SLOTS_PER_ROW) + 1);

			return Math.min(USER_ROWS_MAX, rows);
		}

		private function swatchRowCount():int
		{
			return modRowCount() + userRowCount();
		}

		private function buildSwatches():void
		{
			if (_swatches.length > 0 || _userSwatches.length > 0 || !_uiConfigured || !_presetsSized)
				return;

			var rows:int = swatchRowCount();

			if (rows == 0)
				return;

			var rowY:Number = isCompact()
				? SWATCH_PAD
				: hitAreaA.height - (SWATCH_PAD + rows * SWATCH_ROW_H + 2) + SWATCH_PAD;
			var i:int;

			for (i = 0; i < modRowCount(); i++)
			{
				buildRow(i * SLOTS_PER_ROW, Math.min(_presets.length, (i + 1) * SLOTS_PER_ROW), rowY, false);
				rowY += SWATCH_ROW_H;
			}

			var uRows:int = userRowCount();

			for (i = 0; i < uRows; i++)
			{
				buildRow(i * SLOTS_PER_ROW, (i + 1) * SLOTS_PER_ROW, rowY, true);
				rowY += SWATCH_ROW_H;
			}

			updateSwatchSelection();
		}

		private function buildRow(fromIdx:int, toIdx:int, rowY:Number, userRow:Boolean):void
		{
			var count:int = toIdx - fromIdx;
			var rowW:int = count * SWATCH_SIZE + (count - 1) * SWATCH_GAP;
			var startX:Number = (hitAreaA.width - rowW) / 2;

			for (var i:int = 0; i < count; i++)
			{
				var swatch:MovieClip = new MovieClip();

				swatch.slotIndex = fromIdx + i;
				swatch.userRow = userRow;
				swatch.x = startX + i * (SWATCH_SIZE + SWATCH_GAP);
				swatch.y = rowY;
				swatch.buttonMode = true;
				swatch.useHandCursor = true;

				swatch.addEventListener(MouseEvent.CLICK, handleSwatchClick);
				swatch.addEventListener(MouseEvent.MOUSE_DOWN, handleSwatchMouseDown);
				swatch.addEventListener(MouseEvent.ROLL_OVER, handleSwatchRoll);
				swatch.addEventListener(MouseEvent.ROLL_OUT, handleSwatchRoll);

				addChild(swatch);

				if (userRow)
				{
					_userSwatches.push(swatch);
					_userBright.push(new HoverBrightener(swatch, Constants.HOVER_BRIGHTEN));
				}
				else
				{
					_swatches.push(swatch);
					_swatchBright.push(new HoverBrightener(swatch, Constants.HOVER_BRIGHTEN));
				}
			}
		}

		public function updateSwatchSelection():void
		{
			var current:String = (_color != null) ? _color.toLowerCase() : '';
			var i:int;

			for (i = 0; i < _swatches.length; i++)
			{
				var modIdx:int = int(_swatches[i].slotIndex);

				drawSwatch(_swatches[i], _presets[modIdx], _presets[modIdx] == current, false);
			}

			for (i = 0; i < _userSwatches.length; i++)
			{
				var idx:int = int(_userSwatches[i].slotIndex);
				var slotColor:String = _userPresets[idx];

				drawSwatch(_userSwatches[i], slotColor, slotColor != null && slotColor == current, idx == _editSlot);
			}
		}

		private function drawSwatch(swatch:MovieClip, colorHex:String, active:Boolean, editing:Boolean):void
		{
			swatch.graphics.clear();

			if (editing)
			{
				swatch.graphics.lineStyle(1, 0x000000, 1);
				swatch.graphics.drawRect(-2, -2, SWATCH_SIZE + 4, SWATCH_SIZE + 4);
				swatch.graphics.lineStyle(2, EDIT_COLOR, 1);
			}
			else if (active)
			{
				swatch.graphics.lineStyle(1, 0x000000, 1);
				swatch.graphics.drawRect(-2, -2, SWATCH_SIZE + 4, SWATCH_SIZE + 4);
				swatch.graphics.lineStyle(2, 0xFFFFFF, 1);
			}
			else
			{
				swatch.graphics.lineStyle(1, 0x000000, 0.9);
			}

			if (colorHex != null)
			{
				swatch.graphics.beginFill(parseInt(colorHex, 16));
				swatch.graphics.drawRect(0, 0, SWATCH_SIZE, SWATCH_SIZE);
				swatch.graphics.endFill();
			}
			else
			{
				swatch.graphics.beginFill(0x1A1A1A, 0.9);
				swatch.graphics.drawRect(0, 0, SWATCH_SIZE, SWATCH_SIZE);
				swatch.graphics.endFill();
				swatch.graphics.lineStyle(1, 0x777777, 0.9);
				swatch.graphics.moveTo(SWATCH_SIZE / 2 - 3, SWATCH_SIZE / 2);
				swatch.graphics.lineTo(SWATCH_SIZE / 2 + 3, SWATCH_SIZE / 2);
				swatch.graphics.moveTo(SWATCH_SIZE / 2, SWATCH_SIZE / 2 - 3);
				swatch.graphics.lineTo(SWATCH_SIZE / 2, SWATCH_SIZE / 2 + 3);
			}
		}

		private function handleSwatchClick(event:MouseEvent):void
		{
			var swatch:MovieClip = event.currentTarget as MovieClip;

			if (swatch == null)
				return;

			var idx:int = int(swatch.slotIndex);

			if (Boolean(swatch.userRow))
			{
				var slotColor:String = _userPresets[idx];

				if (slotColor == null)
				{
					enterEditMode(idx);
				}
				else if (idx != _editSlot)
				{
					endEdit();

					if (slotColor != _color)
						color = slotColor;
					else
						updateSwatchSelection();
				}
			}
			else
			{
				endEdit();

				if (_presets[idx] != _color)
					color = _presets[idx];
				else
					updateSwatchSelection();
			}
		}

		private function handleSwatchMouseDown(event:MouseEvent):void
		{
			var swatch:MovieClip = event.currentTarget as MovieClip;

			if (swatch == null || !Boolean(swatch.userRow))
				return;

			if (App.utils.commons.isRightButton(event))
			{
				var idx:int = int(swatch.slotIndex);

				if (_userPresets[idx] == null)
					return;

				event.stopPropagation();
				_menuOpen = true;
				App.contextMenuMgr.show(Constants.PRESET_CONTEXT_MENU_HANDLER, this, {'slot': idx, 'value': String(_userPresets[idx])});
			}
		}

		private function handleSwatchRoll(event:MouseEvent):void
		{
			var swatch:MovieClip = event.currentTarget as MovieClip;

			if (swatch == null)
				return;

			var over:Boolean = (event.type == MouseEvent.ROLL_OVER);

			if (Boolean(swatch.userRow))
			{
				var pos:int = _userSwatches.indexOf(swatch);

				if (pos >= 0)
					HoverBrightener(_userBright[pos]).on = over;
			}
			else
			{
				var modPos:int = _swatches.indexOf(swatch);

				if (modPos >= 0)
					HoverBrightener(_swatchBright[modPos]).on = over;
			}
		}

		public function handlePresetAction(action:String, slot:int):void
		{
			if (_userPresets == null || slot < 0 || slot >= _userPresets.length)
				return;

			if (action == 'edit')
				enterEditMode(slot);
			else if (action == 'clear')
				clearUserSlot(slot);
		}

		private function enterEditMode(slot:int):void
		{
			if (_editSlot >= 0 && _editSlot != slot)
				endEdit();

			_editSlot = slot;
			_editTouched = false;

			var slotColor:String = _userPresets[slot];

			if (slotColor != null && slotColor != _color)
				color = slotColor;
			else
				updateSwatchSelection();
		}

		private function clearUserSlot(slot:int):void
		{
			_userPresets[slot] = null;

			if (_editSlot == slot)
				_editSlot = -1;

			saveUserPresets();
			updateSwatchSelection();
		}

		private function saveUserPresets():void
		{
			if (_userPresets != null && _saveHandler != null)
				_saveHandler(_userPresets.concat());
		}

		public function set presets(value:Array):void
		{
			if (value == null)
			{
				_presets = null;
			}
			else
			{
				var list:Array = [];

				for (var i:int = 0; i < value.length && list.length < MAX_MOD_PRESETS; i++)
				{
					var entry:String = String(value[i]).split('#').join('').toLowerCase();

					if (/^[0-9a-f]{6}$/.test(entry))
						list.push(entry);
				}

				_presets = list;
			}

			var rows:int = swatchRowCount();

			if ((rows > 0 || isCompact()) && !_presetsSized)
			{
				if (isCompact())
				{
					var perRow:int = Math.min(_presets.length, SLOTS_PER_ROW);
					var rowW:int = perRow * SWATCH_SIZE + (perRow - 1) * SWATCH_GAP;

					hitAreaA.width = Math.min(hitAreaA.width, Math.max(COMPACT_MIN_W, rowW + 2 * COMPACT_SIDE_PAD));
					hitAreaA.height = SWATCH_PAD + rows * SWATCH_ROW_H + 6 + COMPACT_BTN_H + 8;
				}
				else
					hitAreaA.height += SWATCH_PAD + rows * SWATCH_ROW_H + 2;

				_presetsSized = true;

				if (_uiConfigured)
				{
					background.width = hitAreaA.width + 120;
					background.height = hitAreaA.height + 120;
					arrowBottom.y = hitAreaA.height + 4;

					if (isCompact())
						applyCompactLayout();
				}
			}

			buildSwatches();
		}

		public function set presetsOnly(value:Boolean):void
		{
			_presetsOnly = value;
		}

		public function set onValueChanged(callback:Function):void
		{
			_onValueChanged = callback;
		}

		public function set color(newColor:String):void
		{
			if (newColor == _color)
				return;

			if (_editSlot >= 0)
				_editTouched = true;

			_color = newColor;
			invalidateData();
		}

		public function get color():String
		{
			return _color;
		}

		public function set position(position:Point):void
		{
			_position = position;
		}

		public function get position():Point
		{
			return _position;
		}

		public function set arrowDirection(direction:int):void
		{
			arrowTop.visible = false;
			arrowBottom.visible = false;

			if (direction == PopOverConst.ARROW_BOTTOM)
				arrowBottom.visible = true;
			else
				arrowTop.visible = true;
		}
	}
}
