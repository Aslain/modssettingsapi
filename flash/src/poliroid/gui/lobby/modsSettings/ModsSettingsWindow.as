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
	import poliroid.gui.lobby.modsSettings.controls.ColorChoiceButton;
	import poliroid.gui.lobby.modsSettings.controls.ColorChoicePopup;
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
		public var markFeatureSeen:Function;
		public var saveUserColorPresets:Function;
		public var saveScrollPosition:Function;
		public var saveMultiColumnMode:Function;
		public var replayLiveImages:Function;
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
		private var _maxModColumns:int = 2;
		private var _lastColumnCount:int = 0;
		private var _forceColumnRebuild:Boolean = false;
		private var _pendingScroll:Number = 0;
		private var _pendingScrollTries:int = 0;
		private var _baseline:Object = new Object();
		private var _changedCounts:Object = new Object();

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
			content.addEventListener(InteractiveEvent.FEATURE_SEEN, handleFeatureSeen);

			footer.addEventListener(InteractiveEvent.OK_BUTTON_CLICK, handleOkButtonClick);
			footer.addEventListener(InteractiveEvent.CANCEL_BUTTON_CLICK, handleCancelButtonClick);
			footer.addEventListener(InteractiveEvent.APPLY_BUTTON_CLICK, handleApplyButtonClick);

			_toolbar = new ModsSettingsToolbar();
			_toolbar.addEventListener(InteractiveEvent.COLLAPSE_ALL, handleCollapseAll);
			_toolbar.addEventListener(InteractiveEvent.JUMP_TO_LETTER, handleJumpToLetter);
			_toolbar.addEventListener(InteractiveEvent.COLUMN_MODE_TOGGLE, handleColumnModeToggle);
			_toolbar.setColumnMode(Constants.multiColumnMode);
			addChild(_toolbar);
			positionToolbar();

			_resetConfirm = new ResetConfirmDialog();
			_resetConfirm.addEventListener(InteractiveEvent.RESET_CONFIRMED, onResetConfirmed);
			addChild(_resetConfirm);

			ColorChoicePopup.saveHandler = onUserPresetsSave;

			requestModsData();
		}

		override protected function onDispose():void
		{
			App.utils.scheduler.cancelTask(applyPendingScroll);
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
			content.removeEventListener(InteractiveEvent.FEATURE_SEEN, handleFeatureSeen);

			footer.removeEventListener(InteractiveEvent.OK_BUTTON_CLICK, handleOkButtonClick);
			footer.removeEventListener(InteractiveEvent.CANCEL_BUTTON_CLICK, handleCancelButtonClick);
			footer.removeEventListener(InteractiveEvent.APPLY_BUTTON_CLICK, handleApplyButtonClick);

			if (_toolbar != null)
			{
				_toolbar.removeEventListener(InteractiveEvent.COLLAPSE_ALL, handleCollapseAll);
				_toolbar.removeEventListener(InteractiveEvent.JUMP_TO_LETTER, handleJumpToLetter);
				_toolbar.removeEventListener(InteractiveEvent.COLUMN_MODE_TOGGLE, handleColumnModeToggle);
				_toolbar = null;
			}

			if (_resetConfirm != null)
			{
				_resetConfirm.removeEventListener(InteractiveEvent.RESET_CONFIRMED, onResetConfirmed);
				_resetConfirm.dispose();
				_resetConfirm = null;
			}

			ColorChoicePopup.saveHandler = null;

			try
			{
				App.utils.counterManager.disposeCountersForContainer(Constants.NEW_COUNTERS_CONTAINER);
			}
			catch (err:Error)
			{
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

			Constants.updateForWidth(width, _maxModColumns);

			header.updateStage(width, height);
			content.updateStage(width, height);
			footer.updateStage(width, height);
			background.updateStage(width, height);

			positionToolbar();

			if (Constants.columnCount != _lastColumnCount || _forceColumnRebuild)
			{
				_forceColumnRebuild = false;
				_lastColumnCount = Constants.columnCount;
				rebuildModsForColumnCount();
			}

			if (_resetConfirm != null && _resetConfirm.visible)
				_resetConfirm.resize(width, height);
		}

		private function positionToolbar():void
		{
			if (_toolbar == null || content == null)
				return;

			_toolbar.x = content.x;
			_toolbar.y = 10;
			_toolbar.setWidth(Constants.MOD_COMPONENT_WIDTH);
			_toolbar.relayoutLetters();
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

			_maxModColumns = 2;
			for each (var t:Object in templates)
			{
				var layoutT:Object = (t.multiColumnTemplate != null) ? t.multiColumnTemplate : t;
				var cc:int = 2;
				if (layoutT.column3 != null)
					cc = 3;
				if (layoutT.column4 != null)
					cc = 4;
				if (cc == 2)
				{
					var entries:int = ((t.column1 is Array) ? (t.column1 as Array).length : 0)
						+ ((t.column2 is Array) ? (t.column2 as Array).length : 0);
					if (entries >= 8)
						cc = 4;
					else if (entries >= 6)
						cc = 3;
				}
				if (cc > _maxModColumns)
					_maxModColumns = cc;
			}

			var appW:Number = _appW > 0 ? _appW : (stage != null ? stage.stageWidth : 1920);
			var appH:Number = _appH > 0 ? _appH : (stage != null ? stage.stageHeight : 1080);
			Constants.updateForWidth(appW, _maxModColumns);
			_lastColumnCount = Constants.columnCount;

			for each (var template:Object in templates)
			{
				var mod:ModsSettingsComponent = content.addMod(activeTemplate(template));

				modsArray.push(mod);
				snapshotBaseline(mod);
			}

			updateStage(appW, appH);

			content.reflowMods();

			updateToolbarState();

			if (header != null)
			{
				header.setSearchAvailable(modsArray.length > 1);
				header.setModCount(modsArray.length);
			}
		}

		public function as_setScrollPosition(pos:Number):void
		{
			_pendingScroll = pos;
			_pendingScrollTries = 10;
			App.utils.scheduler.scheduleOnNextFrame(applyPendingScroll);
		}

		private function applyPendingScroll():void
		{
			if (_pendingScroll > 0 && content != null && content.scrollPane != null)
			{
				var max:Number = content.scrollPane.maxScroll;

				if (isNaN(max) || max < 0)
					max = 0;

				if (_pendingScroll > max && _pendingScrollTries > 0)
				{
					_pendingScrollTries--;
					App.utils.scheduler.scheduleOnNextFrame(applyPendingScroll);
					return;
				}

				content.scrollPane.smoothScrollPosition = Math.min(_pendingScroll, max);
			}

			_pendingScroll = 0;
		}

		public function as_setMultiColumnMode(value:Boolean):void
		{
			Constants.multiColumnMode = value;

			if (_toolbar != null)
				_toolbar.setColumnMode(value);
		}

		public function as_setUserColorPresets(data:Array):void
		{
			ColorChoicePopup.setUserPresets(data);
		}

		public function as_userPresetAction(action:String, slot:int):void
		{
			ColorChoicePopup.userPresetAction(action, slot);
		}

		public function as_setColorValue(linkage:String, varName:String, color:String):void
		{
			for each (var mod:ModsSettingsComponent in modsArray)
			{
				if (mod.modLinkage != linkage)
					continue;

				for each (var component:Object in mod.components)
				{
					if (component.data.hasOwnProperty('varName') && component.data.varName == varName)
					{
						var control:ColorChoiceButton = component.componentObject['control'] as ColorChoiceButton;

						if (control != null)
							control.onValueChanged(color);

						return;
					}
				}
			}
		}

		private function onUserPresetsSave(presets:Array):void
		{
			if (saveUserColorPresets != null)
				saveUserColorPresets(App.utils.JSON.encode(presets));
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

					mod.refreshResetState();
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
			if (templates != null)
			{
				for (var j:int = 0; j < templates.length; j++)
				{
					if (templates[j] != null && String(templates[j].linkage) == linkage)
					{
						templates[j] = template;
						break;
					}
				}
			}

			var newMod:ModsSettingsComponent = content.reloadMod(linkage, activeTemplate(template));

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

			recountChangedOptions(linkage);
			updateApplyCounter();
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

		public function as_markAllFeaturesSeen(linkage:String):void
		{
			for each (var mod:ModsSettingsComponent in modsArray)
			{
				if (mod.modLinkage == linkage)
				{
					mod.clearAllNewMarkers();
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

			if (configChangedLinkages.indexOf(event.linkage) == -1)
				configChangedLinkages.push(event.linkage);

			recountChangedOptions(event.linkage);
			updateApplyCounter();
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

		private function handleColumnModeToggle(event:InteractiveEvent):void
		{
			Constants.multiColumnMode = !Constants.multiColumnMode;

			if (_toolbar != null)
				_toolbar.setColumnMode(Constants.multiColumnMode);

			if (saveMultiColumnMode != null)
				saveMultiColumnMode(Constants.multiColumnMode);

			_forceColumnRebuild = true;
			updateStage(_appW, _appH);
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
			flashMod(target);
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

		private function handleFeatureSeen(event:InteractiveEvent):void
		{
			if (markFeatureSeen != null)
				markFeatureSeen(event.linkage, event.varName);
		}

		private function requestClose():void
		{
			if (saveScrollPosition != null && content != null && content.scrollPane != null)
				saveScrollPosition(content.scrollPane.scrollPosition);

			closeView();
		}

		private function encodeValue(value:*):String
		{
			return App.utils.JSON.encode({v: value});
		}

		private function snapshotBaseline(mod:ModsSettingsComponent):void
		{
			if (mod == null)
				return;

			var values:Object = mod.getConfigData(true);
			var encoded:Object = new Object();

			for (var k:String in values)
				encoded[k] = encodeValue(values[k]);

			_baseline[mod.modLinkage] = encoded;
			_changedCounts[mod.modLinkage] = 0;
		}

		private function recountChangedOptions(linkage:String):void
		{
			var base:Object = _baseline[linkage];

			if (base == null)
				return;

			for each (var mod:ModsSettingsComponent in modsArray)
			{
				if (mod == null || mod.modLinkage != linkage)
					continue;

				var values:Object = mod.getConfigData(true);
				var count:int = 0;

				for (var k:String in values)
				{
					if (encodeValue(values[k]) != base[k])
						count++;
				}

				_changedCounts[linkage] = count;
				return;
			}
		}

		private function updateApplyCounter():void
		{
			if (footer == null || footer.applyButton == null)
				return;

			var pending:int = 0;

			for each (var count:int in _changedCounts)
				pending += count;

			var applicable:int = pending;

			for each (var linkage:String in configChangedLinkages)
				if (_baseline[linkage] == null)
					applicable++;

			footer.applyButton.label = (pending > 0) ? STRINGS.BUTTON_APPLY + ' (' + pending + ')' : STRINGS.BUTTON_APPLY;
			footer.applyButton.enabled = applicable > 0;
		}

		private function flashMod(mod:ModsSettingsComponent):void
		{
			if (mod != null)
				mod.flashHighlight();
		}

		private function handleOkButtonClick(event:InteractiveEvent):void
		{
			if (configChanged)
				syncModsData();

			requestClose();
		}

		private function handleApplyButtonClick(event:InteractiveEvent):void
		{
			syncModsData();

			for each (var linkage:String in configChangedLinkages)
			{
				for each (var mod:ModsSettingsComponent in modsArray)
				{
					if (mod != null && mod.modLinkage == linkage)
					{
						snapshotBaseline(mod);
						break;
					}
				}
			}

			configChanged = false;
			configChangedLinkages.length = 0;
			footer.applyButton.enabled = false;
			updateApplyCounter();
		}

		private function handleCancelButtonClick(event:InteractiveEvent):void
		{
			requestClose();
		}

		private function handleCloseButtonClick(event:InteractiveEvent):void
		{
			requestClose();
		}

		private function activeTemplate(t:Object):Object
		{
			if (Constants.multiColumnMode && t != null && t.multiColumnTemplate != null)
				return t.multiColumnTemplate;
			return t;
		}

		private function rebuildModsForColumnCount():void
		{
			if (templates == null || content == null)
				return;

			var live:Object = new Object();
			var m:ModsSettingsComponent;
			for each (m in modsArray)
				if (m != null && configChangedLinkages.indexOf(m.modLinkage) != -1)
					live[m.modLinkage] = m.getConfigData();

			for each (var t:Object in templates)
			{
				if (t == null || t.linkage == null)
					continue;

				var linkage:String = String(t.linkage);
				var newMod:ModsSettingsComponent = content.reloadMod(linkage, activeTemplate(t), true);
				if (newMod == null)
					continue;

				for (var i:int = 0; i < modsArray.length; i++)
				{
					if (ModsSettingsComponent(modsArray[i]).modLinkage == linkage)
					{
						modsArray[i] = newMod;
						break;
					}
				}

				if (live[linkage] != null)
					newMod.resetToValues(live[linkage]);
			}

			content.reflowMods();

			if (replayLiveImages != null)
				replayLiveImages();
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

					m.setSearchVisible(true);

					if (_collapseSnapshot != null && _collapseSnapshot.hasOwnProperty(m.modLinkage))
						m.setCollapsed(Boolean(_collapseSnapshot[m.modLinkage]));
				}

				_collapseSnapshot = null;

				if (header != null)
					header.setSearchResults(-1, 0);

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

			var hits:int = 0;
			var total:int = 0;
			var lastHit:ModsSettingsComponent = null;

			for each (var mod:ModsSettingsComponent in modsArray)
			{
				if (mod == null)
					continue;

				total++;

				var name:String = (mod.data != null && mod.data.modDisplayName != null) ? String(mod.data.modDisplayName) : '';
				name = name.replace(/<[^>]*>/g, '').toLowerCase();

				var hit:Boolean = name.indexOf(query) != -1;
				mod.setSearchVisible(hit);

				if (hit)
				{
					hits++;
					lastHit = mod;
				}

				if (hit && mod.isCollapsed)
					mod.setCollapsed(false);
			}

			if (header != null)
				header.setSearchResults(hits, total);

			if (hits == 1)
				flashMod(lastHit);

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
				requestClose();
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
