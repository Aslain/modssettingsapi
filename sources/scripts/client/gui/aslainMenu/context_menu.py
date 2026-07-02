import BigWorld
from gui.Scaleform.framework.managers.context_menu import AbstractContextMenuHandler, registerHandlers as registerContextMenuHandlers
from helpers import dependency

from ._constants import *
from .l10n import l10n
from .skeleton import IModsSettingsApiInternal

class HotkeyContextMenuHandler(AbstractContextMenuHandler):
	api = dependency.descriptor(IModsSettingsApiInternal)

	def __init__(self, cmProxy, ctx=None):
		self._linkage = None
		self._varName = None
		self._value = None
		super(HotkeyContextMenuHandler, self).__init__(cmProxy, ctx, {
			HOTKEY_OPTIONS.CLEAR_VALUE: 'clearValue',
			HOTKEY_OPTIONS.RESET_TO_DEFAULT_VALUE: 'resetToDefaultValue'
		})

	def _initFlashValues(self, ctx):
		self._varName = ctx.varName
		self._linkage = ctx.linkage
		self._value = ctx.value

	def _clearFlashValues(self):
		self._linkage = None
		self._varName = None
		self._value = None

	def clearValue(self):
		if self._linkage and self._varName:
			self.api.onHotkeyClear(self._linkage, self._varName)

	def resetToDefaultValue(self):
		if self._linkage and self._varName:
			self.api.onHotkeyDefault(self._linkage, self._varName)

	def _generateOptions(self, ctx=None):
		return [
			self._makeItem(HOTKEY_OPTIONS.RESET_TO_DEFAULT_VALUE, self.api.userSettings.get('buttonDefault') or l10n('buttons/default')),
			self._makeItem(HOTKEY_OPTIONS.CLEAR_VALUE, self.api.userSettings.get('buttonCleanup') or l10n('buttons/clear'), {'enabled': len(self._value)}),
		]

class PresetContextMenuHandler(AbstractContextMenuHandler):
	api = dependency.descriptor(IModsSettingsApiInternal)

	def __init__(self, cmProxy, ctx=None):
		self._slot = -1
		self._value = ''
		super(PresetContextMenuHandler, self).__init__(cmProxy, ctx, {
			PRESET_OPTIONS.EDIT: 'editPreset',
			PRESET_OPTIONS.COPY_HEX: 'copyPresetHex',
			PRESET_OPTIONS.CLEAR: 'clearPreset'
		})

	def _initFlashValues(self, ctx):
		self._slot = int(ctx.slot)
		self._value = str(ctx.value or '')

	def _clearFlashValues(self):
		self._slot = -1
		self._value = ''

	def editPreset(self):
		if self._slot >= 0 and hasattr(self.api, 'userPresetAction'):
			self.api.userPresetAction('edit', self._slot)

	def clearPreset(self):
		if self._slot >= 0 and hasattr(self.api, 'userPresetAction'):
			self.api.userPresetAction('clear', self._slot)

	def copyPresetHex(self):
		if self._value:
			try:
				BigWorld.wg_copyToClipboard(self._value.upper())
			except Exception:
				pass

	def _generateOptions(self, ctx=None):
		hasColor = len(self._value) > 0
		return [
			self._makeItem(PRESET_OPTIONS.EDIT, l10n('colorchoice/preset/menu/edit')),
			self._makeItem(PRESET_OPTIONS.COPY_HEX, l10n('colorchoice/preset/menu/copyhex'), {'enabled': hasColor}),
			self._makeItem(PRESET_OPTIONS.CLEAR, l10n('colorchoice/preset/menu/clear'), {'enabled': hasColor}),
		]

class ColorValueContextMenuHandler(AbstractContextMenuHandler):
	api = dependency.descriptor(IModsSettingsApiInternal)

	def __init__(self, cmProxy, ctx=None):
		self._linkage = None
		self._varName = None
		self._value = ''
		super(ColorValueContextMenuHandler, self).__init__(cmProxy, ctx, {
			COLOR_VALUE_OPTIONS.RESET: 'resetValue',
			COLOR_VALUE_OPTIONS.COPY_HEX: 'copyHex'
		})

	def _initFlashValues(self, ctx):
		self._linkage = ctx.linkage
		self._varName = ctx.varName
		self._value = str(ctx.value or '')

	def _clearFlashValues(self):
		self._linkage = None
		self._varName = None
		self._value = ''

	def resetValue(self):
		if self._linkage and self._varName and hasattr(self.api, 'requestColorValueReset'):
			self.api.requestColorValueReset(self._linkage, self._varName)

	def copyHex(self):
		if self._value:
			try:
				BigWorld.wg_copyToClipboard(self._value.upper())
			except Exception:
				pass

	def _generateOptions(self, ctx=None):
		hasDefault = self._getDefault() is not None
		return [
			self._makeItem(COLOR_VALUE_OPTIONS.RESET, self.api.userSettings.get('buttonDefault') or l10n('buttons/default'), {'enabled': hasDefault}),
			self._makeItem(COLOR_VALUE_OPTIONS.COPY_HEX, l10n('colorchoice/preset/menu/copyhex'), {'enabled': len(self._value) > 0}),
		]

	def _getDefault(self):
		if hasattr(self.api, 'getColorValueDefault'):
			return self.api.getColorValueDefault(self._linkage, self._varName)
		return None

def getContextMenuHandlers():
	return (
		(HOTKEY_CONTEXT_MENU_HANDLER_ALIAS, HotkeyContextMenuHandler),
		(PRESET_CONTEXT_MENU_HANDLER_ALIAS, PresetContextMenuHandler),
		(COLOR_VALUE_CONTEXT_MENU_HANDLER_ALIAS, ColorValueContextMenuHandler),
	)

registerContextMenuHandlers(*getContextMenuHandlers())
