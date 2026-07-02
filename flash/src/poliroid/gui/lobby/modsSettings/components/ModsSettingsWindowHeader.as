package poliroid.gui.lobby.modsSettings.components
{
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.display.Sprite;
	import flash.display.DisplayObject;
	import flash.geom.Rectangle;
	import flash.events.MouseEvent;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.ui.Keyboard;
	import scaleform.clik.events.ButtonEvent;
	import scaleform.clik.events.InputEvent;
	import net.wg.gui.components.controls.CloseButtonText;
	import net.wg.gui.components.controls.TextInput;
	import net.wg.infrastructure.base.UIComponentEx;
	import poliroid.gui.lobby.modsSettings.events.InteractiveEvent;
	import poliroid.gui.lobby.modsSettings.data.ModsSettingsLocalizationVO;
	import poliroid.gui.lobby.modsSettings.lang.STRINGS;
	import poliroid.gui.lobby.modsSettings.shared.Constants;

	public class ModsSettingsWindowHeader extends UIComponentEx
	{
		private static const SEARCH_WIDTH:Number = 150;
		private static const SEARCH_CLOSE_GAP:Number = 32;
		private static const SEARCH_ICON_INSET:Number = 7;
		private static const SEARCH_TEXT_INDENT:Number = 20;
		private static const SEARCH_CLEAR_ZONE:Number = 18;

		public var titleTF:TextField;
		public var closeButton:CloseButtonText;

		private var _search:TextInput;
		private var _magnifier:Sprite;
		private var _clearBtn:Sprite;
		private var _placeholder:TextField;
		private var _hitsTF:TextField;
		private var _searchFocused:Boolean = false;
		private var _searchAvailable:Boolean = true;
		private var _baseTitle:String = '';
		private var _modCount:int = -1;
		private var _searchHint:String = "Search mods" + String.fromCharCode(0x2026);
		private var _searchTfBaseW:Number = NaN;
		private var _lastSearchText:String = '';

		public function ModsSettingsWindowHeader()
		{
			super();
		}

		override protected function configUI():void
		{
			super.configUI();

			closeButton.addEventListener(ButtonEvent.CLICK, handleCloseButtonClick);
			createSearch();
		}

		override protected function onDispose():void
		{
			App.utils.scheduler.cancelTask(syncFocusState);

			closeButton.removeEventListener(ButtonEvent.CLICK, handleCloseButtonClick);
			closeButton.dispose();
			closeButton = null;
			titleTF = null;

			if (_search != null)
			{
				_search.removeEventListener(InputEvent.INPUT, onSearchInput);
				_search.removeEventListener(FocusEvent.FOCUS_IN, onSearchFocusIn);
				_search.removeEventListener(FocusEvent.FOCUS_OUT, onSearchFocusOut);
				_search.removeEventListener(KeyboardEvent.KEY_DOWN, onSearchKeyDown);
				_search = null;
			}

			if (_clearBtn != null)
			{
				_clearBtn.removeEventListener(MouseEvent.CLICK, onClearClick);
				_clearBtn = null;
			}

			_magnifier = null;
			_placeholder = null;
			_hitsTF = null;

			super.onDispose();
		}

		private function createSearch():void
		{
			_search = TextInput(App.utils.classFactory.getComponent('TextInput', TextInput));
			_search.width = SEARCH_WIDTH;
			_search.text = '';
			_search.validateNow();
			addChild(_search);
			_search.addEventListener(InputEvent.INPUT, onSearchInput);
			_search.addEventListener(FocusEvent.FOCUS_IN, onSearchFocusIn);
			_search.addEventListener(FocusEvent.FOCUS_OUT, onSearchFocusOut);
			_search.addEventListener(KeyboardEvent.KEY_DOWN, onSearchKeyDown);
			applySearchIndent();

			var iconColor:uint = (_search.textField != null) ? _search.textField.textColor : Constants.TOOLBAR_TEXT_COLOR;

			_magnifier = new Sprite();
			_magnifier.mouseEnabled = false;
			_magnifier.graphics.lineStyle(1.5, iconColor, 1);
			_magnifier.graphics.drawCircle(5, 5, 4);
			_magnifier.graphics.moveTo(8, 8);
			_magnifier.graphics.lineTo(12, 12);
			addChild(_magnifier);

			_placeholder = new TextField();
			_placeholder.selectable = false;
			_placeholder.mouseEnabled = false;
			_placeholder.autoSize = TextFieldAutoSize.LEFT;
			var fmt:TextFormat = new TextFormat();
			fmt.font = "$FieldFont";
			fmt.size = 14;
			fmt.color = 0x80807A;
			_placeholder.defaultTextFormat = fmt;
			_placeholder.text = _searchHint;
			addChild(_placeholder);

			_hitsTF = new TextField();
			_hitsTF.selectable = false;
			_hitsTF.mouseEnabled = false;
			_hitsTF.autoSize = TextFieldAutoSize.LEFT;
			var hitsFmt:TextFormat = new TextFormat();
			hitsFmt.font = "$FieldFont";
			hitsFmt.size = 13;
			hitsFmt.color = 0x959382;
			_hitsTF.defaultTextFormat = hitsFmt;
			_hitsTF.visible = false;
			addChild(_hitsTF);

			_clearBtn = new Sprite();
			_clearBtn.buttonMode = true;
			_clearBtn.useHandCursor = true;
			_clearBtn.visible = false;
			_clearBtn.graphics.beginFill(0, 0);
			_clearBtn.graphics.drawRect(0, 0, 14, 14);
			_clearBtn.graphics.endFill();
			_clearBtn.graphics.lineStyle(1.5, Constants.TOOLBAR_TEXT_COLOR, 0.85);
			_clearBtn.graphics.moveTo(3, 3);
			_clearBtn.graphics.lineTo(11, 11);
			_clearBtn.graphics.moveTo(11, 3);
			_clearBtn.graphics.lineTo(3, 11);
			_clearBtn.addEventListener(MouseEvent.CLICK, onClearClick);
			addChild(_clearBtn);

			layoutSearch();

			setSearchAvailable(_searchAvailable);
		}

		public function updateStage(appWidth:Number, appHeight:Number):void
		{
			x = int((appWidth - Constants.MOD_COMPONENT_WIDTH) / 2);
			closeButton.x = Constants.MOD_COMPONENT_WIDTH - 56;
			layoutSearch();
		}

		private function layoutSearch():void
		{
			if (_search == null)
				return;

			var sx:Number = (Constants.MOD_COMPONENT_WIDTH - 56) - SEARCH_CLOSE_GAP - SEARCH_WIDTH;

			var cb:Rectangle = closeButton.getBounds(this);
			var cy:Number;
			if (cb.height > 0 && cb.height < 200)
				cy = cb.top + cb.height / 2;
			else
				cy = closeButton.y + closeButton.height / 2;

			_search.x = sx;
			_search.y = cy - _search.height / 2;

			_placeholder.x = sx + 6 + SEARCH_TEXT_INDENT;
			_placeholder.y = cy - _placeholder.height / 2;

			centerSpriteOn(_magnifier, sx + SEARCH_ICON_INSET, cy);
			centerSpriteOn(_clearBtn, sx + SEARCH_WIDTH - 24, cy);

			if (_hitsTF != null)
			{
				_hitsTF.x = sx - _hitsTF.width - 8;
				_hitsTF.y = cy - _hitsTF.height / 2;
			}
		}

		public function setSearchAvailable(available:Boolean):void
		{
			_searchAvailable = available;

			if (_search != null)
				_search.visible = available;

			if (_clearBtn != null)
				_clearBtn.visible = available && _search != null && (_search.text.length > 0);

			if (_hitsTF != null && !available)
				_hitsTF.visible = false;

			updatePlaceholder();
		}

		public function setSearchResults(hits:int, total:int):void
		{
			if (_hitsTF == null)
				return;

			if (hits < 0 || !_searchAvailable)
			{
				_hitsTF.visible = false;
				return;
			}

			var numHits:String = "<b><font color='#C8C8C8'>" + hits + "</font></b>";
			var numTotal:String = "<b><font color='#C8C8C8'>" + total + "</font></b>";

			_hitsTF.htmlText = STRINGS.SEARCH_HITS.split('{0}').join(numHits).split('{1}').join(numTotal);
			_hitsTF.visible = true;

			layoutSearch();
		}

		private function applySearchIndent():void
		{
			if (_search == null || _search.textField == null)
				return;

			if (isNaN(_searchTfBaseW))
				_searchTfBaseW = _search.textField.width;

			if (_search.textField.width != _searchTfBaseW - SEARCH_CLEAR_ZONE)
				_search.textField.width = _searchTfBaseW - SEARCH_CLEAR_ZONE;
		}

		private function centerSpriteOn(s:Sprite, leftX:Number, centerY:Number):void
		{
			var b:Rectangle = s.getBounds(s);
			s.x = leftX;
			s.y = centerY - b.top - b.height / 2;
		}

		public function setModCount(count:int):void
		{
			_modCount = count;
			applyTitle();
		}

		private function applyTitle():void
		{
			if (titleTF != null)
				titleTF.text = _baseTitle;
		}

		public function setLocalization(vo:ModsSettingsLocalizationVO):void
		{
			_baseTitle = vo.windowTitle;
			applyTitle();
			closeButton.label = vo.buttonClose;
			if (vo.searchPlaceholder != null && vo.searchPlaceholder != "")
			{
				_searchHint = vo.searchPlaceholder;
				if (_placeholder != null)
					_placeholder.text = _searchHint;
			}
		}

		public function focusSearch():void
		{
			if (!_searchAvailable || _search == null || stage == null)
				return;

			if (_search.textField != null)
				stage.focus = _search.textField;
			else
				stage.focus = _search;
		}

		public function isSearchFocused():Boolean
		{
			return stageFocusWithinSearch();
		}

		public function blurSearch():void
		{
			if (stage != null)
				stage.focus = null;

			scheduleFocusSync();
		}

		private function updatePlaceholder():void
		{
			if (_placeholder == null || _search == null)
				return;

			var idle:Boolean = _searchAvailable && (_search.text.length == 0) && !_searchFocused;

			_placeholder.visible = idle;

			if (_magnifier != null)
				_magnifier.visible = idle;
		}

		private function onSearchInput(event:InputEvent):void
		{
			applySearchIndent();
			updatePlaceholder();
			_clearBtn.visible = (_search.text.length > 0);

			if (_search.text == _lastSearchText)
				return;

			_lastSearchText = _search.text;
			dispatchEvent(new InteractiveEvent(InteractiveEvent.SEARCH, '', '', _search.text));
		}

		public function clearSearch():void
		{
			if (_search == null)
				return;

			_search.text = '';
			_lastSearchText = '';
			_search.validateNow();
			applySearchIndent();
			updatePlaceholder();

			if (_clearBtn != null)
				_clearBtn.visible = false;

			dispatchEvent(new InteractiveEvent(InteractiveEvent.SEARCH, '', '', ''));
		}

		private function onClearClick(event:MouseEvent):void
		{
			clearSearch();
			blurSearch();
		}

		private function onSearchFocusIn(event:FocusEvent):void
		{
			scheduleFocusSync();
		}

		private function onSearchFocusOut(event:FocusEvent):void
		{
			scheduleFocusSync();
		}

		private function onSearchKeyDown(event:KeyboardEvent):void
		{
			if (event.keyCode == Keyboard.ESCAPE)
			{
				event.stopImmediatePropagation();
				blurSearch();
			}
		}

		private function scheduleFocusSync():void
		{
			App.utils.scheduler.cancelTask(syncFocusState);
			App.utils.scheduler.scheduleOnNextFrame(syncFocusState);
		}

		private function syncFocusState():void
		{
			if (_search == null)
				return;

			var focused:Boolean = stageFocusWithinSearch();

			if (focused == _searchFocused)
				return;

			_searchFocused = focused;
			applySearchIndent();
			updatePlaceholder();

			if (_search != null)
				_search.focused = focused ? 1 : 0;
		}

		private function stageFocusWithinSearch():Boolean
		{
			if (stage == null || _search == null)
				return false;

			var o:DisplayObject = stage.focus;

			while (o != null)
			{
				if (o == _search)
					return true;

				o = o.parent;
			}

			return false;
		}

		private function handleCloseButtonClick(event:ButtonEvent):void
		{
			dispatchEvent(new InteractiveEvent(InteractiveEvent.CLOSE_BUTTON_CLICK));
		}
	}
}
