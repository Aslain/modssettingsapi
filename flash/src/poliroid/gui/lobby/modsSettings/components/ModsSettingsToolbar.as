package poliroid.gui.lobby.modsSettings.components
{
	import flash.display.Sprite;
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.text.TextFieldAutoSize;
	import flash.text.AntiAliasType;
	import poliroid.gui.lobby.modsSettings.events.InteractiveEvent;
	import poliroid.gui.lobby.modsSettings.shared.Constants;

	// Toolbar shown above the mods list: a single collapse/expand-all icon button
	// (a rectangle with two chevrons) plus a horizontal A-Z quick-jump bar.
	public class ModsSettingsToolbar extends Sprite
	{
		private static const LETTERS:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
		private static const COLOR_HOVER:uint = 0xFFFFFF;

		private var _collapseBtn:Sprite;
		private var _letters:Object;
		private var _allCollapsed:Boolean = false;
		private var _textColor:uint = Constants.TOOLBAR_TEXT_COLOR;

		public function ModsSettingsToolbar()
		{
			super();
			_letters = new Object();
			mouseEnabled = false;
			createCollapseButton();
			createLetters();
		}

		private function letterFormat(color:uint):TextFormat
		{
			var fmt:TextFormat = new TextFormat();
			fmt.font = "$TitleFont";
			fmt.size = 14;
			fmt.color = color;
			fmt.align = TextFormatAlign.CENTER;
			return fmt;
		}

		private function createCollapseButton():void
		{
			_collapseBtn = new Sprite();
			_collapseBtn.x = 4;
			_collapseBtn.y = 0;
			_collapseBtn.buttonMode = true;
			_collapseBtn.useHandCursor = true;
			_collapseBtn.addEventListener(MouseEvent.CLICK, onCollapseClick);
			_collapseBtn.addEventListener(MouseEvent.ROLL_OVER, onCollapseOver);
			_collapseBtn.addEventListener(MouseEvent.ROLL_OUT, onCollapseOut);
			addChild(_collapseBtn);
			drawCollapseIcon();
		}

		private function drawCollapseIcon():void
		{
			var s:Number = Constants.TOOLBAR_COLLAPSE_BTN_SIZE;
			var cx:Number = s / 2;
			var hw:Number = 5;
			var ch:Number = 4;

			_collapseBtn.graphics.clear();
			// transparent hit area
			_collapseBtn.graphics.beginFill(0, 0);
			_collapseBtn.graphics.drawRect(0, 0, s, s);
			_collapseBtn.graphics.endFill();
			_collapseBtn.graphics.beginFill(_textColor, 1);

			if (_allCollapsed)
			{
				// expand: chevrons point away from centre (top up, bottom down)
				_collapseBtn.graphics.moveTo(cx - hw, 8); _collapseBtn.graphics.lineTo(cx + hw, 8); _collapseBtn.graphics.lineTo(cx, 4);
				_collapseBtn.graphics.moveTo(cx - hw, s - 8); _collapseBtn.graphics.lineTo(cx + hw, s - 8); _collapseBtn.graphics.lineTo(cx, s - 4);
			}
			else
			{
				// collapse: chevrons point toward the centre (top down, bottom up)
				_collapseBtn.graphics.moveTo(cx - hw, 4); _collapseBtn.graphics.lineTo(cx + hw, 4); _collapseBtn.graphics.lineTo(cx, 4 + ch);
				_collapseBtn.graphics.moveTo(cx - hw, s - 4); _collapseBtn.graphics.lineTo(cx + hw, s - 4); _collapseBtn.graphics.lineTo(cx, s - 4 - ch);
			}

			_collapseBtn.graphics.endFill();
		}

		private function createLetters():void
		{
			var left:Number = Constants.TOOLBAR_LETTERS_LEFT;
			var slot:Number = (Constants.MOD_COMPONENT_WIDTH - left) / LETTERS.length;

			for (var i:int = 0; i < LETTERS.length; i++)
			{
				var letter:String = LETTERS.charAt(i);
				var holder:MovieClip = new MovieClip();
				holder.x = left + i * slot;

				var tf:TextField = new TextField();
				tf.selectable = false;
				tf.mouseEnabled = false;
				tf.embedFonts = true;
				tf.antiAliasType = AntiAliasType.ADVANCED;
				tf.autoSize = TextFieldAutoSize.NONE;
				tf.width = slot;
				tf.height = Constants.TOOLBAR_HEIGHT;
				tf.defaultTextFormat = letterFormat(_textColor);
				tf.text = letter;

				holder.addChild(tf);
				holder.graphics.beginFill(0, 0);
				holder.graphics.drawRect(0, 0, slot, Constants.TOOLBAR_HEIGHT);
				holder.graphics.endFill();
				holder.buttonMode = true;
				holder.useHandCursor = true;
				holder.mouseChildren = false;
				holder["tf"] = tf;
				holder["letter"] = letter;
				holder["available"] = true;
				holder["ox"] = holder.x;
				holder["slot"] = slot;
				holder.addEventListener(MouseEvent.CLICK, onLetterClick);
				holder.addEventListener(MouseEvent.ROLL_OVER, onLetterOver);
				holder.addEventListener(MouseEvent.ROLL_OUT, onLetterOut);

				addChild(holder);
				_letters[letter] = holder;
			}
		}

		// Highlight only the letters that have at least one mod; grey out the rest
		public function setAvailableLetters(available:Object):void
		{
			for (var letter:String in _letters)
			{
				var holder:MovieClip = MovieClip(_letters[letter]);
				var has:Boolean = available != null && available[letter] == true;

				holder["available"] = has;
				holder.mouseEnabled = has;
				holder.alpha = has ? 1 : 0.25;
			}
		}

		public function setCollapseState(allCollapsed:Boolean):void
		{
			if (_allCollapsed == allCollapsed)
				return;

			_allCollapsed = allCollapsed;
			drawCollapseIcon();
		}

		private function onCollapseClick(event:MouseEvent):void
		{
			// value = target collapsed state for every mod
			dispatchEvent(new InteractiveEvent(InteractiveEvent.COLLAPSE_ALL, '', '', !_allCollapsed));
		}

		private function onCollapseOver(event:MouseEvent):void
		{
			_collapseBtn.alpha = 0.7;
		}

		private function onCollapseOut(event:MouseEvent):void
		{
			_collapseBtn.alpha = 1;
		}

		private function onLetterClick(event:MouseEvent):void
		{
			var holder:MovieClip = MovieClip(event.currentTarget);

			if (holder["available"] == true)
				dispatchEvent(new InteractiveEvent(InteractiveEvent.JUMP_TO_LETTER, '', String(holder["letter"])));
		}

		private function onLetterOver(event:MouseEvent):void
		{
			var holder:MovieClip = MovieClip(event.currentTarget);
			TextField(holder["tf"]).textColor = COLOR_HOVER;

			// Scale up around the letter's centre so it pops out on hover
			var s:Number = 1.4;
			var slot:Number = Number(holder["slot"]);
			holder.scaleX = holder.scaleY = s;
			holder.x = Number(holder["ox"]) + slot * (1 - s) / 2;
			holder.y = (Constants.TOOLBAR_HEIGHT / 2) * (1 - s);
			addChild(holder);
		}

		private function onLetterOut(event:MouseEvent):void
		{
			var holder:MovieClip = MovieClip(event.currentTarget);
			TextField(holder["tf"]).textColor = _textColor;

			holder.scaleX = holder.scaleY = 1;
			holder.x = Number(holder["ox"]);
			holder.y = 0;
		}
	}
}
