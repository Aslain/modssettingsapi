package poliroid.gui.lobby.modsSettings.controls
{
	import flash.display.DisplayObject;
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import net.wg.gui.components.controls.SoundButtonEx;
	import poliroid.gui.lobby.modsSettings.data.HotkeyControlVO;
	import poliroid.gui.lobby.modsSettings.events.InteractiveEvent;
	import poliroid.gui.lobby.modsSettings.shared.Constants;

	public class HotkeyControl extends SoundButtonEx
	{
		private static const COMMAND_START_ACCEPT:String = 'startAccept';
		private static const COMMAND_STOP_ACCEPT:String = 'stopAccept';
		private static const STATE_ACCEPTING:String = 'accepting';
		private static const STATE_EMPTY:String = 'empty';
		private static const STATE_NORMAL:String = 'normal';
		private static const MODIFIERS_PREFIX:String = 'mod_';

		public static const DISPLAY_CHANGED:String = 'hotkeyDisplayChanged';

		public var valueTF:TextField;
		public var statesMC:MovieClip;
		public var modifiersMC:MovieClip;
		public var hitAreaA:MovieClip;

		private static const CHIP_GAP:Number = 4;
		private static const PAD_H:Number = 7;
		private static const BOX_MIN_W:Number = 56;

		private var _model:HotkeyControlVO;
		private var _keyset:Array;
		private var _tfRight:Number = NaN;
		private var _maxRightLocal:Number = NaN;
		private var _modOrigX:Number = 0;
		private var _decor:Array;
		private var _decorOrigX:Array;
		private var _frame:Shape;
		private var _hover:Boolean = false;
		private var _hitSprite:Sprite;
		private var _comboLeft:Number = 0;
		private var _boxTop:Number = 3;
		private var _boxH:Number = 19;
		private var _boxLeft:Number = 0;
		private var _boxDrawW:Number = 0;

		public function HotkeyControl():void
		{
			super();
		}

		override protected function configUI():void
		{
			super.configUI();

			scaleX = 1;
			scaleY = 1;
			preventAutosizing = true;
			focusable = false;
			_hitSprite = new Sprite();
			_hitSprite.mouseEnabled = false;
			_hitSprite.mouseChildren = false;
			addChild(_hitSprite);
			hitArea = _hitSprite;
			valueTF.selectable = false;
			_tfRight = valueTF.x + valueTF.width;
			_modOrigX = modifiersMC.x;
			valueTF.autoSize = TextFieldAutoSize.RIGHT;

			_boxTop = 3;
			_boxH = 19;
			valueTF.text = '';

			addEventListener(MouseEvent.ROLL_OVER, onRollOver);
			addEventListener(MouseEvent.ROLL_OUT, onRollOut);

			_decor = [];
			_decorOrigX = [];
			for (var i:int = 0; i < numChildren; i++)
			{
				var child:DisplayObject = getChildAt(i);
				if (child != valueTF && child != hitAreaA && child != modifiersMC && child != _hitSprite)
				{
					_decor.push(child);
					_decorOrigX.push(child.x);
				}
			}

			_frame = new Shape();
			addChildAt(_frame, getChildIndex(valueTF));

			setDecorVisible(false);
			if (_model != null)
				setData(_model);
			else
				updateHitArea();
		}

		override protected function setState(state:String):void
		{
		}

		private function drawFrame():void
		{
			var topC:uint = _hover ? 0x47473E : 0x333328;
			var midC:uint = _hover ? 0x5C5C4E : 0x4A4A3A;
			var botC:uint = _hover ? 0x3A3A34 : 0x24241D;
			var innerC:uint = _hover ? 0x1A1A1A : 0x000000;
			var fillC:uint = _hover ? 0x222220 : 0x0A0A06;

			var x:Number = _boxLeft;
			var y:Number = _boxTop;
			var w:Number = _boxDrawW;
			var h:Number = _boxH;

			var g:Graphics = _frame.graphics;
			g.clear();
			g.lineStyle();

			var m:Matrix = new Matrix();
			m.createGradientBox(h, h, Math.PI / 2, x, y);
			g.beginGradientFill(GradientType.LINEAR, [topC, midC, botC], [1, 1, 1], [0, 128, 255], m);
			g.drawRoundRect(x, y, w, h, 4, 4);
			g.endFill();

			g.beginFill(innerC, 1);
			g.drawRoundRect(x + 1, y + 1, w - 2, h - 2, 3, 3);
			g.endFill();

			g.beginFill(fillC, 0.81);
			g.drawRoundRect(x + 2, y + 2, w - 4, h - 4, 2, 2);
			g.endFill();
		}

		private function onRollOver(event:MouseEvent):void
		{
			_hover = true;
			if (_frame != null && _frame.visible)
				drawFrame();
		}

		private function onRollOut(event:MouseEvent):void
		{
			_hover = false;
			if (_frame != null && _frame.visible)
				drawFrame();
		}

		private function setDecorVisible(value:Boolean):void
		{
			if (_decor == null)
				return;
			for (var i:int = 0; i < _decor.length; i++)
				DisplayObject(_decor[i]).visible = value;
		}

		private function applyStateShift():void
		{
			if (_decor == null || _decorOrigX == null)
				return;
			var shift:Number = isNaN(_maxRightLocal) ? 0 : (_maxRightLocal - _tfRight);
			for (var i:int = 0; i < _decor.length; i++)
				DisplayObject(_decor[i]).x = Number(_decorOrigX[i]) + shift;
			modifiersMC.x = _modOrigX + shift;
		}

		public function setData(data:HotkeyControlVO):void
		{
			_model = data;

			if (_keyset && (_keyset.toString() != _model.keyset.toString()))
				dispatchEvent(new InteractiveEvent(InteractiveEvent.VALUE_CHANGED));

			_keyset = _model.keyset;

			if (_model.isAccepting)
			{
				setDecorVisible(true);
				modifiersMC.visible = true;
				modifiersMC.gotoAndStop(MODIFIERS_PREFIX);
				if (_frame != null)
					_frame.visible = false;
				statesMC.gotoAndPlay(STATE_ACCEPTING);
				valueTF.text = '';
				applyStateShift();
			}
			else if (_model.isEmpty)
			{
				setDecorVisible(true);
				modifiersMC.visible = true;
				modifiersMC.gotoAndStop(MODIFIERS_PREFIX);
				if (_frame != null)
					_frame.visible = false;
				statesMC.gotoAndPlay(STATE_EMPTY);
				valueTF.text = '';
				applyStateShift();
			}
			else
			{
				setDecorVisible(false);
				statesMC.gotoAndStop(STATE_NORMAL);

				var modifiersLabel:String = MODIFIERS_PREFIX;
				if (_model.modifierCtrl)
					modifiersLabel += 'ctrl';
				if (_model.modifierAlt)
					modifiersLabel += 'alt';
				if (_model.modiferShift)
					modifiersLabel += 'shift';

				modifiersMC.gotoAndStop(modifiersLabel);
				modifiersMC.visible = (modifiersLabel != MODIFIERS_PREFIX);
				valueTF.text = _model.text;
			}

			var gb:Rectangle = (valueTF.length > 0) ? valueTF.getCharBoundaries(0) : null;
			if (gb != null)
				valueTF.y = Math.round(_boxTop + (_boxH - gb.height) / 2 - gb.y) - 1;
			else
				valueTF.y = Math.round(_boxTop + (_boxH - valueTF.textHeight) / 2 - 2);

			if (_frame != null && _model != null && !_model.isEmpty && !_model.isAccepting)
			{
				var rightAnchor:Number = isNaN(_maxRightLocal) ? _tfRight : _maxRightLocal;
				_boxDrawW = Math.max(BOX_MIN_W, valueTF.width + PAD_H * 2);
				_boxLeft = rightAnchor - _boxDrawW;
				valueTF.x = Math.round(_boxLeft + (_boxDrawW - valueTF.width) / 2);
				drawFrame();
				_frame.visible = true;
				if (modifiersMC.visible)
				{
					var b:Rectangle = modifiersMC.getBounds(this);
					modifiersMC.x += (_boxLeft - CHIP_GAP) - b.right;
					_comboLeft = modifiersMC.getBounds(this).left;
				}
				else
				{
					_comboLeft = _boxLeft;
				}
			}
			else
			{
				modifiersMC.x = _modOrigX;
				_comboLeft = 0;
			}

			updateHitArea();

			if (_model.isEmpty || _model.isAccepting || _frame != null)
				dispatchEvent(new Event(DISPLAY_CHANGED));
		}

		private function updateHitArea():void
		{
			if (_hitSprite == null)
				return;

			var r:Rectangle = null;

			if (modifiersMC != null && modifiersMC.visible)
				r = mergeRect(r, modifiersMC.getBounds(this));

			if (_model != null && (_model.isEmpty || _model.isAccepting))
			{
				if (_decor != null)
					for (var di:int = 0; di < _decor.length; di++)
					{
						var d:DisplayObject = DisplayObject(_decor[di]);
						if (d.visible)
							r = mergeRect(r, d.getBounds(this));
					}
			}
			else
			{
				if (_frame != null && _frame.visible)
					r = mergeRect(r, _frame.getBounds(this));
				if (valueTF != null && valueTF.text != '')
					r = mergeRect(r, valueTF.getBounds(this));
			}

			if (r == null || r.width <= 0 || r.height <= 0)
				r = new Rectangle(0, 0, (isNaN(_tfRight) ? 60 : _tfRight), 25);

			var g:Graphics = _hitSprite.graphics;
			g.clear();
			g.beginFill(0, 0);
			g.drawRect(r.x - 3, r.y - 3, r.width + 6, r.height + 6);
			g.endFill();
		}

		private function mergeRect(a:Rectangle, b:Rectangle):Rectangle
		{
			if (b == null || (b.width <= 0 && b.height <= 0))
				return a;
			return (a == null) ? b.clone() : a.union(b);
		}

		public function get comboLeft():Number
		{
			if (_model == null || _model.isEmpty || _model.isAccepting)
				return 0;
			return _comboLeft;
		}

		public function set maxRightLocal(value:Number):void
		{
			_maxRightLocal = value;
			if (_model != null && _frame != null)
				setData(_model);
		}

		public function relayout():void
		{
			if (_model != null && _frame != null)
				setData(_model);
		}

		override protected function onMouseDownHandler(event:MouseEvent):void
		{
			super.onMouseDownHandler(event);

			if (App.utils.commons.isLeftButton(event))
			{
				if (!_model.isAccepting)
					dispatchEvent(new InteractiveEvent(InteractiveEvent.HOTKEY_ACTION, _model.linkage, _model.varName, COMMAND_START_ACCEPT));
			}
			else if (App.utils.commons.isRightButton(event))
			{
				if (_model.isAccepting)
					dispatchEvent(new InteractiveEvent(InteractiveEvent.HOTKEY_ACTION, _model.linkage, _model.varName, COMMAND_STOP_ACCEPT));

				App.contextMenuMgr.show(Constants.HOTKEY_CONTEXT_MENU_HANDLER, this, {'linkage': _model.linkage, 'varName': _model.varName, 'value': _keyset});
			}
		}

		public function get keyset():Array
		{
			return _keyset;
		}
	}
}
