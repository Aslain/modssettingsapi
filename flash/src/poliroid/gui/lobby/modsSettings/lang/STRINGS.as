package poliroid.gui.lobby.modsSettings.lang
{
	import poliroid.gui.lobby.modsSettings.data.ModsSettingsLocalizationVO;

	public class STRINGS extends Object
	{
		public static var WINDOW_TITLE:String = "WINDOW_TITLE";
		public static var BUTTON_APPLY:String = "BUTTON_APPLY";
		public static var BUTTON_OK:String = "BUTTON_OK";
		public static var BUTTON_CANCEL:String = "BUTTON_CANCEL";
		public static var BUTTON_CLOSE:String = "BUTTON_CLOSE";
		public static var BUTTON_ENABLED_TOOLTIP:String = "BUTTON_ENABLED_TOOLTIP";
		public static var BUTTON_RESET_TOOLTIP:String = "BUTTON_RESET_TOOLTIP";
		public static var RESET_CONFIRM_TITLE:String = "RESET_CONFIRM_TITLE";
		public static var RESET_CONFIRM_MESSAGE:String = "RESET_CONFIRM_MESSAGE";
		public static var RESET_CONFIRM_SUBMIT:String = "RESET_CONFIRM_SUBMIT";
		public static var POPUP_COLOR:String = "POPUP_COLOR";
		public static var SEARCH_HITS:String = "";

		public function STRINGS():void
		{
			super();
		}

		public static function setLocalization(vo:ModsSettingsLocalizationVO):void
		{
			WINDOW_TITLE = vo.windowTitle;
			BUTTON_APPLY = vo.buttonApply;
			BUTTON_OK = vo.buttonOK;
			BUTTON_CANCEL = vo.buttonCancel;
			BUTTON_CLOSE = vo.buttonClose;
			BUTTON_ENABLED_TOOLTIP = vo.stateTooltip;
			BUTTON_RESET_TOOLTIP = vo.resetTooltip;
			RESET_CONFIRM_TITLE = vo.resetConfirmTitle;
			RESET_CONFIRM_MESSAGE = vo.resetConfirmMessage;
			RESET_CONFIRM_SUBMIT = vo.resetConfirmSubmit;
			POPUP_COLOR = vo.popupColor;
			SEARCH_HITS = vo.searchHits;
		}
	}
}
