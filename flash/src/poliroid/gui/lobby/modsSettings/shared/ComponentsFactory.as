package poliroid.gui.lobby.modsSettings.shared
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.display.MovieClip;
	import flash.display.DisplayObject;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.display.Loader;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.net.URLRequest;
	import flash.events.IOErrorEvent;
	import flash.events.TimerEvent;
	import flash.geom.Rectangle;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	import scaleform.clik.controls.ButtonGroup;
	import scaleform.clik.core.UIComponent;
	import scaleform.clik.events.SliderEvent;
	import scaleform.clik.events.ListEvent;
	import scaleform.clik.events.InputEvent;
	import scaleform.clik.events.ButtonEvent;
	import scaleform.clik.events.IndexEvent;
	import scaleform.clik.data.DataProvider;
	import net.wg.gui.components.controls.NumericStepper;
	import net.wg.gui.components.controls.SoundButtonEx;
	import net.wg.gui.components.controls.TextInput;
	import net.wg.gui.components.controls.CheckBox;
	import net.wg.gui.components.controls.DropdownMenu;
	import net.wg.gui.components.controls.ButtonIconNormal;
	import net.wg.gui.components.controls.LabelControl;
	import net.wg.gui.components.controls.UILoaderAlt;
	import net.wg.gui.components.controls.SoundButton;
	import net.wg.gui.components.controls.InfoIcon;
	import net.wg.gui.components.controls.Slider;
	import net.wg.gui.components.controls.StepSlider;
	import net.wg.gui.components.controls.RadioButton;
	import net.wg.gui.components.controls.RangeSlider;
	import poliroid.gui.lobby.modsSettings.controls.ColorChoiceButton;
	import poliroid.gui.lobby.modsSettings.controls.HotkeyControl;
	import poliroid.gui.lobby.modsSettings.data.HotkeyControlVO;
	import poliroid.gui.lobby.modsSettings.events.InteractiveEvent;
	import poliroid.gui.lobby.modsSettings.shared.Utilities;

	public class ComponentsFactory
	{
		private static const SCROLL_ITEM_LIMIT:int = 9;
		private static var _imageCache:Dictionary = new Dictionary();
		private static const ATLAS_ORIGIN:Point = new Point(0, 0);

		public function ComponentsFactory()
		{
			super();
		}

		public static function handleComponentEvent(event:Event):void
		{
			event.target.dispatchEvent(new InteractiveEvent(InteractiveEvent.VALUE_CHANGED));
		}

		public static function createEmpty(width:Number, height:Number):MovieClip
		{
			var mc:MovieClip = new MovieClip();

			mc.width = width;
			mc.height = height ? height : Constants.EMPTY_COMPONENT_HEIGHT;

			return mc;
		}

		public static function escapeHTML(text:String):String
		{
			if (text == null)
				return text;
			return text.split('&').join('&amp;').split('<').join('&lt;').split('>').join('&gt;');
		}

		public static function createLabel(text:String, tooltip:String = '', tooltipIcon:String = '', useHTML:Boolean = true):DisplayObject
		{
			var ui:UIComponent = new UIComponent();
			var label:LabelControl = LabelControl(App.utils.classFactory.getComponent('LabelControl', LabelControl));

			label.width = 800;
			label.htmlText = useHTML ? text : escapeHTML(text);

			if (tooltip)
			{
				label.toolTip = tooltip;
				label.infoIcoType = tooltipIcon ? tooltipIcon : InfoIcon.TYPE_INFO;
			}

			ui.addChild(label);
			label.validateNow();

			var infoIcon:InfoIcon = label['_infoIco'];

			if (infoIcon)
				infoIcon.buttonMode = true;

			var result:MovieClip = new MovieClip();

			result.addChild(ui);
			result['label'] = label;

			return result;
		}

		public static const IMAGE_PAD:int = 8;

		public static function createImage(componentConfig:Object):DisplayObject
		{
			var w:int = componentConfig.hasOwnProperty("width") ? int(componentConfig.width) : 0;
			var h:int = componentConfig.hasOwnProperty("height") ? int(componentConfig.height) : 0;
			var src:String = String(componentConfig.source);
			var halign:String = componentConfig.hasOwnProperty("align") ? String(componentConfig.align) : "left";
			var valign:String = componentConfig.hasOwnProperty("valign") ? String(componentConfig.valign) : "top";
			var boxW:int = componentConfig.hasOwnProperty("containerWidth") ? int(componentConfig.containerWidth) : ((w > 0 ? w : 96) + IMAGE_PAD);
			var boxH:int = componentConfig.hasOwnProperty("containerHeight") ? int(componentConfig.containerHeight) : ((h > 0 ? h : 96) + IMAGE_PAD);

			var result:MovieClip = new MovieClip();

			var labelH:int = 0;
			if (componentConfig.hasOwnProperty("label"))
			{
				var labelField:LabelControl = LabelControl(App.utils.classFactory.getComponent('LabelControl', LabelControl));
				labelField.width = boxW;
				labelField.htmlText = (componentConfig.useHTML != false) ? String(componentConfig.label) : escapeHTML(String(componentConfig.label));
				labelField.validateNow();
				result.addChild(labelField);
				result["labelField"] = labelField;
				result["labelAlign"] = componentConfig.hasOwnProperty("labelAlign") ? String(componentConfig.labelAlign) : "left";
				labelH = Constants.COMPONENT_HEADER_MARGIN;
			}
			result["labelH"] = labelH;
			result["useHTML"] = componentConfig.useHTML != false;

			var imgBox:MovieClip = new MovieClip();
			imgBox.y = labelH;
			result.addChild(imgBox);
			result["imgBox"] = imgBox;

			result.graphics.beginFill(0, 0);
			result.graphics.drawRect(0, 0, boxW, labelH + boxH);
			result.graphics.endFill();
			result.scrollRect = new Rectangle(0, 0, boxW, labelH + boxH);
			result["imgW"] = w;
			result["imgH"] = h;
			result["boxW"] = boxW;
			result["boxH"] = boxH;
			result["totalH"] = labelH + boxH;
			result["halign"] = halign;
			result["valign"] = valign;
			positionImageLabel(result);

			if (componentConfig.hasOwnProperty("collapsed") && Boolean(componentConfig.collapsed))
				collapseImage(result);
			else if (componentConfig.hasOwnProperty("atlas") && componentConfig.atlas != null)
			{
				var a:Object = componentConfig.atlas;
				playAtlasInto(result, String(a.source), int(a.frameWidth), int(a.frameHeight),
					int(a.columns), int(a.count), Number(a.fps), (a.loop != false));
			}
			else
				loadImageInto(result, src);
			return result;
		}

		public static function loadImageInto(holder:MovieClip, src:String):void
		{
			stopAtlas(holder);
			holder.scrollRect = new Rectangle(0, 0, int(holder["boxW"]), int(holder["totalH"]));
			holder["collapsed"] = false;
			holder["src"] = src;
			var imgBox:MovieClip = MovieClip(holder["imgBox"]);
			if (src == null || src == "")
			{
				while (imgBox.numChildren > 0)
					imgBox.removeChildAt(imgBox.numChildren - 1);
				return;
			}

			if (_imageCache[src] != null)
			{
				renderBitmapInto(holder, BitmapData(_imageCache[src]));
				return;
			}

			var url:String = (src.indexOf("mods/") == 0 ? "../../../" : "../../") + src;
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {
				var bmp:Bitmap = loader.content as Bitmap;
				if (bmp != null && bmp.bitmapData != null)
				{
					var bmd:BitmapData = bmp.bitmapData.clone();
					_imageCache[src] = bmd;
					if (holder["src"] == src)
						renderBitmapInto(holder, bmd);
				}
				try { loader.unload(); } catch (err:Error) {}
			});
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent):void {});
			try { loader.load(new URLRequest(url)); } catch (err:Error) {}
		}

		public static function collapseImage(holder:MovieClip):void
		{
			stopAtlas(holder);
			var imgBox:MovieClip = MovieClip(holder["imgBox"]);
			while (imgBox.numChildren > 0)
				imgBox.removeChildAt(imgBox.numChildren - 1);
			holder["src"] = "";
			holder["collapsed"] = true;
			holder.scrollRect = new Rectangle(0, 0, int(holder["boxW"]), 0);
		}

		public static function setImageLabel(holder:MovieClip, text:String):void
		{
			var labelField:LabelControl = holder["labelField"] as LabelControl;
			if (labelField == null)
				return;
			labelField.htmlText = (holder["useHTML"] != false) ? text : escapeHTML(text);
			labelField.validateNow();
			positionImageLabel(holder);
		}

		private static function positionImageLabel(holder:MovieClip):void
		{
			var labelField:LabelControl = holder["labelField"] as LabelControl;
			if (labelField == null)
				return;
			var boxW:int = int(holder["boxW"]);
			var labelAlign:String = String(holder["labelAlign"]);
			var tf:TextField = labelField["textField"] as TextField;
			var textW:Number = (tf != null) ? Math.min(tf.textWidth + 4, boxW) : boxW;
			var x:Number = (labelAlign == "center") ? (boxW - textW) / 2 : (labelAlign == "right") ? (boxW - textW) : 0;
			labelField.x = Math.max(0, Math.round(x));
		}

		private static function renderBitmapInto(holder:MovieClip, bmd:BitmapData):void
		{
			var imgBox:MovieClip = MovieClip(holder["imgBox"]);
			while (imgBox.numChildren > 0)
				imgBox.removeChildAt(imgBox.numChildren - 1);

			var w:int = int(holder["imgW"]);
			var h:int = int(holder["imgH"]);
			var boxW:int = int(holder["boxW"]);
			var boxH:int = int(holder["boxH"]);
			var halign:String = String(holder["halign"]);
			var valign:String = String(holder["valign"]);

			var bmp:Bitmap = new Bitmap(bmd);
			var scale:Number = (w > 0 && h > 0)
				? Math.min(w / bmd.width, h / bmd.height)
				: Math.min(boxW / bmd.width, boxH / bmd.height);
			if (scale > 1)
				scale = 1;
			if (scale > 0)
			{
				bmp.scaleX = scale;
				bmp.scaleY = scale;
			}
			bmp.smoothing = scale < 1;
			bmp.x = Math.round((halign == "center") ? (boxW - bmp.width) / 2 : (halign == "right") ? (boxW - bmp.width) : 0);
			bmp.y = Math.round((valign == "center") ? (boxH - bmp.height) / 2 : (valign == "bottom") ? (boxH - bmp.height) : 0);
			imgBox.addChild(bmp);
		}

		public static function playAtlasInto(holder:MovieClip, atlasSrc:String, frameW:int, frameH:int,
			cols:int, count:int, fps:Number, loop:Boolean):void
		{
			stopAtlas(holder);
			holder.scrollRect = new Rectangle(0, 0, int(holder["boxW"]), int(holder["totalH"]));
			holder["collapsed"] = false;
			holder["atlasSrc"] = atlasSrc;
			holder["atlasFrameW"] = (frameW > 0) ? frameW : 1;
			holder["atlasFrameH"] = (frameH > 0) ? frameH : 1;
			holder["atlasCols"] = (cols > 0) ? cols : 1;
			holder["atlasCount"] = (count > 0) ? count : 1;
			holder["atlasFps"] = (fps > 0) ? fps : 12;
			holder["atlasLoop"] = loop;
			holder["atlasFrame"] = 0;

			if (atlasSrc == null || atlasSrc == "")
				return;

			if (_imageCache[atlasSrc] != null)
			{
				startAtlasAnim(holder, BitmapData(_imageCache[atlasSrc]));
				return;
			}
			var url:String = (atlasSrc.indexOf("mods/") == 0 ? "../../../" : "../../") + atlasSrc;
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, function(e:Event):void {
				var bmp:Bitmap = loader.content as Bitmap;
				if (bmp != null && bmp.bitmapData != null)
				{
					var bmd:BitmapData = bmp.bitmapData.clone();
					_imageCache[atlasSrc] = bmd;
					if (holder["atlasSrc"] == atlasSrc && holder.stage != null)
						startAtlasAnim(holder, bmd);
				}
				try { loader.unload(); } catch (err:Error) {}
			});
			loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent):void {});
			try { loader.load(new URLRequest(url)); } catch (err:Error) {}
		}

		private static function startAtlasAnim(holder:MovieClip, atlasBmd:BitmapData):void
		{
			holder["atlasBmd"] = atlasBmd;
			var fw:int = int(holder["atlasFrameW"]);
			var fh:int = int(holder["atlasFrameH"]);
			if (holder["atlasBuf"] is BitmapData)
			{
				try { BitmapData(holder["atlasBuf"]).dispose(); } catch (e:Error) {}
			}
			holder["atlasBuf"] = new BitmapData(fw, fh, true, 0x00000000);
			renderAtlasFrame(holder);
			if (int(holder["atlasCount"]) <= 1)
				return;
			var timer:Timer = new Timer(1000.0 / Number(holder["atlasFps"]));
			timer.addEventListener(TimerEvent.TIMER, function(e:TimerEvent):void {
				advanceAtlas(holder);
			});
			holder["atlasTimer"] = timer;
			timer.start();
		}

		private static function advanceAtlas(holder:MovieClip):void
		{
			if (holder == null || holder.stage == null)
			{
				stopAtlas(holder);
				return;
			}
			var idx:int = int(holder["atlasFrame"]) + 1;
			var count:int = int(holder["atlasCount"]);
			if (idx >= count)
			{
				if (Boolean(holder["atlasLoop"]))
					idx = 0;
				else
				{
					idx = count - 1;
					stopAtlasTimer(holder);
				}
			}
			holder["atlasFrame"] = idx;
			renderAtlasFrame(holder);
		}

		private static function renderAtlasFrame(holder:MovieClip):void
		{
			var atlas:BitmapData = holder["atlasBmd"] as BitmapData;
			var buf:BitmapData = holder["atlasBuf"] as BitmapData;
			if (atlas == null || buf == null)
				return;
			var idx:int = int(holder["atlasFrame"]);
			var cols:int = int(holder["atlasCols"]);
			var fw:int = int(holder["atlasFrameW"]);
			var fh:int = int(holder["atlasFrameH"]);
			var col:int = idx % cols;
			var row:int = idx / cols;
			buf.copyPixels(atlas, new Rectangle(col * fw, row * fh, fw, fh), ATLAS_ORIGIN);
			renderBitmapInto(holder, buf);
		}

		private static function stopAtlasTimer(holder:MovieClip):void
		{
			if (holder != null && holder["atlasTimer"] is Timer)
			{
				Timer(holder["atlasTimer"]).stop();
				holder["atlasTimer"] = null;
			}
		}

		public static function stopAtlas(holder:MovieClip):void
		{
			if (holder == null)
				return;
			stopAtlasTimer(holder);
			holder["atlasBmd"] = null;
			holder["atlasSrc"] = "";
			if (holder["atlasBuf"] is BitmapData)
			{
				try { BitmapData(holder["atlasBuf"]).dispose(); } catch (e:Error) {}
				holder["atlasBuf"] = null;
			}
		}

		public static function createCheckBox(componentConfig:Object, modLinkage:String, text:String, value:Boolean, tooltip:String = '', tooltipIcon:String = ''):DisplayObject
		{
			var ui:UIComponent = new UIComponent();
			var checkbox:CheckBox = CheckBox(App.utils.classFactory.getComponent('CheckBox', CheckBox));

			checkbox.label = (componentConfig.useHTML != false) ? text : escapeHTML(text);
			checkbox.selected = value;
			if (tooltip)
			{
				checkbox.toolTip = tooltip;
				checkbox.infoIcoType = tooltipIcon ? tooltipIcon : InfoIcon.TYPE_INFO;
			}
			checkbox.width = 800;
			ui.addChild(checkbox);
			checkbox.validateNow();

			var infoIcon:InfoIcon = checkbox['_infoIco'];

			if (infoIcon)
				infoIcon.buttonMode = true;

			checkbox.addEventListener(Event.SELECT, handleComponentEvent);

			if (componentConfig.hasOwnProperty('button'))
			{
				var positionY:Number = checkbox.y + Constants.MOD_MARGIN_BOTTOM - 3;
				var positionX:Number = checkbox.x + checkbox.textField.textWidth + Constants.BUTTON_MARGIN_LEFT + 20;

				if (tooltip)
					positionX += 25;

				var button:DisplayObject = createDynamicButton(componentConfig, positionX, positionY);

				button.addEventListener(ButtonEvent.CLICK, function():void {
					button.dispatchEvent(new InteractiveEvent(InteractiveEvent.BUTTON_CLICK, modLinkage, componentConfig.varName, checkbox.selected));
				});

				ui.addChild(button);
			}

			var result:MovieClip = new MovieClip();

			result.addChild(ui);
			result[Constants.COMPONENT_RETURN_VALUE_KEY] = new ValueProxy(checkbox, 'selected');
			result['setValue'] = function(v:*):void { checkbox.selected = Boolean(v); };

			return result;
		}

		public static function createRadioButtonGroup(componentConfig:Object, modLinkage:String, groupName:String, options:Array, text:String = '', tooltip:String = '', tooltipIcon:String = '', value:Number = 0):DisplayObject
		{
			var ui:UIComponent = new UIComponent();
			var margin:Number = text ? Constants.COMPONENT_HEADER_MARGIN : 0;

			if (text)
			{
				var label:DisplayObject = ComponentsFactory.createLabel(text, tooltip, tooltipIcon, componentConfig.useHTML != false);

				label.x = label.y = 0;
				ui.addChild(label);
			}

			var buttonGroup:ButtonGroup = ButtonGroup.getGroup(groupName, ui);

			for (var i:Number = 0; i < options.length; i++)
			{
				var radioButton:RadioButton = RadioButton(App.utils.classFactory.getComponent('RadioButton', RadioButton));

				radioButton.y = i * Constants.RADIO_BUTTONS_MARGIN + (margin ? Constants.RADIO_HEADER_MARGIN : 0);
				radioButton.label = options[i].label;
				radioButton.autoSize = TextFieldAutoSize.LEFT;

				ui.addChild(radioButton);
				buttonGroup.addButton(radioButton);

				radioButton.addEventListener(Event.SELECT, handleComponentEvent);
			}

			buttonGroup.setSelectedButtonByIndex(value);

			if (componentConfig.hasOwnProperty('button'))
			{
				var positionX:Number = 0;
				var positionY:Number = 0;
				radioButton = RadioButton(buttonGroup.getButtonAt(0));

				if (text)
				{
					positionX = label.x + label['label'].textField.textWidth + Constants.BUTTON_MARGIN_LEFT;

					if (tooltip)
						positionX += 25;
				}
				else
					positionX = radioButton.x + radioButton.width + Constants.BUTTON_MARGIN_LEFT;

				var button:DisplayObject = createDynamicButton(componentConfig, positionX, positionY);

				button.addEventListener(ButtonEvent.CLICK, function():void {
					button.dispatchEvent(new InteractiveEvent(InteractiveEvent.BUTTON_CLICK, modLinkage, componentConfig.varName, buttonGroup.selectedIndex));
				});

				ui.addChild(button);
			}

			var result:MovieClip = new MovieClip();

			result.addChild(ui);
			result[Constants.COMPONENT_RETURN_VALUE_KEY] = new ValueProxy(buttonGroup, 'selectedIndex');
			result['setValue'] = function(v:*):void { buttonGroup.setSelectedButtonByIndex(int(v)); };

			return result;
		}

		public static function createDropdown(componentConfig:Object, modLinkage:String, options:Array, text:String = '', tooltip:String = '', tooltipIcon:String = '', value:Number = 0):DisplayObject
		{
			var ui:UIComponent = new UIComponent();
			var margin:Number = text ? Constants.COMPONENT_HEADER_MARGIN : 0;

			if (text)
			{
				var label:DisplayObject = ComponentsFactory.createLabel(text, tooltip, tooltipIcon, componentConfig.useHTML != false);

				label.x = label.y = 0;
				ui.addChild(label);
			}

			var dropdown:DropdownMenu = DropdownMenu(App.utils.classFactory.getObject('DropdownMenuUI'));

			dropdown.y = margin;
			dropdown.width = componentConfig.hasOwnProperty('width') ? componentConfig.width : 200;

			if (options.length > SCROLL_ITEM_LIMIT)
			{
				dropdown['componentInspectorSetting'] = true;
				dropdown.scrollBar = 'ScrollBar';
				dropdown.rowCount = SCROLL_ITEM_LIMIT;
				dropdown.inspectableThumbOffset = {'top': 0, 'bottom': 0};
				dropdown['componentInspectorSetting'] = false;
			}
			else
			{
				dropdown.rowCount = options.length;
				dropdown.scrollBar = '';
			}

			dropdown.itemRenderer = App.utils.classFactory.getClass('DropDownListItemRendererSound');
			dropdown.dropdown = 'DropdownMenu_ScrollingList';
			dropdown.dataProvider = new DataProvider(options);
			dropdown.selectedIndex = value;
			dropdown.validateNow();

			ui.addChild(dropdown);

			dropdown.handleScroll = false;
			dropdown.addEventListener(ListEvent.INDEX_CHANGE, handleComponentEvent);
			dropdown['componentInspectorSetting'] = true;
			dropdown.inspectableMenuOffset = {'top': -5, 'right': -6, 'bottom': 0, 'left': 3};
			if (options.length > SCROLL_ITEM_LIMIT)
				dropdown.inspectableMenuPadding = {'top': 0, 'right': 6, 'bottom': 0, 'left': 0};
			dropdown['componentInspectorSetting'] = false;

			if (componentConfig.hasOwnProperty('button'))
			{
				var positionY:Number = dropdown.y + Constants.MOD_MARGIN_BOTTOM - 3;
				var positionX:Number = dropdown.x + dropdown.width + Constants.BUTTON_MARGIN_LEFT;
				var button:DisplayObject = createDynamicButton(componentConfig, positionX, positionY);

				button.addEventListener(ButtonEvent.CLICK, function():void {
					button.dispatchEvent(new InteractiveEvent(InteractiveEvent.BUTTON_CLICK, modLinkage, componentConfig.varName, dropdown.selectedIndex));
				});

				ui.addChild(button);
			}

			var result:MovieClip = new MovieClip();

			result.addChild(ui);
			result[Constants.COMPONENT_RETURN_VALUE_KEY] = new ValueProxy(dropdown, 'selectedIndex');
			result['setValue'] = function(v:*):void { dropdown.selectedIndex = int(v); dropdown.validateNow(); };

			return result;
		}

		public static function createSlider(componentConfig:Object, modLinkage:String, min:Number, max:Number, interval:Number, value:Number, format:String, text:String = '', tooltip:String = '', tooltipIcon:String = ''):DisplayObject
		{
			var ui:UIComponent = new UIComponent();
			var margin:Number = text ? Constants.COMPONENT_HEADER_MARGIN : 0;

			if (text)
			{
				var label:DisplayObject = ComponentsFactory.createLabel(text, tooltip, tooltipIcon, componentConfig.useHTML != false);

				label.x = label.y = 0;
				ui.addChild(label);
			}

			var slider:Slider = Slider(App.utils.classFactory.getComponent('Slider', Slider));

			slider.y = margin;
			slider.width = componentConfig.hasOwnProperty('width') ? componentConfig.width : 200;
			slider.minimum = min;
			slider.maximum = max;
			slider.snapInterval = interval;
			slider.snapping = true;
			slider.value = value;

			ui.addChild(slider);

			slider.addEventListener(SliderEvent.VALUE_CHANGE, handleComponentEvent);

			if (format)
			{
				var formattedString:String = Utilities.getFormattedSliderValue(format, slider.value.toString());
				var valueLabel:DisplayObject = ComponentsFactory.createLabel(formattedString, '');

				valueLabel.y = slider.y + 2;
				valueLabel.x = slider.x + slider.width + Constants.SLIDER_VALUE_MARGIN;

				ui.addChild(valueLabel);

				slider.addEventListener(SliderEvent.VALUE_CHANGE, function(event:SliderEvent):void {
					valueLabel['label'].htmlText = Utilities.getFormattedSliderValue(format, event.value.toString());
				});
			}

			if (componentConfig.hasOwnProperty('button'))
			{
				var positionY:Number = margin;
				var positionX:Number = slider.x + slider.width + Constants.SLIDER_VALUE_MARGIN + 15;

				if (format)
					positionX += 15;

				var button:DisplayObject = createDynamicButton(componentConfig, positionX, positionY);

				button.addEventListener(ButtonEvent.CLICK, function():void {
					button.dispatchEvent(new InteractiveEvent(InteractiveEvent.BUTTON_CLICK, modLinkage, componentConfig.varName, slider.value));
				});

				ui.addChild(button);
			}

			slider.addEventListener(MouseEvent.MOUSE_WHEEL, function(event:MouseEvent):void {
				event.stopImmediatePropagation();
				result.parent.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_WHEEL, event.bubbles, event.cancelable, event.localX, event.localY, event.relatedObject, event.ctrlKey, event.altKey, event.shiftKey, event.buttonDown, event.delta));
			});

			var result:MovieClip = new MovieClip();

			result.addChild(ui);
			result[Constants.COMPONENT_RETURN_VALUE_KEY] = new ValueProxy(slider, 'value');
			result['setValue'] = function(v:*):void {
				slider.value = Number(v);
				if (format && valueLabel != null)
					valueLabel['label'].htmlText = Utilities.getFormattedSliderValue(format, slider.value.toString());
			};

			return result;
		}

		public static function createStepSlider(componentConfig:Object, modLinkage:String, options:Array, format:String, text:String = '', tooltip:String = '', tooltipIcon:String = '', selectedIndex:Number = 0):DisplayObject
		{
			var ui:UIComponent = new UIComponent();
			var margin:Number = text ? Constants.COMPONENT_HEADER_MARGIN : 0;

			if (text)
			{
				var label:DisplayObject = ComponentsFactory.createLabel(text, tooltip, tooltipIcon, componentConfig.useHTML != false);

				label.x = label.y = 0;
				ui.addChild(label);
			}

			var stepSlider:StepSlider = StepSlider(App.utils.classFactory.getComponent('StepSliderUI', StepSlider));

			stepSlider.y = margin;
			stepSlider.width = componentConfig.hasOwnProperty('width') ? componentConfig.width : 200;
			stepSlider.dataProvider = new DataProvider(options);
			stepSlider.value = selectedIndex;

			ui.addChild(stepSlider);

			stepSlider.addEventListener(SliderEvent.VALUE_CHANGE, handleComponentEvent);

			var itemLabel:String = stepSlider['getItemLabel'](stepSlider.dataProvider.requestItemAt(stepSlider.value));
			var formattedItemLabel:String = Utilities.getFormattedSliderValue(format, itemLabel);
			var valueLabel:DisplayObject = ComponentsFactory.createLabel(formattedItemLabel, '');

			valueLabel.y = stepSlider.y + 2;
			valueLabel.x = stepSlider.x + stepSlider.width + Constants.SLIDER_VALUE_MARGIN;

			ui.addChild(valueLabel);

			stepSlider.addEventListener(SliderEvent.VALUE_CHANGE, function(event:SliderEvent):void {
				var itemLabel:String = stepSlider['getItemLabel'](stepSlider.dataProvider.requestItemAt(event.value));
				valueLabel['label'].htmlText = Utilities.getFormattedSliderValue(format, itemLabel);
			});

			if (componentConfig.hasOwnProperty('button'))
			{
				var positionY:Number = margin;
				var positionX:Number = stepSlider.x + stepSlider.width + Constants.SLIDER_VALUE_MARGIN + 15;

				if (format)
					positionX += 15;

				var button:DisplayObject = createDynamicButton(componentConfig, positionX, positionY);

				button.addEventListener(ButtonEvent.CLICK, function(event:ButtonEvent):void {
					button.dispatchEvent(new InteractiveEvent(InteractiveEvent.BUTTON_CLICK, modLinkage, componentConfig.varName, stepSlider.value));
				});

				ui.addChild(button);
			}

			stepSlider.addEventListener(MouseEvent.MOUSE_WHEEL, function(event:MouseEvent):void {
				event.stopImmediatePropagation();
				result.parent.dispatchEvent(new MouseEvent(MouseEvent.MOUSE_WHEEL, event.bubbles, event.cancelable, event.localX, event.localY, event.relatedObject, event.ctrlKey, event.altKey, event.shiftKey, event.buttonDown, event.delta));
			});

			var result:MovieClip = new MovieClip();

			result.addChild(ui);
			result[Constants.COMPONENT_RETURN_VALUE_KEY] = new ValueProxy(stepSlider, 'value');
			result['setValue'] = function(v:*):void {
				stepSlider.value = int(v);
				var lbl:String = stepSlider['getItemLabel'](stepSlider.dataProvider.requestItemAt(stepSlider.value));
				valueLabel['label'].htmlText = Utilities.getFormattedSliderValue(format, lbl);
			};

			return result;
		}

		public static function createTextInput(componentConfig:Object, text:String = '', tooltip:String = '', tooltipIcon:String = '', value:String = ''):DisplayObject
		{
			var ui:UIComponent = new UIComponent();
			var margin:Number = text ? Constants.COMPONENT_HEADER_MARGIN : 0;

			if (text)
			{
				var label:DisplayObject = ComponentsFactory.createLabel(text, tooltip, tooltipIcon, componentConfig.useHTML != false);

				label.x = label.y = 0;

				ui.addChild(label);
			}

			var textInput:TextInput = TextInput(App.utils.classFactory.getComponent('TextInput', TextInput));

			textInput.y = margin;
			textInput.width = componentConfig.hasOwnProperty('width') ? componentConfig.width : 200;
			textInput.text = value;
			textInput.validateNow();

			ui.addChild(textInput);

			textInput.addEventListener(InputEvent.INPUT, handleComponentEvent);

			var result:MovieClip = new MovieClip();

			result.addChild(ui);
			result[Constants.COMPONENT_RETURN_VALUE_KEY] = new ValueProxy(textInput, 'text');
			result['setValue'] = function(v:*):void { textInput.text = String(v); textInput.validateNow(); };

			return result;
		}

		public static function createNumericStepper(componentConfig:Object, modLinkage:String, minimum:Number, maximum:Number, stepSize:Number, value:Number, text:String, tooltip:String, tooltipIcon:String):DisplayObject
		{
			var ui:UIComponent = new UIComponent();

			if (text)
			{
				var label = ComponentsFactory.createLabel(text, tooltip, tooltipIcon, componentConfig.useHTML != false);

				label.y = 4;
				ui.addChild(label);
			}

			var numericStepper:NumericStepper = NumericStepper(App.utils.classFactory.getComponent('NumericStepper', NumericStepper));

			numericStepper.x = 315;
			if (componentConfig.hasOwnProperty('canManualInput'))
				numericStepper.canManualInput = componentConfig.canManualInput;
			numericStepper.minimum = minimum;
			numericStepper.maximum = maximum;
			numericStepper.stepSize = stepSize;
			numericStepper.value = value;
			numericStepper.validateNow();

			ui.addChild(numericStepper);

			numericStepper.addEventListener(IndexEvent.INDEX_CHANGE, handleComponentEvent);

			var result:MovieClip = new MovieClip();

			result.addChild(ui);
			result[Constants.COMPONENT_RETURN_VALUE_KEY] = new ValueProxy(numericStepper, 'value');
			result['control'] = numericStepper;
			result['setValue'] = function(v:*):void { numericStepper.value = Number(v); numericStepper.validateNow(); };

			return result;
		}

		public static function createHotKey(componentConfig:Object, modLinkage:String, value:Array, text:String = '', tooltip:String = '', tooltipIcon:String = ''):DisplayObject
		{
			var ui:UIComponent = new UIComponent();
			var label:DisplayObject = ComponentsFactory.createLabel(text, tooltip, tooltipIcon, componentConfig.useHTML != false);

			label.x = 0;
			label.y = 4;
			label.visible = false;
			ui.addChild(label);

			var hotkeyCtrl:HotkeyControl = App.utils.classFactory.getComponent('HotkeyControlUI', HotkeyControl);

			hotkeyCtrl.x = 315;
			hotkeyCtrl.y = 0;

			ui.addChild(hotkeyCtrl);

			var result:MovieClip = new MovieClip();

			result.addChild(ui);
			result[Constants.COMPONENT_RETURN_VALUE_KEY] = new ValueProxy(hotkeyCtrl, 'keyset');
			result['control'] = hotkeyCtrl;

			var labelCtrl:LabelControl = label['label'] as LabelControl;
			var fullText:String = text;
			var useHTML:Boolean = componentConfig.useHTML != false;

			var floatMode:String = componentConfig.hasOwnProperty('float') ? String(componentConfig.float) : 'none';
			var tfBelow:TextField = new TextField();
			tfBelow.autoSize = TextFieldAutoSize.NONE;
			tfBelow.multiline = true;
			tfBelow.wordWrap = true;
			tfBelow.selectable = false;
			tfBelow.mouseEnabled = false;
			tfBelow.x = 0;

			var layoutHotkeyRow:Function = function(event:Event = null):void
			{
				if (labelCtrl == null)
					return;
				var tf:TextField = labelCtrl['textField'] as TextField;
				if (tf == null)
					return;
				var prevH:Number = result.height;
				var maxW:Number = Math.max(80, (hotkeyCtrl.x + hotkeyCtrl.comboLeft) - 10);

				tf.autoSize = TextFieldAutoSize.NONE;
				tf.multiline = true;
				tf.wordWrap = true;

				var didWrap:Boolean = false;
				if (floatMode == 'right' && fullText.indexOf('<') == -1)
				{
					tf.width = maxW;
					if (useHTML) tf.htmlText = fullText; else tf.text = fullText;
					var lineH:Number = (tf.numLines > 0) ? tf.getLineMetrics(0).height : 18;
					var comboBottom:Number = hotkeyCtrl.getBounds(ui).bottom;
					var beside:int = Math.max(1, Math.floor((comboBottom - tf.getBounds(ui).top) / lineH));
					if (tf.numLines > beside)
					{
						var offset:int = tf.getLineOffset(beside);
						tf.text = fullText.substring(0, offset);
						tf.height = tf.textHeight + 4;
						tfBelow.defaultTextFormat = tf.getTextFormat();
						tfBelow.embedFonts = tf.embedFonts;
						tfBelow.antiAliasType = tf.antiAliasType;
						tfBelow.width = Math.max(maxW, hotkeyCtrl.getBounds(ui).right);
						tfBelow.text = fullText.substring(offset);
						tfBelow.height = tfBelow.textHeight + 4;
						tfBelow.y = Math.max(comboBottom, tf.getBounds(ui).bottom);
						if (tfBelow.parent != ui)
							ui.addChild(tfBelow);
						didWrap = true;
					}
				}

				if (!didWrap)
				{
					tf.width = maxW;
					if (useHTML) tf.htmlText = fullText; else tf.text = fullText;
					tf.height = tf.textHeight + 4;
					if (tfBelow.parent == ui)
						ui.removeChild(tfBelow);
				}

				if (event != null)
				{
					label.visible = true;
					if (Math.abs(result.height - prevH) > 0.5)
						result.dispatchEvent(new InteractiveEvent(InteractiveEvent.HEIGHT_CHANGED, modLinkage));
				}
			};

			hotkeyCtrl.addEventListener(HotkeyControl.DISPLAY_CHANGED, layoutHotkeyRow);

			if (componentConfig.hotkey != null)
				hotkeyCtrl.setData(new HotkeyControlVO(componentConfig.hotkey));
			else
				layoutHotkeyRow();

			return result;
		}

		public static function createColorChoice(componentConfig:Object, modLinkage:String, value:String, text:String = '', tooltip:String = '', tooltipIcon:String = ''):DisplayObject
		{
			var ui:UIComponent = new UIComponent();
			var label:DisplayObject = ComponentsFactory.createLabel(text, tooltip, tooltipIcon, componentConfig.useHTML != false);

			label.x = 0;
			label.y = 4;
			ui.addChild(label);

			var colorChoice:ColorChoiceButton = App.utils.classFactory.getComponent('ColorChoiceButtonUI', ColorChoiceButton);

			colorChoice.x = 315;
			colorChoice.y = 0;
			colorChoice.color = value;

			ui.addChild(colorChoice);

			var result:MovieClip = new MovieClip();

			result.addChild(ui);
			result[Constants.COMPONENT_RETURN_VALUE_KEY] = new ValueProxy(colorChoice, 'color');
			result['control'] = colorChoice;
			result['setValue'] = function(v:*):void { colorChoice.color = String(v); };

			return result;
		}

		public static function createCheckboxColor(componentConfig:Object, modLinkage:String, value:Object, text:String = '', tooltip:String = '', tooltipIcon:String = ''):DisplayObject
		{
			var ui:UIComponent = new UIComponent();

			var enabled:Boolean = (value != null) && Boolean(value.enabled);
			var colorValue:String = (value != null && value.color != null) ? String(value.color) : '000000';

			var swatchX:Number = 315;
			var labelX:Number = 20;

			var maxW:Number = Math.max(60, swatchX - labelX - 10);
			var useHTML:Boolean = componentConfig.useHTML != false;
			var isPlain:Boolean = text.indexOf('<') < 0;

			var firstLine:String = text;
			var overflow:String = '';
			var lineH:Number = 16;

			var label:DisplayObject = ComponentsFactory.createLabel(text, '', '', useHTML);
			var labelCtrl:LabelControl = label['label'] as LabelControl;
			var tf:TextField = labelCtrl ? (labelCtrl['textField'] as TextField) : null;
			if (tf != null)
			{
				tf.autoSize = TextFieldAutoSize.NONE;
				tf.multiline = true;
				tf.wordWrap = true;
				tf.width = maxW;
				if (useHTML) tf.htmlText = text; else tf.text = text;
				lineH = tf.getLineMetrics(0).height;
				if (isPlain && tf.numLines > 1)
				{
					var off:int = tf.getLineOffset(1);
					firstLine = text.substring(0, off);
					overflow = text.substring(off);
				}
			}

			var checkbox:CheckBox = CheckBox(App.utils.classFactory.getComponent('CheckBox', CheckBox));

			checkbox.label = useHTML ? firstLine : escapeHTML(firstLine);
			checkbox.selected = enabled;
			if (tooltip)
			{
				checkbox.toolTip = tooltip;
				checkbox.infoIcoType = tooltipIcon ? tooltipIcon : InfoIcon.TYPE_INFO;
			}
			checkbox.x = 0;
			checkbox.y = 0;
			checkbox.width = swatchX - 6;
			ui.addChild(checkbox);
			checkbox.validateNow();

			var infoIcon:InfoIcon = checkbox['_infoIco'];
			if (infoIcon)
				infoIcon.buttonMode = true;

			checkbox.addEventListener(Event.SELECT, handleComponentEvent);

			var colorChoice:ColorChoiceButton = App.utils.classFactory.getComponent('ColorChoiceButtonUI', ColorChoiceButton);

			colorChoice.x = swatchX;
			colorChoice.y = 0;
			colorChoice.color = colorValue;
			ui.addChild(colorChoice);
			colorChoice.validateNow();

			if (overflow != '' && tf != null)
			{
				var belowY:Number = (checkbox.textField != null ? checkbox.textField.y : 2) + lineH;

				if (useHTML) tf.htmlText = overflow; else tf.text = overflow;
				tf.height = tf.textHeight + 4;
				label.x = labelX;
				label.y = belowY;
				(label as MovieClip).mouseEnabled = false;
				(label as MovieClip).mouseChildren = false;

				var lowerHit:MovieClip = new MovieClip();
				lowerHit.graphics.beginFill(0, 0);
				lowerHit.graphics.drawRect(0, 0, swatchX - 6, tf.height);
				lowerHit.graphics.endFill();
				lowerHit.x = 0;
				lowerHit.y = belowY;
				ui.addChild(lowerHit);
				lowerHit.addEventListener(MouseEvent.CLICK, function(e:MouseEvent):void {
					checkbox.selected = !checkbox.selected;
					lowerHit.dispatchEvent(new InteractiveEvent(InteractiveEvent.VALUE_CHANGED));
				});

				ui.addChild(label);
			}

			var result:MovieClip = new MovieClip();

			result.addChild(ui);

			result[Constants.COMPONENT_RETURN_VALUE_KEY] = new CheckboxColorProxy(checkbox, colorChoice);
			result['control'] = colorChoice;
			result['setValue'] = function(v:*):void {
				if (v != null)
				{
					checkbox.selected = Boolean(v.enabled);
					if (v.color != null)
						colorChoice.color = String(v.color);
				}
			};

			return result;
		}

		public static function createRangeSlider(componentConfig:Object, modLinkage:String):DisplayObject
		{
			var ui:UIComponent = new UIComponent();
			var label:DisplayObject = ComponentsFactory.createLabel(componentConfig.text, componentConfig.tooltip, componentConfig.tooltipIcon, componentConfig.useHTML != false);

			label.y = -7;
			label.x = 0;
			ui.y += 7;
			ui.addChild(label);

			var rangeSlider:RangeSlider = RangeSlider(App.utils.classFactory.getComponent('RangeSliderUI', RangeSlider));

			rangeSlider.y += 33;
			rangeSlider.x += 5;
			rangeSlider.width = 240;
			rangeSlider.maximum = componentConfig.maximum;
			rangeSlider.minimum = componentConfig.minimum;
			rangeSlider.divisionLabelPostfix = componentConfig.divisionLabelPostfix;
			rangeSlider.divisionLabelStep = componentConfig.divisionLabelStep;
			rangeSlider.divisionStep = componentConfig.divisionStep;
			rangeSlider.minRangeDistance = componentConfig.minRangeDistance;
			rangeSlider.snapInterval = componentConfig.snapInterval;
			rangeSlider.leftValue = componentConfig.value[0];
			rangeSlider.rightValue = componentConfig.value[1];
			rangeSlider.focusable = true;
			rangeSlider.snapping = true;
			rangeSlider.rangeMode = true;
			rangeSlider['valueProxyValue'] = [rangeSlider.leftValue, rangeSlider.rightValue];

			var valueLabel:DisplayObject = ComponentsFactory.createLabel('', '');

			valueLabel.y = rangeSlider.y + 2;
			valueLabel.x = rangeSlider.x + rangeSlider.width + Constants.SLIDER_VALUE_MARGIN + 5;
			valueLabel['label'].htmlText = rangeSlider.leftValue + ' / ' + rangeSlider.rightValue;

			ui.addChild(valueLabel);

			rangeSlider.addEventListener(SliderEvent.VALUE_CHANGE, function(event:SliderEvent):void {
				valueLabel['label'].htmlText = rangeSlider.leftValue + ' / ' + rangeSlider.rightValue;
				rangeSlider['valueProxyValue'] = [rangeSlider.leftValue, rangeSlider.rightValue];
				handleComponentEvent(event);
			});
			rangeSlider.validateNow();

			ui.addChild(rangeSlider);

			var result:MovieClip = new MovieClip();

			result.addChild(ui);
			result[Constants.COMPONENT_RETURN_VALUE_KEY] = new ValueProxy(rangeSlider, 'valueProxyValue');
			result['setValue'] = function(v:*):void {
				if (v is Array && (v as Array).length >= 2) {
					rangeSlider.leftValue = Number(v[0]);
					rangeSlider.rightValue = Number(v[1]);
					rangeSlider['valueProxyValue'] = [rangeSlider.leftValue, rangeSlider.rightValue];
					valueLabel['label'].htmlText = rangeSlider.leftValue + ' / ' + rangeSlider.rightValue;
				}
			};

			return result;
		}

		private static function createDynamicButton(componentConfig:Object, positionX:Number = 0, positionY:Number = 0):DisplayObject
		{
			var button:*;

			if (componentConfig.button.hasOwnProperty('text') && componentConfig.button.text != '')
			{
				button = SoundButtonEx(App.utils.classFactory.getComponent('ButtonNormal', SoundButtonEx));
				button.label = componentConfig.button.text;
			}

			if (componentConfig.button.hasOwnProperty('iconSource') && componentConfig.button.iconSource != '')
			{
				button = ButtonIconNormal(App.utils.classFactory.getComponent('ButtonIconNormalUI', ButtonIconNormal));
				button.iconSource = componentConfig.button.iconSource;
				button.iconOffsetTop = componentConfig.button.hasOwnProperty('iconOffsetTop') ? componentConfig.button.iconOffsetTop : 0;
				button.iconOffsetLeft = componentConfig.button.hasOwnProperty('iconOffsetLeft') ? componentConfig.button.iconOffsetLeft : 0;
			}

			button.width = componentConfig.button.hasOwnProperty('width') ? componentConfig.button.width : 30;
			button.height = componentConfig.button.hasOwnProperty('height') ? componentConfig.button.height : 25;

			if (componentConfig.button.hasOwnProperty('fixedPositioning') && componentConfig.button.fixedPositioning == true
				&& componentConfig.hasOwnProperty('width'))
			{
				if (componentConfig.button.hasOwnProperty('align') && componentConfig.button.align == 'right')
					positionX = Number(componentConfig.width) - button.width;
				else
					positionX = Number(componentConfig.width);
			}

			button.x = positionX;
			button.y = positionY;

			if (componentConfig.button.hasOwnProperty('offsetLeft'))
				button.x += componentConfig.button.offsetLeft;
			if (componentConfig.button.hasOwnProperty('offsetTop'))
				button.y += componentConfig.button.offsetTop;

			button.validateNow();

			return button;
		}
	}
}
