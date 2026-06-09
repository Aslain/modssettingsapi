package poliroid.gui.lobby.modsSettings.shared
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.geom.ColorTransform;

	public class HoverBrightener
	{
		private static const SPEED:Number = 0.3;

		private var _target:DisplayObject;
		private var _max:Number;
		private var _value:Number = 0;
		private var _goal:Number = 0;

		public function HoverBrightener(target:DisplayObject, max:Number)
		{
			_target = target;
			_max = max;
		}

		public function set on(value:Boolean):void
		{
			_goal = value ? _max : 0;

			if (_target != null && !_target.hasEventListener(Event.ENTER_FRAME))
				_target.addEventListener(Event.ENTER_FRAME, onTick);
		}

		private function onTick(event:Event):void
		{
			_value += (_goal - _value) * SPEED;

			if (Math.abs(_goal - _value) < 0.5)
			{
				_value = _goal;
				_target.removeEventListener(Event.ENTER_FRAME, onTick);
			}

			var ct:ColorTransform = new ColorTransform();
			ct.redOffset = _value;
			ct.greenOffset = _value;
			ct.blueOffset = _value;
			_target.transform.colorTransform = ct;
		}
	}
}
