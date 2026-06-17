package poliroid.gui.lobby.modsSettings.controls
{
	import flash.display.GradientType;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.text.TextField;
	import flash.text.TextFormat;

	import scaleform.clik.events.ButtonEvent;
	import net.wg.gui.components.controls.SoundButtonEx;

	import poliroid.gui.lobby.modsSettings.events.InteractiveEvent;
	import poliroid.gui.lobby.modsSettings.shared.Constants;

	public class ResetConfirmDialog extends Sprite
	{
		private static const PANEL_W:Number = 380;
		private static const TEXT_PAD:Number = 24;
		private static const TOP_MARGIN:Number = 26;
		private static const NAME_MSG_GAP:Number = 12;
		private static const MSG_BTN_GAP:Number = 22;
		private static const BOTTOM_PAD:Number = 20;
		private static const BTN_GAP:Number = 16;

		private static const NAME_COLOR:uint = 0xF3EBCE;
		private static const BODY_COLOR:uint = 0xD8D2C8;
		private static const GOLD:uint = Constants.TOOLBAR_TEXT_COLOR;
		private static const TEXT_SIZE:int = 18;

		private var _backdrop:Sprite;
		private var _panel:Sprite;
		private var _frame:Sprite;
		private var _nameTF:TextField;
		private var _messageTF:TextField;
		private var _resetBtn:SoundButtonEx;
		private var _cancelBtn:SoundButtonEx;
		private var _panelH:Number = 140;

		public function ResetConfirmDialog()
		{
			super();
			visible = false;

			_backdrop = new Sprite();
			_backdrop.addEventListener(MouseEvent.CLICK, eat);
			_backdrop.addEventListener(MouseEvent.MOUSE_WHEEL, eat);
			addChild(_backdrop);

			_panel = new Sprite();
			addChild(_panel);

			_frame = new Sprite();
			_panel.addChild(_frame);

			_nameTF = createTF(NAME_COLOR);
			_panel.addChild(_nameTF);

			_messageTF = createTF(BODY_COLOR);
			_panel.addChild(_messageTF);

			_resetBtn = createButton('ButtonAttentionLargeUI', onResetClick);
			_cancelBtn = createButton('ButtonSecondaryLargeUI', onCancelClick);
		}

		private function createTF(color:uint):TextField
		{
			var tf:TextField = new TextField();
			tf.selectable = false;
			tf.mouseEnabled = false;
			tf.multiline = true;
			tf.wordWrap = true;
			tf.width = PANEL_W - TEXT_PAD * 2;

			var fmt:TextFormat = new TextFormat();
			fmt.font = '$FieldFont';
			fmt.size = TEXT_SIZE;
			fmt.color = color;
			fmt.align = 'center';
			tf.defaultTextFormat = fmt;

			return tf;
		}

		private function createButton(linkage:String, handler:Function):SoundButtonEx
		{
			var b:SoundButtonEx = SoundButtonEx(App.utils.classFactory.getComponent(linkage, SoundButtonEx));
			b.addEventListener(ButtonEvent.CLICK, handler);
			_panel.addChild(b);
			b.validateNow();
			return b;
		}

		public function open(modName:String, message:String, resetLabel:String, cancelLabel:String, stageW:Number, stageH:Number):void
		{
			var hasName:Boolean = modName != null && modName.length > 0;
			_nameTF.visible = hasName;
			_nameTF.text = hasName ? modName : '';
			_messageTF.text = (message == null) ? '' : message;

			_resetBtn.label = resetLabel;
			_cancelBtn.label = cancelLabel;
			_resetBtn.validateNow();
			_cancelBtn.validateNow();

			_panelH = TOP_MARGIN + blockHeight() + MSG_BTN_GAP + buttonHeight() + BOTTOM_PAD;

			resize(stageW, stageH);
			visible = true;
		}

		private function blockHeight():Number
		{
			var h:Number = _messageTF.textHeight;
			if (_nameTF.visible)
				h += _nameTF.textHeight + NAME_MSG_GAP;
			return Math.max(h, 22);
		}

		private function buttonHeight():Number
		{
			return (_resetBtn != null && _resetBtn.height > 0) ? _resetBtn.height : 40;
		}

		public function resize(stageW:Number, stageH:Number):void
		{
			_backdrop.graphics.clear();
			_backdrop.graphics.beginFill(0x000000, 0.6);
			_backdrop.graphics.drawRect(0, 0, Math.max(stageW, 1), Math.max(stageH, 1));
			_backdrop.graphics.endFill();

			_panel.x = Math.round((stageW - PANEL_W) / 2);
			_panel.y = Math.round((stageH - _panelH) / 2);

			drawFrame();

			var btnH:Number = buttonHeight();
			var buttonY:Number = _panelH - BOTTOM_PAD - btnH;

			var blockTop:Number = Math.round((buttonY - blockHeight()) / 2);
			if (_nameTF.visible)
			{
				_nameTF.x = TEXT_PAD;
				_nameTF.y = blockTop;
				_messageTF.x = TEXT_PAD;
				_messageTF.y = blockTop + _nameTF.textHeight + NAME_MSG_GAP;
			}
			else
			{
				_messageTF.x = TEXT_PAD;
				_messageTF.y = blockTop;
			}

			var groupW:Number = _resetBtn.width + BTN_GAP + _cancelBtn.width;
			var groupX:Number = Math.round((PANEL_W - groupW) / 2);
			_resetBtn.x = groupX;
			_resetBtn.y = buttonY;
			_cancelBtn.x = groupX + _resetBtn.width + BTN_GAP;
			_cancelBtn.y = buttonY;
		}

		private function drawFrame():void
		{
			_frame.graphics.clear();

			var m:Matrix = new Matrix();
			m.createGradientBox(PANEL_W, _panelH, Math.PI / 2, 0, 0);
			_frame.graphics.beginGradientFill(GradientType.LINEAR, [0x2B2A25, 0x16150F], [0.98, 0.98], [0, 255], m);
			_frame.graphics.drawRect(0, 0, PANEL_W, _panelH);
			_frame.graphics.endFill();

			_frame.graphics.lineStyle(1, 0x000000, 0.6);
			_frame.graphics.drawRect(0, 0, PANEL_W, _panelH);
			_frame.graphics.lineStyle(1, GOLD, 0.30);
			_frame.graphics.drawRect(1, 1, PANEL_W - 2, _panelH - 2);
		}

		public function dispose():void
		{
			if (_backdrop != null)
			{
				_backdrop.removeEventListener(MouseEvent.CLICK, eat);
				_backdrop.removeEventListener(MouseEvent.MOUSE_WHEEL, eat);
			}

			if (_resetBtn != null)
			{
				_resetBtn.removeEventListener(ButtonEvent.CLICK, onResetClick);
				_resetBtn.dispose();
				_resetBtn = null;
			}

			if (_cancelBtn != null)
			{
				_cancelBtn.removeEventListener(ButtonEvent.CLICK, onCancelClick);
				_cancelBtn.dispose();
				_cancelBtn = null;
			}
		}

		public function close():void
		{
			visible = false;
		}

		private function onResetClick(event:ButtonEvent):void
		{
			close();
			dispatchEvent(new InteractiveEvent(InteractiveEvent.RESET_CONFIRMED));
		}

		private function onCancelClick(event:ButtonEvent):void
		{
			close();
		}

		private function eat(event:MouseEvent):void
		{
			event.stopImmediatePropagation();
		}
	}
}
