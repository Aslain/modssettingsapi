package poliroid.gui.lobby.modsSettings.shared
{
	import net.wg.gui.components.controls.CheckBox;
	import poliroid.gui.lobby.modsSettings.controls.ColorChoiceButton;

	public class CheckboxColorProxy
	{
		private var _checkbox:CheckBox;
		private var _colorChoice:ColorChoiceButton;

		public function CheckboxColorProxy(checkbox:CheckBox, colorChoice:ColorChoiceButton)
		{
			_checkbox = checkbox;
			_colorChoice = colorChoice;
		}

		public function get value():*
		{
			return {enabled: _checkbox.selected, color: _colorChoice.color};
		}
	}
}
