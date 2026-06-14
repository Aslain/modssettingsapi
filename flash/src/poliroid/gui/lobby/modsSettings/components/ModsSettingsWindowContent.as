package poliroid.gui.lobby.modsSettings.components
{
	import flash.display.MovieClip;
	import flash.events.Event;
	import net.wg.infrastructure.base.UIComponentEx;
	import net.wg.gui.components.controls.ScrollBar;
	import poliroid.gui.lobby.modsSettings.controls.SmoothResizableScrollPane;
	import poliroid.gui.lobby.modsSettings.shared.Constants;

	public class ModsSettingsWindowContent extends UIComponentEx
	{
		public var scrollPane:SmoothResizableScrollPane;
		public var scrollBar:ScrollBar;
		public var container:MovieClip;
		public var background:MovieClip;

		private var _settledHeight:Number = NaN;

		public function ModsSettingsWindowContent()
		{
			super();

			container = new MovieClip();
		}

		override protected function configUI():void
		{
			super.configUI();

			scrollPane.scrollBar = scrollBar;
			scrollPane.target = container;
			scrollPane.smoothScrollStepFactor = 150;
			scrollPane.smoothScrollDuration = 500;
		}

		override protected function onDispose():void
		{
			App.utils.scheduler.cancelTask(settleReflow);
			scrollPane.dispose();
			scrollBar.dispose();
			scrollPane = null;
			scrollBar = null;
			container = null;

			super.onDispose();
		}

		public function updateStage(appWidth:Number, appHeight:Number):void
		{
			scrollPane.setSize(Constants.MOD_COMPONENT_WIDTH, appHeight - 200);

			x = int((appWidth - Constants.MOD_COMPONENT_WIDTH) / 2);
			y = 100;

			scrollBar.height = int(appHeight - 204);
			scrollBar.x = Constants.MOD_COMPONENT_WIDTH;

			background.width = Constants.MOD_COMPONENT_WIDTH + 200;
			background.height = int(appHeight - 200);
		}

		public function addMod(template:Object):ModsSettingsComponent
		{
			var linkage:String = template.linkage;
			var renderer:ModsSettingsComponent = new ModsSettingsComponent(linkage);
			var targetPosition:int = 0;

			renderer.setData(template);
			renderer.validateNow();

			for (var i:int = 0; i < container.numChildren; i++)
			{
				var child:ModsSettingsComponent = container.getChildAt(i) as ModsSettingsComponent;
				var nextRendererPosition:int = child.y + child.height + Constants.MOD_MARGIN_BOTTOM;

				targetPosition = Math.max(targetPosition, nextRendererPosition);
			}

			renderer.y = targetPosition;
			container.addChild(renderer);

			return renderer;
		}

		public function reloadMod(linkage:String, template:Object):ModsSettingsComponent
		{
			var oldRenderer:ModsSettingsComponent = null;
			var idx:int = -1;

			for (var i:int = 0; i < container.numChildren; i++)
			{
				var child:ModsSettingsComponent = container.getChildAt(i) as ModsSettingsComponent;

				if (child != null && child.modLinkage == linkage)
				{
					oldRenderer = child;
					idx = i;
					break;
				}
			}

			if (oldRenderer == null)
				return null;

			// In-place first: keep the component + reuse unchanged controls, swap only the
			// rows that changed. Avoids destroying/recreating the whole mod (the re-render
			// flash). applyTemplate runs its own reflow via HEIGHT_CHANGED. Falls through to
			// a full rebuild only for structural changes it can't reconcile.
			if (oldRenderer.applyTemplate(template))
				return oldRenderer;

			var renderer:ModsSettingsComponent = new ModsSettingsComponent(linkage);

			renderer.setData(template);

			container.removeChild(oldRenderer);
			container.addChildAt(renderer, idx);

			// On stage now: re-measure hotkey labels before the reflow so wrapped labels get
			// their true height the first time.
			renderer.revalidateHotkeys();
			renderer.validateNow();

			reflowMods();

			return renderer;
		}

		public function scrollToMod(mod:ModsSettingsComponent):void
		{
			if (mod == null || scrollPane == null)
				return;

			var pos:Number = Math.max(0, Math.min(mod.y, scrollPane.maxScroll));
			scrollPane.smoothScrollPosition = pos;
		}

		public function reflowMods():void
		{
			var pos:int = 0;
			var lastBottom:int = 0;

			for (var i:int = 0; i < container.numChildren; i++)
			{
				var child:ModsSettingsComponent = container.getChildAt(i) as ModsSettingsComponent;

				if (child == null)
					continue;

				child.y = pos;
				lastBottom = child.y + child.height;
				pos = lastBottom + Constants.MOD_MARGIN_BOTTOM;
			}

			container.graphics.clear();
			container.graphics.beginFill(0, 0);
			container.graphics.drawRect(0, 0, 1, lastBottom);
			container.graphics.endFill();

			if (container != null)
				container.dispatchEvent(new Event(Event.RESIZE));

			_settledHeight = (container != null) ? container.height : NaN;
			App.utils.scheduler.scheduleOnNextFrame(settleReflow);
		}

		private function settleReflow():void
		{
			if (container == null)
				return;
			if (container.height != _settledHeight)
				reflowMods();
		}
	}
}
