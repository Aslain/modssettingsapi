package poliroid.gui.lobby.modsSettings.controls
{
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import scaleform.clik.constants.InvalidationType;
	import net.wg.gui.components.controls.SoundButtonEx;
	import net.wg.gui.components.popovers.PopOverConst;
	import net.wg.gui.interfaces.ISoundButtonEx;
	import poliroid.gui.lobby.modsSettings.controls.ColorChoicePopup;
	import poliroid.gui.lobby.modsSettings.events.InteractiveEvent;
	import poliroid.gui.lobby.modsSettings.shared.Constants;

	public class ColorChoiceButton extends SoundButtonEx implements ISoundButtonEx
	{
		private static const POPUP_BOTTOM_MARGIN:int = 46;

		public var hitAreaA:MovieClip;
		public var colorFill:MovieClip;

		public var contextLinkage:String = null;
		public var contextVarName:String = null;

		private var _color:String;
		private var _presets:Array = null;
		private var _presetsOnly:Boolean = false;

		public function ColorChoiceButton()
		{
			super();
		}

		override protected function configUI():void
		{
			preventAutosizing = true;

			super.configUI();
		}

		override protected function draw():void
		{
			super.draw();

			if (isInvalid(InvalidationType.DATA))
			{
				colorFill.graphics.clear();
				colorFill.graphics.beginFill(parseInt(_color, 16));
				colorFill.graphics.drawRect(0, 0, 10, 10);
				colorFill.graphics.endFill();
			}
		}

		override protected function onMouseDownHandler(event:MouseEvent):void
		{
			super.onMouseDownHandler(event);

			if (App.utils.commons.isLeftButton(event))
			{
				var popup:ColorChoicePopup = App.utils.classFactory.getComponent('ColorChoicePopupUI', ColorChoicePopup);

				popup.color = color;
				popup.presetsOnly = _presetsOnly;
				popup.presets = _presets;
				popup.arrowDirection = getPopupArrowDirection(popup);
				popup.position = getPopupPosition(popup);
				popup.onValueChanged = onValueChanged;
				popup.show();
			}
			else if (App.utils.commons.isRightButton(event) && contextLinkage != null && contextVarName != null)
			{
				App.contextMenuMgr.show(Constants.COLOR_VALUE_CONTEXT_MENU_HANDLER, this,
					{'linkage': contextLinkage, 'varName': contextVarName, 'value': (_color != null ? _color : '')});
			}
		}

		private function getPopupArrowDirection(popup:ColorChoicePopup):int
		{
			var globalPos:Point = localToGlobal(new Point());
			var globalPosY:int = globalPos.y / App.appScale >> 0;
			var bottomOffset:int = globalPosY + popup.hitAreaA.height + POPUP_BOTTOM_MARGIN;

			if (bottomOffset < App.appHeight)
			{
				return PopOverConst.ARROW_TOP;
			}

			return PopOverConst.ARROW_BOTTOM;
		}

		private function getPopupPosition(popup:ColorChoicePopup):Point
		{
			var globalPos:Point = localToGlobal(new Point());
			var globalPosX:int = globalPos.x / App.appScale >> 0;
			var globalPosY:int = globalPos.y / App.appScale >> 0;
			var bottomOffset:int = globalPosY + popup.hitAreaA.height + POPUP_BOTTOM_MARGIN;

			globalPosX += width >> 1;
			globalPosX -= popup.hitAreaA.width >> 1;
			globalPosX += 1;

			if (bottomOffset < App.appHeight)
			{
				globalPosY += height;
				globalPosY += 15;
			}
			else
			{
				globalPosY -= popup.hitAreaA.height;
				globalPosY -= height;
				globalPosY += 8;
			}

			return new Point(globalPosX, globalPosY);
		}

		public function onValueChanged(newColor:String):void
		{
			color = newColor;
			dispatchEvent(new InteractiveEvent(InteractiveEvent.VALUE_CHANGED));
		}

		public function set color(newColor:String):void
		{
			_color = newColor;
			invalidateData();
		}

		public function get color():String
		{
			return _color;
		}

		public function set presets(value:Array):void
		{
			_presets = value;
		}

		public function get presets():Array
		{
			return _presets;
		}

		public function set presetsOnly(value:Boolean):void
		{
			_presetsOnly = value;
		}

		public function get presetsOnly():Boolean
		{
			return _presetsOnly;
		}
	}
}
