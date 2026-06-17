package poliroid.gui.lobby.modsSettings
{
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	import flash.utils.getQualifiedClassName;

	import scaleform.clik.events.InputEvent;
	import net.wg.infrastructure.base.AbstractView;

	import poliroid.gui.lobby.modsSettings.components.ModsSettingsComponent;
	import poliroid.gui.lobby.modsSettings.components.ModsSettingsToolbar;
	import poliroid.gui.lobby.modsSettings.components.ModsSettingsWindowBackground;
	import poliroid.gui.lobby.modsSettings.components.ModsSettingsWindowContent;
	import poliroid.gui.lobby.modsSettings.components.ModsSettingsWindowFooter;
	import poliroid.gui.lobby.modsSettings.components.ModsSettingsWindowHeader;
	import poliroid.gui.lobby.modsSettings.controls.ResetConfirmDialog;
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
		public var requestModReset:Function;
		public var closeView:Function;

		private var modsArray:Array;
		private var templates:Object;
		private var configChanged:Boolean = false;
		private var configChangedLinkages:Array;
		private var _toolbar:ModsSettingsToolbar;
		private var _lastJumpLetter:String = '';
		private var _lastJumpIndex:int = 0;
		private var _collapseSnapshot:Object = null;
		private var _ctrlDown:Boolean = false;
		private var _resetConfirm:ResetConfirmDialog;
		private var _confirmLinkage:String = null;
		private var _skipResetConfirm:Boolean = false;
		private var _appW:Number = 0;
		private var _appH:Number = 0;

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
			App.gameInputMgr.setKeyHandler(Keyboard.CONTROL, KeyboardEvent.KEY_DOWN, onCtrlKeyDownHandler, true);
			App.gameInputMgr.setKeyHandler(Keyboard.CONTROL, KeyboardEvent.KEY_UP, onCtrlKeyUpHandler, true);
			App.gameInputMgr.setKeyHandler(Keyboard.F, KeyboardEvent.KEY_DOWN, onFKeyDownHandler, true);

			header.addEventListener(InteractiveEvent.CLOSE_BUTTON_CLICK, handleCloseButtonClick);
			header.addEventListener(InteractiveEvent.SEARCH, handleSearch);

			content.addEventListener(InteractiveEvent.SETTINGS_CHANGED, handleModSettingsChanged);
			content.addEventListener(InteractiveEvent.BUTTON_CLICK, handleModSettingsButtonClick);
			content.addEventListener(InteractiveEvent.HOTKEY_ACTION, handleModSettingsHotkeyAction);
			content.addEventListener(InteractiveEvent.COLLAPSE_CHANGED, handleModCollapseChanged);
			content.addEventListener(InteractiveEvent.HEIGHT_CHANGED, handleModHeightChanged);
			content.addEventListener(InteractiveEvent.RESET_REQUESTED, handleModResetRequested);

			footer.addEventListener(InteractiveEvent.OK_BUTTON_CLICK, handleOkButtonClick);
			footer.addEventListener(InteractiveEvent.CANCEL_BUTTON_CLICK, handleCancelButtonClick);
			footer.addEventListener(InteractiveEvent.APPLY_BUTTON_CLICK, handleApplyButtonClick);

			_toolbar = new ModsSettingsToolbar();
			_toolbar.addEventListener(InteractiveEvent.COLLAPSE_ALL, handleCollapseAll);
			_toolbar.addEventListener(InteractiveEvent.JUMP_TO_LETTER, handleJumpToLetter);
			addChild(_toolbar);
			positionToolbar();

			_resetConfirm = new ResetConfirmDialog();
			_resetConfirm.addEventListener(InteractiveEvent.RESET_CONFIRMED, onResetConfirmed);
			addChild(_resetConfirm);

			requestModsData();
		}

		override protected function onDispose():void
		{
			App.gameInputMgr.clearKeyHandler(Keyboard.ESCAPE, KeyboardEvent.KEY_DOWN, onEscapeKeyDownHandler);
			App.gameInputMgr.clearKeyHandler(Keyboard.CONTROL, KeyboardEvent.KEY_DOWN, onCtrlKeyDownHandler);
			App.gameInputMgr.clearKeyHandler(Keyboard.CONTROL, KeyboardEvent.KEY_UP, onCtrlKeyUpHandler);
			App.gameInputMgr.clearKeyHandler(Keyboard.F, KeyboardEvent.KEY_DOWN, onFKeyDownHandler);
			App.toolTipMgr.hide();

			header.removeEventListener(InteractiveEvent.CLOSE_BUTTON_CLICK, handleCloseButtonClick);
			header.removeEventListener(InteractiveEvent.SEARCH, handleSearch);

			content.removeEventListener(InteractiveEvent.SETTINGS_CHANGED, handleModSettingsChanged);
			content.removeEventListener(InteractiveEvent.BUTTON_CLICK, handleModSettingsButtonClick);
			content.removeEventListener(InteractiveEvent.HOTKEY_ACTION, handleModSettingsHotkeyAction);
			content.removeEventListener(InteractiveEvent.COLLAPSE_CHANGED, handleModCollapseChanged);
			content.removeEventListener(InteractiveEvent.HEIGHT_CHANGED, handleModHeightChanged);
			content.removeEventListener(InteractiveEvent.RESET_REQUESTED, handleModResetRequested);

			footer.removeEventListener(InteractiveEvent.OK_BUTTON_CLICK, handleOkButtonClick);
			footer.removeEventListener(InteractiveEvent.CANCEL_BUTTON_CLICK, handleCancelButtonClick);
			footer.removeEventListener(InteractiveEvent.APPLY_BUTTON_CLICK, handleApplyButtonClick);

			if (_toolbar != null)
			{
				_toolbar.removeEventListener(InteractiveEvent.COLLAPSE_ALL, handleCollapseAll);
				_toolbar.removeEventListener(InteractiveEvent.JUMP_TO_LETTER, handleJumpToLetter);
				_toolbar = null;
			}

			if (_resetConfirm != null)
			{
				_resetConfirm.removeEventListener(InteractiveEvent.RESET_CONFIRMED, onResetConfirmed);
				_resetConfirm.dispose();
				_resetConfirm = null;
			}

			header = null;
			content = null;
			footer = null;
			background = null;

			super.onDispose();
		}

		override public function updateStage(width:Number, height:Number):void
		{
			_appW = width;
			_appH = height;

			header.updateStage(width, height);
			content.updateStage(width, height);
			footer.updateStage(width, height);
			background.updateStage(width, height);

			positionToolbar();

			if (_resetConfirm != null && _resetConfirm.visible)
				_resetConfirm.resize(width, height);
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

			_skipResetConfirm = vo.resetSkipConfirm;
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

		public function as_updateImage(linkage:String, varName:String, source:String, width:int, height:int, removeImage:Boolean = false, label:String = null):void
		{
			for each (var mod:ModsSettingsComponent in modsArray)
			{
				if (mod.modLinkage == linkage)
					mod.updateImage(varName, source, width, height, removeImage, label);
			}
		}

		public function as_updateImageAtlas(linkage:String, varName:String, atlasSrc:String, frameW:int, frameH:int, cols:int, count:int, fps:Number, loop:Boolean, width:int, height:int):void
		{
			for each (var mod:ModsSettingsComponent in modsArray)
			{
				if (mod.modLinkage == linkage)
					mod.updateImageAtlas(varName, atlasSrc, frameW, frameH, cols, count, fps, loop, width, height);
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

		public function as_resetMod(linkage:String, values:Object):void
		{
			for each (var mod:ModsSettingsComponent in modsArray)
			{
				if (mod.modLinkage == linkage)
				{
					mod.resetToValues(values);
					return;
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

			if (stage != null && stage.focus != null)
			{
				var fc:String = getQualifiedClassName(stage.focus);
				if (fc.indexOf('CheckBox') != -1 || fc.indexOf('Dropdown') != -1 || fc.indexOf('ModsSettingsComponent') != -1)
					stage.focus = this;
			}
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

		private function handleModHeightChanged(event:InteractiveEvent):void
		{
			content.reflowMods();
		}

		private function handleModResetRequested(event:InteractiveEvent):void
		{
			if (_skipResetConfirm || _resetConfirm == null)
			{
				if (requestModReset != null)
					requestModReset(event.linkage);
				return;
			}

			_confirmLinkage = event.linkage;

			var modName:String = '';
			for each (var mod:ModsSettingsComponent in modsArray)
			{
				if (mod.modLinkage == event.linkage)
				{
					if (mod.data != null && mod.data.modDisplayName != null)
						modName = String(mod.data.modDisplayName).replace(/<[^>]*>/g, '').replace(/^\s+|\s+$/g, '');
					break;
				}
			}

			var w:Number = (_appW > 0) ? _appW : (stage != null ? stage.stageWidth : 1920);
			var h:Number = (_appH > 0) ? _appH : (stage != null ? stage.stageHeight : 1080);
			_resetConfirm.open(modName, STRINGS.RESET_CONFIRM_MESSAGE, STRINGS.RESET_CONFIRM_SUBMIT, STRINGS.BUTTON_CANCEL, w, h);
		}

		private function onResetConfirmed(event:InteractiveEvent):void
		{
			if (requestModReset != null && _confirmLinkage != null)
				requestModReset(_confirmLinkage);
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
			if (_collapseSnapshot != null && header != null)
				header.clearSearch();

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

		private function handleSearch(event:InteractiveEvent):void
		{
			var query:String = (event.value == null) ? '' : String(event.value).toLowerCase();

			if (query.length == 0)
			{
				for each (var m:ModsSettingsComponent in modsArray)
				{
					if (m == null)
						continue;

					m.visible = true;

					if (_collapseSnapshot != null && _collapseSnapshot.hasOwnProperty(m.modLinkage))
						m.setCollapsed(Boolean(_collapseSnapshot[m.modLinkage]));
				}

				_collapseSnapshot = null;

				if (content != null)
				{
					content.reflowMods();
					content.scrollToTop();
				}

				return;
			}

			if (_collapseSnapshot == null)
			{
				_collapseSnapshot = new Object();

				for each (var s:ModsSettingsComponent in modsArray)
					if (s != null)
						_collapseSnapshot[s.modLinkage] = s.isCollapsed;
			}

			for each (var mod:ModsSettingsComponent in modsArray)
			{
				if (mod == null)
					continue;

				var name:String = (mod.data != null && mod.data.modDisplayName != null) ? String(mod.data.modDisplayName) : '';
				name = name.replace(/<[^>]*>/g, '').toLowerCase();

				var hit:Boolean = name.indexOf(query) != -1;
				mod.visible = hit;

				if (hit && mod.isCollapsed)
					mod.setCollapsed(false);
			}

			if (content != null)
			{
				content.reflowMods();
				content.scrollToTop();
			}
		}

		private function onEscapeKeyDownHandler(event:InputEvent):void
		{
			if (header != null && header.isSearchFocused())
				header.blurSearch();
			else
				closeView();
		}

		private function onCtrlKeyDownHandler(event:InputEvent):void
		{
			_ctrlDown = true;
		}

		private function onCtrlKeyUpHandler(event:InputEvent):void
		{
			_ctrlDown = false;
		}

		private function onFKeyDownHandler(event:InputEvent):void
		{
			if (_ctrlDown && header != null)
				header.focusSearch();
		}
	}
}
