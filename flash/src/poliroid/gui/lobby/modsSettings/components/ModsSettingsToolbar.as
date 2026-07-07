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

	public class ModsSettingsToolbar extends Sprite
	{
		private static const LETTERS:String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
		private static const COLOR_HOVER:uint = 0xFFFFFF;

		private static const LETTER_SLOT:Number = 32;

		private static const COLUMN_TOGGLE_ZONE:Number = 30;

		private var _collapseBtn:Sprite;
		private var _columnBtn:Sprite;
		private var _multiMode:Boolean = false;
		private var _letters:Object;
		private var _allCollapsed:Boolean = false;
		private var _textColor:uint = Constants.TOOLBAR_TEXT_COLOR;

		public function ModsSettingsToolbar()
		{
			super();
			_letters = new Object();
			mouseEnabled = false;
			createCollapseButton();
			createColumnButton();
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
			drawCollapseIcon(_textColor);
		}

		private function drawCollapseIcon(color:uint):void
		{
			var s:Number = Constants.TOOLBAR_COLLAPSE_BTN_SIZE;
			var cx:Number = s / 2;
			var hw:Number = 5;
			var ch:Number = 4;

			_collapseBtn.graphics.clear();
			_collapseBtn.graphics.beginFill(0, 0);
			_collapseBtn.graphics.drawRect(0, 0, s, s);
			_collapseBtn.graphics.endFill();
			_collapseBtn.graphics.beginFill(color, 1);

			if (_allCollapsed)
			{
				_collapseBtn.graphics.moveTo(cx - hw, 8); _collapseBtn.graphics.lineTo(cx + hw, 8); _collapseBtn.graphics.lineTo(cx, 4);
				_collapseBtn.graphics.moveTo(cx - hw, s - 8); _collapseBtn.graphics.lineTo(cx + hw, s - 8); _collapseBtn.graphics.lineTo(cx, s - 4);
			}
			else
			{
				_collapseBtn.graphics.moveTo(cx - hw, 4); _collapseBtn.graphics.lineTo(cx + hw, 4); _collapseBtn.graphics.lineTo(cx, 4 + ch);
				_collapseBtn.graphics.moveTo(cx - hw, s - 4); _collapseBtn.graphics.lineTo(cx + hw, s - 4); _collapseBtn.graphics.lineTo(cx, s - 4 - ch);
			}

			_collapseBtn.graphics.endFill();
		}

		private function createColumnButton():void
		{
			_columnBtn = new Sprite();
			_columnBtn.y = 0;
			_columnBtn.buttonMode = true;
			_columnBtn.useHandCursor = true;
			_columnBtn.addEventListener(MouseEvent.CLICK, onColumnClick);
			_columnBtn.addEventListener(MouseEvent.ROLL_OVER, onColumnOver);
			_columnBtn.addEventListener(MouseEvent.ROLL_OUT, onColumnOut);
			addChild(_columnBtn);
			drawColumnIcon(_textColor);
		}

		private function drawColumnIcon(color:uint):void
		{
			var s:Number = Constants.TOOLBAR_COLLAPSE_BTN_SIZE;
			var bars:int = _multiMode ? 4 : 2;
			var bw:Number = 3;
			var gap:Number = 2;
			var totalW:Number = bars * bw + (bars - 1) * gap;
			var startX:Number = (s - totalW) / 2;
			var top:Number = 3;
			var h:Number = s - 6;

			_columnBtn.graphics.clear();
			_columnBtn.graphics.beginFill(0, 0);
			_columnBtn.graphics.drawRect(0, 0, s, s);
			_columnBtn.graphics.endFill();

			_columnBtn.graphics.beginFill(color, 1);
			for (var i:int = 0; i < bars; i++)
				_columnBtn.graphics.drawRect(startX + i * (bw + gap), top, bw, h);
			_columnBtn.graphics.endFill();
		}

		public function setColumnMode(multiMode:Boolean):void
		{
			_multiMode = multiMode;
			drawColumnIcon(_textColor);
		}

		public function setWidth(w:Number):void
		{
			if (_columnBtn != null)
				_columnBtn.x = w - Constants.TOOLBAR_COLLAPSE_BTN_SIZE - 4;
		}

		public function relayoutLetters():void
		{
			if (_letters == null)
				return;

			var slot:Number = LETTER_SLOT;
			var startX:Number = (Constants.MOD_COMPONENT_WIDTH - LETTERS.length * slot) / 2;

			for (var i:int = 0; i < LETTERS.length; i++)
			{
				var holder:MovieClip = MovieClip(_letters[LETTERS.charAt(i)]);
				if (holder == null)
					continue;

				var hx:Number = startX + i * slot;

				holder.scaleX = holder.scaleY = 1;
				holder.y = 0;
				holder.x = hx;
				holder["ox"] = hx;
				holder["slot"] = slot;

				var tf:TextField = TextField(holder["tf"]);
				if (tf != null)
					tf.width = slot;

				holder.graphics.clear();
				holder.graphics.beginFill(0, 0);
				holder.graphics.drawRect(0, 0, slot, Constants.TOOLBAR_HEIGHT);
				holder.graphics.endFill();
			}
		}

		private function onColumnClick(event:MouseEvent):void
		{
			dispatchEvent(new InteractiveEvent(InteractiveEvent.COLUMN_MODE_TOGGLE));
		}

		private function onColumnOver(event:MouseEvent):void
		{
			drawColumnIcon(COLOR_HOVER);
			Constants.playHoverSound();
		}

		private function onColumnOut(event:MouseEvent):void
		{
			drawColumnIcon(_textColor);
		}

		private function createLetters():void
		{
			var left:Number = Constants.TOOLBAR_LETTERS_LEFT;
			var slot:Number = LETTER_SLOT;

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

			relayoutLetters();
		}

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
			drawCollapseIcon(_textColor);
		}

		private function onCollapseClick(event:MouseEvent):void
		{
			dispatchEvent(new InteractiveEvent(InteractiveEvent.COLLAPSE_ALL, '', '', !_allCollapsed));
		}

		private function onCollapseOver(event:MouseEvent):void
		{
			drawCollapseIcon(COLOR_HOVER);
			Constants.playHoverSound();
		}

		private function onCollapseOut(event:MouseEvent):void
		{
			drawCollapseIcon(_textColor);
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
			Constants.playHoverSound();

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
