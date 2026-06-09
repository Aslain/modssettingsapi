package poliroid.gui.lobby.modsSettings
{
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;

	import scaleform.clik.events.InputEvent;
	import net.wg.infrastructure.base.AbstractView;

	import poliroid.gui.lobby.modsSettings.components.ModsSettingsComponent;
	import poliroid.gui.lobby.modsSettings.components.ModsSettingsToolbar;
	import poliroid.gui.lobby.modsSettings.components.ModsSettingsWindowBackground;
	import poliroid.gui.lobby.modsSettings.components.ModsSettingsWindowContent;
	import poliroid.gui.lobby.modsSettings.components.ModsSettingsWindowFooter;
	import poliroid.gui.lobby.modsSettings.components.ModsSettingsWindowHeader;
	import poliroid.gui.lobby.modsSettings.data.HotkeyControlVO;
	import poliroid.gui.lobby.modsSettings.data.ModsSettingsLocalizationVO;
	import poliroid.gui.lobby.modsSettings.events.InteractiveEvent;
	import poliroid.gui.lobby.modsSettings.lang.STRINGS;
	import poliroid.gui.lobby.modsSettings.shared.Constants;

	public class ModsSettingsWindow extends AbstractView
	{
		public var header:ModsSettingsWindowHeader;
		public var content:ModsSettingsWindowContent;
		public var footer:ModsSettingsWindowFooter;
		public var background:ModsSettingsWindowBackground;

		public var requestModsData:Function;
		public var sendModsData:Function;
		public var componentChanged:Function;
		public var buttonAction:Function;
		public var hotkeyAction:Function;
		public var setModCollapsed:Function;
		public var closeView:Function;

		private var modsArray:Array;
		private var templates:Object;
		private var configChanged:Boolean = false;
		private var configChangedLinkages:Array;
		private var _toolbar:ModsSettingsToolbar;
		private var _lastJumpLetter:String = '';
		private var _lastJumpIndex:int = 0;

		public function ModsSettingsWindow():void
		{
			super();

			configChanged = false;
			configChangedLinkages = new Array();
			modsArray = new Array();
		}

		override protected function onPopulate():void
		{
			super.onPopulate();

			App.gameInputMgr.setKeyHandler(Keyboard.ESCAPE, KeyboardEvent.KEY_DOWN, onEscapeKeyDownHandler, true);

			header.addEventListener(InteractiveEvent.CLOSE_BUTTON_CLICK, handleCloseButtonClick);

			content.addEventListener(InteractiveEvent.SETTINGS_CHANGED, handleModSettingsChanged);
			content.addEventListener(InteractiveEvent.BUTTON_CLICK, handleModSettingsButtonClick);
			content.addEventListener(InteractiveEvent.HOTKEY_ACTION, handleModSettingsHotkeyAction);
			content.addEventListener(InteractiveEvent.COLLAPSE_CHANGED, handleModCollapseChanged);

			footer.addEventListener(InteractiveEvent.OK_BUTTON_CLICK, handleOkButtonClick);
			footer.addEventListener(InteractiveEvent.CANCEL_BUTTON_CLICK, handleCancelButtonClick);
			footer.addEventListener(InteractiveEvent.APPLY_BUTTON_CLICK, handleApplyButtonClick);

			_toolbar = new ModsSettingsToolbar();
			_toolbar.addEventListener(InteractiveEvent.COLLAPSE_ALL, handleCollapseAll);
			_toolbar.addEventListener(InteractiveEvent.JUMP_TO_LETTER, handleJumpToLetter);
			addChild(_toolbar);
			positionToolbar();

			requestModsData();
		}

		override protected function onDispose():void
		{
			App.gameInputMgr.clearKeyHandler(Keyboard.ESCAPE, KeyboardEvent.KEY_DOWN, onEscapeKeyDownHandler);
			App.toolTipMgr.hide();

			header.removeEventListener(InteractiveEvent.CLOSE_BUTTON_CLICK, handleCloseButtonClick);

			content.removeEventListener(InteractiveEvent.SETTINGS_CHANGED, handleModSettingsChanged);
			content.removeEventListener(InteractiveEvent.BUTTON_CLICK, handleModSettingsButtonClick);
			content.removeEventListener(InteractiveEvent.HOTKEY_ACTION, handleModSettingsHotkeyAction);
			content.removeEventListener(InteractiveEvent.COLLAPSE_CHANGED, handleModCollapseChanged);

			footer.removeEventListener(InteractiveEvent.OK_BUTTON_CLICK, handleOkButtonClick);
			footer.removeEventListener(InteractiveEvent.CANCEL_BUTTON_CLICK, handleCancelButtonClick);
			footer.removeEventListener(InteractiveEvent.APPLY_BUTTON_CLICK, handleApplyButtonClick);

			if (_toolbar != null)
			{
				_toolbar.removeEventListener(InteractiveEvent.COLLAPSE_ALL, handleCollapseAll);
				_toolbar.removeEventListener(InteractiveEvent.JUMP_TO_LETTER, handleJumpToLetter);
				_toolbar = null;
			}

			header = null;
			content = null;
			footer = null;
			background = null;

			super.onDispose();
		}

		override public function updateStage(width:Number, height:Number):void
		{
			header.updateStage(width, height);
			content.updateStage(width, height);
			footer.updateStage(width, height);
			background.updateStage(width, height);

			positionToolbar();
		}

		private function positionToolbar():void
		{
			if (_toolbar == null || content == null)
				return;

			// Top strip, horizontally aligned with the centred mods column, above the title
			_toolbar.x = content.x;
			_toolbar.y = 10;
		}

		public function as_setLocalization(l10n:Object):void
		{
			var vo:ModsSettingsLocalizationVO = new ModsSettingsLocalizationVO(l10n);

			header.setLocalization(vo);
			footer.setLocalization(vo);
			STRINGS.setLocalization(vo);
		}

		public function as_setData(data:Array):void
		{
			templates = data;

			for each (var template:Object in templates)
			{
				var mod:ModsSettingsComponent = content.addMod(template);

				modsArray.push(mod);
			}

			updateToolbarState();
		}

		public function as_setHotkeys(data:Object):void
		{
			for each (var mod:ModsSettingsComponent in modsArray)
			{
				var linkage:String = mod.modLinkage;

				if (data.hasOwnProperty(linkage))
				{
					for each (var component:Object in mod.components)
					{
						if (component.data.hasOwnProperty('varName') && component.data.varName in data[linkage])
						{
							var hotkeyData:Object = data[linkage][component.data.varName];
							var hotkeyControlVO:Object = new HotkeyControlVO(hotkeyData);

							component.componentObject['control'].setData(hotkeyControlVO);
						}
					}
				}
			}
		}

		public function as_updateImage(linkage:String, varName:String, source:String, width:int, height:int):void
		{
			for each (var mod:ModsSettingsComponent in modsArray)
			{
				if (mod.modLinkage == linkage)
					mod.updateImage(varName, source, width, height);
			}
		}

		public function as_reloadMod(linkage:String, template:Object):void
		{
			var newMod:ModsSettingsComponent = content.reloadMod(linkage, template);

			if (newMod == null)
				return;

			for (var i:int = 0; i < modsArray.length; i++)
			{
				if (ModsSettingsComponent(modsArray[i]).modLinkage == linkage)
				{
					modsArray[i] = newMod;
					break;
				}
			}
		}

		private function collectModsData():Object
		{
			var result:Object = new Object();

			for each (var mod:ModsSettingsComponent in modsArray)
			{
				var linkage:String = mod.modLinkage;

				if (configChangedLinkages.indexOf(linkage) != -1)
				{
					result[linkage] = mod.getConfigData();
				}
			}

			return result;
		}

		private function syncModsData():void
		{
			var config:Object = collectModsData();

			sendModsData(App.utils.JSON.encode(config));
		}

		private function handleModSettingsChanged(event:InteractiveEvent):void
		{
			configChanged = true;
			footer.applyButton.enabled = true;

			if (configChangedLinkages.indexOf(event.linkage) == -1)
				configChangedLinkages.push(event.linkage);

			notifyLiveChange(event.linkage);
		}

		private function notifyLiveChange(linkage:String):void
		{
			// Push the changed mod's current (uncommitted) values to Python so
			// it can update live previews immediately, before Apply is pressed.
			if (componentChanged == null)
				return;

			for each (var mod:ModsSettingsComponent in modsArray)
			{
				if (mod.modLinkage == linkage)
				{
					var data:Object = new Object();
					data[linkage] = mod.getConfigData();
					componentChanged(App.utils.JSON.encode(data));
					return;
				}
			}
		}

		private function handleModSettingsButtonClick(event:InteractiveEvent):void
		{
			buttonAction(event.linkage, event.varName, event.value);
		}

		private function handleModCollapseChanged(event:InteractiveEvent):void
		{
			content.reflowMods();

			if (setModCollapsed != null)
				setModCollapsed(event.linkage, event.value);

			refreshCollapseAllIcon();
		}

		private function handleCollapseAll(event:InteractiveEvent):void
		{
			setAllCollapsed(Boolean(event.value));
		}

		private function setAllCollapsed(value:Boolean):void
		{
			for each (var mod:ModsSettingsComponent in modsArray)
			{
				mod.setCollapsed(value);

				if (setModCollapsed != null)
					setModCollapsed(mod.modLinkage, value);
			}

			content.reflowMods();

			if (_toolbar != null)
				_toolbar.setCollapseState(value);
		}

		private function handleJumpToLetter(event:InteractiveEvent):void
		{
			var matches:Array = new Array();

			for each (var mod:ModsSettingsComponent in modsArray)
			{
				if (modInitial(mod) == event.varName)
					matches.push(mod);
			}

			if (matches.length == 0)
				return;

			// Repeated clicks on the same letter cycle through its mods (wrapping);
			// a different letter restarts at its first mod.
			if (event.varName == _lastJumpLetter)
				_lastJumpIndex = (_lastJumpIndex + 1) % matches.length;
			else
			{
				_lastJumpLetter = event.varName;
				_lastJumpIndex = 0;
			}

			var target:ModsSettingsComponent = ModsSettingsComponent(matches[_lastJumpIndex]);

			var changed:Boolean = false;

			for each (var m:ModsSettingsComponent in matches)
			{
				if (m.isCollapsed)
				{
					m.setCollapsed(false);

					if (setModCollapsed != null)
						setModCollapsed(m.modLinkage, false);

					changed = true;
				}
			}

			if (changed)
			{
				content.reflowMods();
				refreshCollapseAllIcon();
			}

			content.scrollToMod(target);
		}

		private function modInitial(mod:ModsSettingsComponent):String
		{
			if (mod == null || mod.data == null || mod.data.modDisplayName == null)
				return '';

			var name:String = String(mod.data.modDisplayName);
			name = name.replace(/<[^>]*>/g, '');
			name = name.replace(/^[^0-9A-Za-z]+/, '');

			if (name.length == 0)
				return '';

			return name.charAt(0).toUpperCase();
		}

		private function updateToolbarState():void
		{
			if (_toolbar == null)
				return;

			var available:Object = new Object();

			for each (var mod:ModsSettingsComponent in modsArray)
			{
				var initial:String = modInitial(mod);

				if (initial.length == 1)
					available[initial] = true;
			}

			_toolbar.setAvailableLetters(available);
			refreshCollapseAllIcon();
		}

		private function refreshCollapseAllIcon():void
		{
			if (_toolbar == null)
				return;

			var allCollapsed:Boolean = modsArray.length > 0;

			for each (var mod:ModsSettingsComponent in modsArray)
				if (!mod.isCollapsed)
					allCollapsed = false;

			_toolbar.setCollapseState(allCollapsed);
		}

		private function handleModSettingsHotkeyAction(event:InteractiveEvent):void
		{
			hotkeyAction(event.linkage, event.varName, event.value);
		}

		private function handleOkButtonClick(event:InteractiveEvent):void
		{
			if (configChanged)
				syncModsData();

			closeView();
		}

		private function handleApplyButtonClick(event:InteractiveEvent):void
		{
			syncModsData();
			configChanged = false;
			footer.applyButton.enabled = false;
		}

		private function handleCancelButtonClick(event:InteractiveEvent):void
		{
			closeView();
		}

		private function handleCloseButtonClick(event:InteractiveEvent):void
		{
			closeView();
		}

		private function onEscapeKeyDownHandler(event:InputEvent):void
		{
			closeView();
		}
	}
}
