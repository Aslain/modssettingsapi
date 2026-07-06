package poliroid.gui.lobby.modsSettings.shared
{

	public class Constants extends Object
	{
		public static const WINDOW_BACKGROUND_IMAGE:String = '../../gui/maps/uiKit/dialogs/noize_bg.png';

		public static const COLUMN_WIDTH:Number = 450;

		public static var columnCount:int = 2;
		public static var MOD_COMPONENT_WIDTH:Number = 900;

		public static var multiColumnMode:Boolean = false;

		public static function updateForWidth(appWidth:Number, maxModColumns:int = 2):void
		{
			var n:int = 2;
			if (multiColumnMode)
			{
				var afford:int = (appWidth >= 1850) ? 4 : ((appWidth >= 1400) ? 3 : 2);
				n = (afford < maxModColumns) ? afford : maxModColumns;
			}
			if (n < 2)
				n = 2;
			columnCount = n;
			MOD_COMPONENT_WIDTH = n * COLUMN_WIDTH;
		}

		public static const COMPONENT_HEADER_MARGIN:Number = 20;
		public static const COMPONENT_MARGIN_BOTTOM:Number = 10;

		public static const RADIO_BUTTONS_MARGIN:Number = 22;
		public static const RADIO_HEADER_MARGIN:Number = 24;

		public static const MOD_PADDING_TOP:Number = 20;
		public static const MOD_PADDING_BOTTOM:Number = 20;
		public static const MOD_PADDING_LEFT:Number = 20;
		public static const MOD_MARGIN_BOTTOM:Number = 5;

		public static const MOD_CHILD_INDENT:Number = 30;
		public static const MOD_COLLAPSE_ARROW_SIZE:Number = 12;
		public static const MOD_COLLAPSED_HEIGHT:Number = 52;
		public static const TOOLBAR_HEIGHT:Number = 22;
		public static const TOOLBAR_COLLAPSE_BTN_SIZE:Number = 20;
		public static const TOOLBAR_LETTERS_LEFT:Number = 36;
		public static const TOOLBAR_TEXT_COLOR:uint = 0xE2D2A8;
		public static const HOVER_BRIGHTEN:Number = 40;
		public static const MOD_TITLE_INDENT:String = "    ";

		public static const EMPTY_COMPONENT_HEIGHT:Number = 20;

		public static const SLIDER_VALUE_KEY:String = "{{value}}";
		public static const SLIDER_VALUE_MARGIN:Number = 10;

		public static const BUTTON_MARGIN_LEFT:Number = 10;

		public static const COMPONENT_RETURN_VALUE_KEY:String = "returnValue";

		public static const MAX_BOTTOM_OFFSET:int = 230;

		public static const HOTKEY_CONTEXT_MENU_HANDLER:String = 'aslainMenuHotkeyContextMenuHandler';

		public static const PRESET_CONTEXT_MENU_HANDLER:String = 'aslainMenuPresetContextMenuHandler';

		public static const COLOR_VALUE_CONTEXT_MENU_HANDLER:String = 'aslainMenuColorValueContextMenuHandler';

		public static const NEW_FEATURE_CONTEXT_MENU_HANDLER:String = 'aslainMenuNewFeatureContextMenuHandler';

		public static const NEW_COUNTERS_CONTAINER:String = 'aslainMenuNewCounters';
		public static const NEW_FEATURE_LINE_LINKAGE:String = 'NewCounterLineUI';
		public static const NEW_FEATURE_BADGE_LINKAGE:String = 'CounterUI';

		public function Constants()
		{
			super();
		}
	}
}
