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
			// Own hit area instead of the static .fla hitAreaA: the box is now right-aligned
			// at a dynamic x, so the clickable/hover region has to follow it. Rebuilt to the
			// live combo bounds in updateHitArea() on every layout pass.
			_hitSprite = new Sprite();
			_hitSprite.mouseEnabled = false;
			_hitSprite.mouseChildren = false;
			addChild(_hitSprite);
			hitArea = _hitSprite;
			valueTF.selectable = false;
			_tfRight = valueTF.x + valueTF.width;
			_modOrigX = modifiersMC.x;
			valueTF.autoSize = TextFieldAutoSize.RIGHT;

			// Box band is constant: the chip/box PNGs are a 25 px canvas with the solid
			// gold body at rows 3..21 (19 px). Hardcode it - measuring here was flaky
			// (the chip bitmap isn't always ready, getBounds returned 0, and some boxes
			// fell back to a wrong 25 px height that flickered on reload).
			_boxTop = 3;
			_boxH = 19;
			// Clear the .fla placeholder ("F1") so nothing flashes before real data.
			valueTF.text = '';

			addEventListener(MouseEvent.ROLL_OVER, onRollOver);
			addEventListener(MouseEvent.ROLL_OUT, onRollOut);

			// The key-box frame is unnamed static artwork at the symbol root (not a
			// statesMC frame), so collect every child that is not the text / chips /
			// hit area and toggle it per display state.
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
			// Reproduce the original izeberg key-box artwork (buttonNormal.png / buttonHovered.png)
			// in code, so the right-aligned dynamic-width box keeps the bevel of the static .fla
			// slot. Built from concentric rounded-rect FILLS, not a gradient stroke: Scaleform
			// shades a gradient line along the path length, which dropped the highlight on the
			// right edge. A gradient FILL is spatial, so both vertical sides read identically.
			// Outer 1 px ring = vertical 3-stop gradient (medium top -> brightest mid-height ->
			// dimmest bottom); then a 1 px dark inner line; then the dark translucent body.
			// Colors sampled straight from the PNGs.
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

			// Outer highlight ring: a vertical 3-stop gradient fill over the whole box, left as a
			// 1 px ring once the inner rings cover it. createGradientBox span is keyed to the box
			// HEIGHT (first arg = h) so the gradient maps top->bottom regardless of box width.
			var m:Matrix = new Matrix();
			m.createGradientBox(h, h, Math.PI / 2, x, y);
			g.beginGradientFill(GradientType.LINEAR, [topC, midC, botC], [1, 1, 1], [0, 128, 255], m);
			g.drawRoundRect(x, y, w, h, 4, 4);
			g.endFill();

			// Inner dark line (1 px) just inside the highlight.
			g.beginFill(innerC, 1);
			g.drawRoundRect(x + 1, y + 1, w - 2, h - 2, 3, 3);
			g.endFill();

			// Dark translucent body.
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

		// Empty / accepting states draw the static .fla box + statesMC indicator, which sit
		// at the original left slot. Slide them (and the placeholder chips) right by the same
		// delta the normal box moved, so the box stays put when you click to rebind a key.
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

			// Center the REAL glyph rectangle in the box. textHeight reserves descender
			// space that all-caps key names never use, which left the caps sitting too
			// high; getCharBoundaries gives the actual drawn glyph extent.
			var gb:Rectangle = (valueTF.length > 0) ? valueTF.getCharBoundaries(0) : null;
			if (gb != null)
				// Centre the real glyph box, snapped to a whole pixel and nudged up 1 px: the
				// sub-pixel centre rendered visually a touch low.
				valueTF.y = Math.round(_boxTop + (_boxH - gb.height) / 2 - gb.y) - 1;
			else
				valueTF.y = Math.round(_boxTop + (_boxH - valueTF.textHeight) / 2 - 2);

			if (_frame != null && _model != null && !_model.isEmpty && !_model.isAccepting)
			{
				// Box grows left only for long keys, right edge pinned to a fixed anchor so
				// the whole combo is right-aligned. The layout (createComponents) feeds the
				// real anchor via maxRightLocal - the rightmost x usable before the next
				// column or the on/off switcher - so combos use the full free width instead
				// of stopping at the original narrow .fla slot. Falls back to the .fla slot
				// (_tfRight) when no layout anchor was supplied.
				var rightAnchor:Number = isNaN(_maxRightLocal) ? _tfRight : _maxRightLocal;
				_boxDrawW = Math.max(BOX_MIN_W, valueTF.width + PAD_H * 2);
				_boxLeft = rightAnchor - _boxDrawW;
				valueTF.x = Math.round(_boxLeft + (_boxDrawW - valueTF.width) / 2);
				drawFrame();
				_frame.visible = true;
				if (modifiersMC.visible)
				{
					// Pin the chips' right edge a fixed gap left of the box, from real
					// bounds so spacing stays constant at any box width.
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

			// Don't notify the label until the box is actually laid out. setData can
			// arrive before configUI (no _frame yet) - that early pass leaves comboLeft=0,
			// which would wrap the label full-width and reveal it, then re-wrap narrow a
			// moment later (the flicker). configUI re-runs setData once _frame exists.
			if (_model.isEmpty || _model.isAccepting || _frame != null)
				dispatchEvent(new Event(DISPLAY_CHANGED));
		}

		// Rebuild the hit region to cover whatever the control currently shows: the key box
		// + chips in the normal state, or the placeholder / accepting indicator otherwise.
		// Drawn with a 0-alpha fill (geometry still counts for hit testing) and a few px of
		// padding so hover feels the same as the old static area.
		private function updateHitArea():void
		{
			if (_hitSprite == null)
				return;

			var r:Rectangle = null;

			if (modifiersMC != null && modifiersMC.visible)
				r = mergeRect(r, modifiersMC.getBounds(this));

			if (_model != null && (_model.isEmpty || _model.isAccepting))
			{
				// The visible box artwork + statesMC indicator (both in _decor, now shifted).
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

		// Control-local x of the box right edge, fed by the layout from the column /
		// switcher boundary. Re-runs the layout if data is already present (reload).
		public function set maxRightLocal(value:Number):void
		{
			_maxRightLocal = value;
			if (_model != null && _frame != null)
				setData(_model);
		}

		// Re-run the layout against the CURRENT data. Used after the control is put on
		// stage: off-stage the wrapped label's textHeight is short by ~one line, so the
		// row (and the whole mod) builds too short and snaps to its true height a frame
		// later. Re-laying on stage measures the label correctly the first time.
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
