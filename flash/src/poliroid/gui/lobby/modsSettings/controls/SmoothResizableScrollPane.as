
package poliroid.gui.lobby.modsSettings.controls
{
	import flash.events.Event;
	import flash.utils.getTimer;
	import scaleform.clik.constants.InvalidationType;
	import net.wg.gui.components.controls.events.ScrollBarEvent;
	import net.wg.gui.components.controls.events.ScrollPaneEvent;
	import net.wg.gui.components.controls.ResizableScrollPane;

	public class SmoothResizableScrollPane extends ResizableScrollPane
	{
		private var _smoothScrollPosition:Number = 0;
		private var _smoothScrollStepFactor:Number = 100;
		private var _smoothScrollDuration:Number = 1000;
		private var _restoreBottomPosition:Boolean = false;
		private var _scrollStartTime:Number = NaN;
		private var _scrollStartPosition:Number = NaN;
		private var _isScrolling:Boolean = false;
		private var _cachedMaxScroll:Number = NaN;

		override protected function configUI():void
		{
			super.configUI();

			addEventListener(ScrollPaneEvent.POSITION_CHANGED, onScrollPanePositionChange);
		}

		override protected function draw():void
		{
			super.draw();

			if(scrollBar && isInvalid(InvalidationType.SCROLL_BAR))
				scrollBar.addEventListener(ScrollBarEvent.ON_END_DRAG, onScrollBarEndDrag);
		}

		override protected function onDispose():void
		{
			App.utils.scheduler.cancelTask(normalizeTargetPosition);
			scrollBar.removeEventListener(ScrollBarEvent.ON_END_DRAG, onScrollBarEndDrag);
			removeEventListener(ScrollPaneEvent.POSITION_CHANGED, onScrollPanePositionChange);
			App.stage.removeEventListener(Event.ENTER_FRAME, _smoothScrollAnimation);

			super.onDispose();
		}

		override protected function applyScrollBarUpdating():void
		{
			super.applyScrollBarUpdating();

			scrollBar.setScrollProperties(scrollPageSize, 0, maxScroll, _smoothScrollStepFactor);
		}

		override protected function applyTargetChanges():void
		{
			super.applyTargetChanges();

			if (_smoothScrollPosition > maxScroll)
				_smoothScrollPosition = maxScroll;

			if (!_restoreBottomPosition)
				return;

			if (_smoothScrollPosition == _cachedMaxScroll)
				_smoothScrollPosition = scrollPosition = maxScroll;

			_cachedMaxScroll = maxScroll;
		}

		override public function doMouseWheel(value:int):void
		{
			if (!_isScrolling)
				_smoothScrollPosition = scrollPosition;
			var moveDelta = value > 0 ? _smoothScrollStepFactor : -_smoothScrollStepFactor;
			_smoothScrollPosition = Math.min(maxScroll, Math.max(0, smoothScrollPosition - moveDelta));
			_smoothScrollStart();
		}

		private function _smoothScrollStart():void
		{
			_scrollStartTime = getTimer();
			_scrollStartPosition = int(scrollPosition);

			if (!_isScrolling)
			{
				_isScrolling = true;
				_smoothScrollAnimation();
				App.stage.addEventListener(Event.ENTER_FRAME, _smoothScrollAnimation);
			}
		}

		private function _smoothScrollStop():void
		{
			if (scrollPosition == smoothScrollPosition && _isScrolling)
			{
				App.stage.removeEventListener(Event.ENTER_FRAME, _smoothScrollAnimation);
				_isScrolling = false;
			}
		}

		private function _smoothScrollAnimation():void
		{
			if (_smoothScrollPosition > maxScroll)
				_smoothScrollPosition = maxScroll;
			if (_smoothScrollPosition < 0)
				_smoothScrollPosition = 0;
			var animationTime:Number = (getTimer() - _scrollStartTime) / _smoothScrollDuration;
			var k = animationTime - 1;
			var animationCoeff:Number = k * k * k + 1;
			animationCoeff = Math.min(1, animationCoeff);
			scrollPosition = _scrollStartPosition + int((smoothScrollPosition - _scrollStartPosition) * animationCoeff);
			if (animationTime >= 1)
			{
				scrollPosition = _smoothScrollPosition;
				App.stage.removeEventListener(Event.ENTER_FRAME, _smoothScrollAnimation);
				_isScrolling = false;
				return;
			}
			_smoothScrollStop();
		}

		private function normalizeTargetPosition():void
		{
			if (target.y != int(target.y))
				target.y = int(target.y);
		}

		public function get smoothScrollDuration():Number
		{
			return _smoothScrollDuration;
		}

		public function set smoothScrollDuration(value:Number):void
		{
			_smoothScrollDuration = value;
		}

		public function get smoothScrollPosition():Number
		{
			return _smoothScrollPosition;
		}

		public function set smoothScrollPosition(value:Number):void
		{
			_smoothScrollPosition = value;
			scrollPosition = value;
		}

		public function get smoothScrollStepFactor():Number
		{
			return _smoothScrollStepFactor;
		}

		public function set smoothScrollStepFactor(value:Number):void
		{
			_smoothScrollStepFactor = value;
		}

		public function get restoreBottomPosition():Boolean
		{
			return _restoreBottomPosition;
		}

		public function set restoreBottomPosition(value:Boolean):void
		{
			_restoreBottomPosition = value;
		}

		private function onScrollPanePositionChange(event:ScrollPaneEvent):void
		{
			App.utils.scheduler.scheduleOnNextFrame(normalizeTargetPosition);
		}

		private function onScrollBarEndDrag(event:ScrollBarEvent):void
		{
			if (scrollBar)
				_smoothScrollPosition = int(scrollBar.position);
		}
	}
}
