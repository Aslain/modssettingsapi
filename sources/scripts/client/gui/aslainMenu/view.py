import json
import logging

from gui.Scaleform.framework import ScopeTemplates, ViewSettings, g_entitiesFactories
from gui.Scaleform.framework.entities.View import View
from gui.Scaleform.framework.managers.loaders import SFViewLoadParams
from gui.shared.personality import ServicesLocator
from gui.shared.view_helpers.blur_manager import CachedBlur
from gui.shared.utils.functions import makeTooltip
from frameworks.wulf import WindowLayer
from helpers import dependency

from ._constants import *
from .l10n import l10n
from .skeleton import IModsSettingsApiInternal
from .utils import byteify, getParentWindow

_logger = logging.getLogger(__name__)

__all__ = ('loadView', )

def loadView(api):
	parent = getParentWindow()
	app = ServicesLocator.appLoader.getDefLobbyApp()
	app.loadView(SFViewLoadParams(VIEW_ALIAS, parent=parent), ctx=api)


def generateLocalizationVO(userSettings):
	return {
		'windowTitle': userSettings.get('windowTitle') or l10n('name'),
		'stateTooltip': userSettings.get('enableButtonTooltip') or makeTooltip(l10n('stateswitcher/tooltip/header'), l10n('stateswitcher/tooltip/body')),
		'resetTooltip': userSettings.get('resetButtonTooltip') or makeTooltip(l10n('reset/tooltip/header'), l10n('reset/tooltip/body')),
		'resetConfirmTitle': userSettings.get('resetConfirmTitle') or l10n('reset/tooltip/header'),
		'resetConfirmMessage': userSettings.get('resetConfirmMessage') or l10n('reset/confirm/message'),
		'resetConfirmSubmit': userSettings.get('resetConfirmSubmit') or l10n('reset/confirm/submit'),
		'resetSkipConfirm': bool(userSettings.get('resetSkipConfirm', False)),
		'popupColor': userSettings.get('popupColor') or l10n('colorchoice/header'),
		'buttonOK': userSettings.get('buttonOK') or l10n('buttons/ok'),
		'buttonCancel': userSettings.get('buttonCancel') or l10n('buttons/cancel'),
		'buttonApply': userSettings.get('buttonApply') or l10n('buttons/apply'),
		'buttonClose': userSettings.get('buttonClose') or l10n('buttons/close'),
		'searchPlaceholder': userSettings.get('searchPlaceholder') or l10n('search/placeholder'),
		'searchHits': userSettings.get('searchHits') or l10n('search/hits'),
	}


class ModsSettingsApiWindowMeta(View):

	def requestModsData(self):
		self._printOverrideError('requestModsData')

	def sendModsData(self, data):
		self._printOverrideError('sendModsData')

	def componentChanged(self, data):
		self._printOverrideError('componentChanged')

	def hotkeyAction(self, linkage, varName, action):
		self._printOverrideError('hotKeyAction')

	def buttonAction(self, linkage, varName, value):
		self._printOverrideError('buttonAction')

	def setModCollapsed(self, linkage, collapsed):
		self._printOverrideError('setModCollapsed')

	def markFeatureSeen(self, linkage, varName):
		self._printOverrideError('markFeatureSeen')

	def requestModReset(self, linkage):
		self._printOverrideError('requestModReset')

	def saveUserColorPresets(self, data):
		self._printOverrideError('saveUserColorPresets')

	def saveScrollPosition(self, pos):
		self._printOverrideError('saveScrollPosition')

	def saveMultiColumnMode(self, value):
		self._printOverrideError('saveMultiColumnMode')

	def closeView(self):
		self._printOverrideError('closeView')

	def as_setLocalizationS(self, l10n):
		if self._isDAAPIInited():
			self.flashObject.as_setLocalization(l10n)

	def as_setDataS(self, data):
		if self._isDAAPIInited():
			self.flashObject.as_setData(data)

	def as_setHotkeysS(self, data):
		if self._isDAAPIInited():
			self.flashObject.as_setHotkeys(data)

	def as_updateImageS(self, linkage, varName, source, width, height, removeImage, label):
		if self._isDAAPIInited():
			self.flashObject.as_updateImage(linkage, varName, source, width, height, removeImage, label)

	def as_updateImageAtlasS(self, linkage, varName, atlasSrc, frameW, frameH, cols, count, fps, loop, width, height):
		if self._isDAAPIInited():
			self.flashObject.as_updateImageAtlas(linkage, varName, atlasSrc, frameW, frameH, cols, count, fps, loop, width, height)

	def as_reloadModS(self, linkage, template):
		if self._isDAAPIInited():
			self.flashObject.as_reloadMod(linkage, template)

	def as_resetModS(self, linkage, values):
		if self._isDAAPIInited():
			self.flashObject.as_resetMod(linkage, values)

	def as_setUserColorPresetsS(self, presets):
		if self._isDAAPIInited():
			try:
				self.flashObject.as_setUserColorPresets(presets)
			except Exception:
				pass

	def as_userPresetActionS(self, action, slot):
		if self._isDAAPIInited():
			try:
				self.flashObject.as_userPresetAction(action, slot)
			except Exception:
				pass

	def as_setColorValueS(self, linkage, varName, color):
		if self._isDAAPIInited():
			try:
				self.flashObject.as_setColorValue(linkage, varName, color)
			except Exception:
				pass

	def as_setScrollPositionS(self, pos):
		if self._isDAAPIInited():
			try:
				self.flashObject.as_setScrollPosition(pos)
			except Exception:
				pass

	def as_setMultiColumnModeS(self, value):
		if self._isDAAPIInited():
			try:
				self.flashObject.as_setMultiColumnMode(value)
			except Exception:
				pass

	def as_markAllFeaturesSeenS(self, linkage):
		if self._isDAAPIInited():
			try:
				self.flashObject.as_markAllFeaturesSeen(linkage)
			except Exception:
				pass

	def onFocusIn(self, *args):
		if self._isDAAPIInited():
			return False


class ModsSettingsApiWindow(ModsSettingsApiWindowMeta):
	api = dependency.descriptor(IModsSettingsApiInternal)

	def _populate(self):
		super(ModsSettingsApiWindow, self)._populate()
		self._blur = None
		self.api.onWindowOpened()
		self.api.onHotkeysUpdated += self.__onHotkeysUpdated
		if hasattr(self.api, 'onImageUpdate'):
			self.api.onImageUpdate += self.__onImageUpdate
		if hasattr(self.api, 'onImageAtlasUpdate'):
			self.api.onImageAtlasUpdate += self.__onImageAtlasUpdate
		if hasattr(self.api, 'onReloadMod'):
			self.api.onReloadMod += self.__onReloadMod
		if hasattr(self.api, 'onResetMod'):
			self.api.onResetMod += self.__onResetMod
		if hasattr(self.api, 'onUserPresetAction'):
			self.api.onUserPresetAction += self.__onUserPresetAction
		if hasattr(self.api, 'onColorValueSet'):
			self.api.onColorValueSet += self.__onColorValueSet
		if hasattr(self.api, 'onMarkAllFeaturesSeen'):
			self.api.onMarkAllFeaturesSeen += self.__onMarkAllFeaturesSeen
		self._blur = CachedBlur(enabled=True, ownLayer=self.layer - 1)

	def _dispose(self):
		if self._blur is not None:
			self._blur.fini()
			self._blur = None
		self.api.onHotkeysUpdated -= self.__onHotkeysUpdated
		if hasattr(self.api, 'onImageUpdate'):
			self.api.onImageUpdate -= self.__onImageUpdate
		if hasattr(self.api, 'onImageAtlasUpdate'):
			self.api.onImageAtlasUpdate -= self.__onImageAtlasUpdate
		if hasattr(self.api, 'onReloadMod'):
			self.api.onReloadMod -= self.__onReloadMod
		if hasattr(self.api, 'onResetMod'):
			self.api.onResetMod -= self.__onResetMod
		if hasattr(self.api, 'onUserPresetAction'):
			self.api.onUserPresetAction -= self.__onUserPresetAction
		if hasattr(self.api, 'onColorValueSet'):
			self.api.onColorValueSet -= self.__onColorValueSet
		if hasattr(self.api, 'onMarkAllFeaturesSeen'):
			self.api.onMarkAllFeaturesSeen -= self.__onMarkAllFeaturesSeen
		self.api.onWindowClosed()
		super(ModsSettingsApiWindow, self)._dispose()

	def requestModsData(self):
		self.api.clearState()
		self.as_setLocalizationS(generateLocalizationVO(self.api.userSettings))
		if hasattr(self.api, 'getMultiColumnMode'):
			self.as_setMultiColumnModeS(self.api.getMultiColumnMode())
		self.as_setDataS(self.api.generateSettingsData())
		self.as_setHotkeysS(self.api.getAllHotkeys())
		if hasattr(self.api, 'getUserColorPresets'):
			self.as_setUserColorPresetsS(self.api.getUserColorPresets())
		if hasattr(self.api, 'getWindowScrollPosition'):
			self.as_setScrollPositionS(self.api.getWindowScrollPosition())

	def sendModsData(self, data):
		data = byteify(json.loads(data))
		for linkage in data:
			settings = data[linkage]
			self.api.updateModSettings(linkage, settings)
		self.api.saveState()

	def componentChanged(self, data):
		if not hasattr(self.api, 'notifyLiveSettingsChange'):
			return
		try:
			data = byteify(json.loads(data))
			for linkage in data:
				self.api.notifyLiveSettingsChange(linkage, data[linkage])
		except Exception:
			pass

	def hotkeyAction(self, linkage, varName, action):
		try:
			if action == HOTKEY_ACTIONS.START_ACCEPT:
				self.api.onHotkeyStartAccept(linkage, varName)
			elif action == HOTKEY_ACTIONS.STOP_ACCEPT:
				self.api.onHotkeyStopAccept(linkage, varName)
		except Exception:
			pass

	def buttonAction(self, linkage, varName, value):
		try:
			self.api.onButtonClicked(linkage, varName, value)
		except Exception:
			pass

	def setModCollapsed(self, linkage, collapsed):
		if hasattr(self.api, 'setModCollapsed'):
			self.api.setModCollapsed(linkage, collapsed)

	def markFeatureSeen(self, linkage, varName):
		if hasattr(self.api, 'markFeatureSeen'):
			self.api.markFeatureSeen(linkage, varName)

	def requestModReset(self, linkage):
		if hasattr(self.api, 'resetModToDefaults'):
			self.api.resetModToDefaults(linkage)

	def saveUserColorPresets(self, data):
		try:
			presets = byteify(json.loads(data))
			if isinstance(presets, list) and hasattr(self.api, 'setUserColorPresets'):
				self.api.setUserColorPresets(presets)
		except Exception:
			pass

	def saveScrollPosition(self, pos):
		try:
			if hasattr(self.api, 'setWindowScrollPosition'):
				self.api.setWindowScrollPosition(pos)
		except Exception:
			pass

	def saveMultiColumnMode(self, value):
		try:
			if hasattr(self.api, 'setMultiColumnMode'):
				self.api.setMultiColumnMode(value)
		except Exception:
			pass

	def closeView(self):
		self.api.saveState()
		self.destroy()

	def __onHotkeysUpdated(self):
		data = self.api.getAllHotkeys()
		self.as_setHotkeysS(data)

	def __onImageUpdate(self, linkage, varName, source, width, height, removeImage, label):
		self.as_updateImageS(linkage, varName, source, width, height, removeImage, label)

	def __onImageAtlasUpdate(self, linkage, varName, atlasSrc, frameW, frameH, cols, count, fps, loop, width, height):
		self.as_updateImageAtlasS(linkage, varName, atlasSrc, frameW, frameH, cols, count, fps, loop, width, height)

	def __onReloadMod(self, linkage, template):
		self.as_reloadModS(linkage, template)

	def __onResetMod(self, linkage, values):
		self.as_resetModS(linkage, values)

	def __onUserPresetAction(self, action, slot):
		self.as_userPresetActionS(action, slot)

	def __onColorValueSet(self, linkage, varName, color):
		self.as_setColorValueS(linkage, varName, color)

	def __onMarkAllFeaturesSeen(self, linkage):
		self.as_markAllFeaturesSeenS(linkage)


def getViewSettings():
	return (ViewSettings(VIEW_ALIAS, ModsSettingsApiWindow, VIEW_SWF, WindowLayer.OVERLAY, None, ScopeTemplates.GLOBAL_SCOPE), )

for viewSettings in getViewSettings():
	g_entitiesFactories.addSettings(viewSettings)
