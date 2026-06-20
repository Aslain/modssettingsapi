import os
import re
import functools
import copy
import logging

import BigWorld
import cPickle
import Event

from gui.modsListApi import g_modsListApi

from ._constants import *
from .l10n import l10n
from .context_menu import *
from .hotkeys import HotkeysController
from .view import loadView
from .skeleton import IModsSettingsApiInternal
from .utils import deprecated, getDependencyManager, jsonLoad, jsonDump

_logger = logging.getLogger(__name__)

class ModsSettingsApi(IModsSettingsApiInternal):

	def __init__(self):
		super(ModsSettingsApi, self).__init__()
		self.__saveCallbackID = None
		self.activeMods = set()
		self.state = {
			'settings': {},
			'templates': {},
			'storage': {},
			'collapsed': {},
			'defaults': {},
		}
		self.userSettings = {}
		self._liveSettingsChangeCallbacks = {}
		self._lastLiveSettings = {}
		self._warnedLegacyLiveMode = set()
		self._modTranslations = {}
		self.hotkeys = HotkeysController(self)

		self.onWindowOpened = Event.Event()
		self.onWindowClosed = Event.Event()
		self.onHotkeysUpdated = Event.Event()
		self.onButtonClicked = Event.Event()
		self.onSettingsChanged = Event.Event()
		self.onImageUpdate = Event.Event()
		self.onImageAtlasUpdate = Event.Event()
		self.onReloadMod = Event.Event()
		self.onResetMod = Event.Event()

		self.onWindowOpened += self._resetLiveSettingsBaseline
		self.onWindowClosed += self._stopHotkeyAcceptOnClose

		self.loadSettings()
		self.loadState()

		g_modsListApi.addModification(
			id=MOD_ID, name=self.userSettings.get('modsListApiName') or l10n('name'),
			description=self.userSettings.get('modsListApiDescription') or l10n('description'),
			icon=self.userSettings.get('modsListApiIcon') or MOD_ICON,
			enabled=True, login=True, lobby=True,
			callback=functools.partial(loadView, self)
		)

		manager = getDependencyManager()
		if manager is not None:
			manager.addInstance(IModsSettingsApiInternal, self)

	def loadSettings(self):
		if not os.path.exists(USER_SETTINGS_PATH):
			return
		try:
			with open(USER_SETTINGS_PATH, 'rb') as settingsFile:
				self.userSettings = jsonLoad(settingsFile)
		except Exception:
			_logger.exception('Error occured when trying to load user settings!')

	def loadState(self):
		if not os.path.exists(STATE_FILE_PATH):
			self.saveState()
			return
		try:
			with open(STATE_FILE_PATH, 'rb') as stateFile:
				self.state = jsonLoad(stateFile)
				self.state.setdefault('storage', {})
				self.state.setdefault('collapsed', {})
				self.state.setdefault('defaults', {})
				self.__migrateState()
		except Exception:
			_logger.exception('Error occured when trying to load state!')

	def __migrateState(self):
		if 'data' in self.state:
			data = self.state.pop('data')
			self.state['storage'] = data

	def saveState(self):
		if self.__saveCallbackID is None:
			self.__saveCallbackID = BigWorld.callback(0.0, self.__save)

	def __save(self):
		self.__saveCallbackID = None
		try:
			stateDir = os.path.dirname(STATE_FILE_PATH)
			if not os.path.isdir(stateDir):
				os.makedirs(stateDir)
		except Exception:
			_logger.exception('Error occured when trying to recreate folder structure for state file!')
		try:
			with open(STATE_FILE_PATH, 'wb') as stateFile:
				stateFile.write(jsonDump(self.state, True))
		except Exception:
			_logger.exception('Error occured when trying to save state!')

	def clearState(self):
		for linkage in self.state['templates'].keys():
			if linkage not in self.activeMods:
				del self.state['templates'][linkage]
				del self.state['settings'][linkage]
				self.state.get('defaults', {}).pop(linkage, None)

	def registerModTranslation(self, linkage, mapping):
		""" Register a display-only label translation for one mod, applied to the copy
		shown in the settings window. Keys are the mod's original strings, values the
		replacements. The stored template and saved values are never touched, so this
		causes no settings reset. Repeated calls for the same linkage merge. Intended for
		optional community localisation mods - the API itself ships no translations.
		"""
		if not mapping:
			return
		if not hasattr(self, '_modTranslations'):
			self._modTranslations = {}
		try:
			table = self._modTranslations.setdefault(linkage, {})
			for source, target in mapping.items():
				if isinstance(source, str):
					try:
						source = source.decode('utf-8')
					except Exception:
						continue
				table[source] = target
		except Exception:
			_logger.exception("[ModsSettings API] registerModTranslation failed for '%s'", linkage)

	def _applyTranslations(self, linkage, template):
		translations = getattr(self, '_modTranslations', None)
		mapping = translations.get(linkage) if translations else None
		if not mapping:
			return
		def translate(value):
			if isinstance(value, str):
				try:
					key = value.decode('utf-8')
				except Exception:
					return None
			else:
				key = value
			return mapping.get(key)
		def walk(node):
			if isinstance(node, dict):
				for key, value in node.items():
					if isinstance(value, basestring):
						replacement = translate(value)
						if replacement is not None:
							node[key] = replacement
					else:
						walk(value)
			elif isinstance(node, list):
				for index in range(len(node)):
					value = node[index]
					if isinstance(value, basestring):
						replacement = translate(value)
						if replacement is not None:
							node[index] = replacement
					else:
						walk(value)
		try:
			walk(template)
		except Exception:
			_logger.exception("[ModsSettings API] Translation pass failed for '%s'", linkage)

	def setModTemplate(self, linkage, template, callback, buttonHandler=None):
		try:
			self.activeMods.add(linkage)
			currentTemplate = self.state['templates'].get(linkage)
			if not currentTemplate or self.compareTemplates(template, currentTemplate):
				versionBump = (bool(currentTemplate)
					and 'settingsVersion' in template and 'settingsVersion' in currentTemplate
					and template.get('settingsVersion') > currentTemplate.get('settingsVersion'))
				self.state['templates'][linkage] = template
				self.state['settings'][linkage] = self.getSettingsFromTemplate(template)
				if not currentTemplate or versionBump:
					self.state.setdefault('defaults', {})[linkage] = self.getSettingsFromTemplate(template)
				self.saveState()
			elif ('settingsVersion' in template and 'settingsVersion' in currentTemplate
					and self._settingsStructure(template) == self._settingsStructure(currentTemplate)
					and jsonDump(template, True) != jsonDump(currentTemplate, True)):
				self.state['templates'][linkage] = template
				self.saveState()
			elif ('settingsVersion' in template and 'settingsVersion' in currentTemplate
					and jsonDump(template, True) != jsonDump(currentTemplate, True)):
				_logger.warning(
					"[ModsSettings API] Template for '%s' changed but settingsVersion was not bumped "
					"(stored %s, new %s) - keeping the stored template, so the new layout is NOT applied. "
					"Bump settingsVersion to apply it (note: that resets the mod's saved values to defaults).",
					linkage, currentTemplate.get('settingsVersion'), template.get('settingsVersion'))
			if linkage not in self.state.setdefault('defaults', {}):
				self.state['defaults'][linkage] = self.getSettingsFromTemplate(template)
			self.onSettingsChanged += callback
			if buttonHandler is not None:
				self.onButtonClicked += buttonHandler
			return self.getModSettings(linkage, self.state['templates'][linkage])
		except Exception:
			_logger.exception('Error occured when trying to register mod template!')

	def getModSettings(self, linkage, template):
		result = None
		if template:
			currentTemplate = self.state['templates'].get(linkage)
			if currentTemplate:
				if not self.compareTemplates(template, currentTemplate):
					result = self.state['settings'].get(linkage)
				self.activeMods.add(linkage)
		return result

	def registerCallback(self, linkage, callback, buttonHandler=None):
		self.activeMods.add(linkage)
		self.onSettingsChanged += callback
		if buttonHandler is not None:
			self.onButtonClicked += buttonHandler

	def getModData(self, linkage, version, default):
		storage = self.state['storage']
		if linkage not in storage or storage[linkage]['version'] != version:
			self.saveModData(linkage, version, default)
		return cPickle.loads(storage[linkage]['data'])

	def saveModData(self, linkage, version, data):
		self.state['storage'][linkage] = {
			'version': version,
			'data': cPickle.dumps(data, -1),
		}
		self.saveState()

	def updateModSettings(self, linkage, newSettings):
		self.state['settings'][linkage] = newSettings
		self.onSettingsChanged(linkage, newSettings)

	def setModCollapsed(self, linkage, collapsed):
		self.state.setdefault('collapsed', {})[linkage] = bool(collapsed)
		self.saveState()

	def updateImage(self, linkage, varName, source, width=None, height=None, removeImage=False, label=None):
		w = int(width) if width else 0
		h = int(height) if height else 0
		self.onImageUpdate(linkage, varName, source, w, h, bool(removeImage), label)

	def updateImageAtlas(self, linkage, varName, atlasSource, frameWidth, frameHeight, columns, count, fps, loop=True, width=None, height=None):
		w = int(width) if width else 0
		h = int(height) if height else 0
		self.onImageAtlasUpdate(linkage, varName, atlasSource, int(frameWidth), int(frameHeight),
								int(columns), int(count), float(fps), bool(loop), w, h)

	def getVersion(self):
		return VERSION

	def getVersionTuple(self):
		return VERSION_TUPLE

	def registerLiveSettingsChange(self, linkage, callback, fullsettings=True, mode=None):
		if mode is not None:
			if linkage not in self._warnedLegacyLiveMode:
				self._warnedLegacyLiveMode.add(linkage)
				_logger.warning(
					"registerLiveSettingsChange(mode=...) is deprecated for '%s' - use fullsettings=True/False "
					"instead. The mode argument and the LIVE_SETTINGS_MODE class will be removed in a future version.",
					linkage)
			changedOnly = (mode == LIVE_SETTINGS_MODE.CHANGED_ONLY)
		else:
			changedOnly = not bool(fullsettings)
		self._liveSettingsChangeCallbacks.setdefault(linkage, []).append((callback, changedOnly))

	def unregisterLiveSettingsChange(self, linkage, callback):
		callbacks = self._liveSettingsChangeCallbacks.get(linkage)
		if callbacks:
			self._liveSettingsChangeCallbacks[linkage] = [
				entry for entry in callbacks if entry[0] != callback
			]

	def _resetLiveSettingsBaseline(self):
		self._lastLiveSettings = {}

	def _computeChangedSettings(self, previous, settings):
		return dict(
			(key, value) for key, value in settings.items()
			if key not in previous or previous[key] != value
		)

	def notifyLiveSettingsChange(self, linkage, settings):
		callbacks = tuple(self._liveSettingsChangeCallbacks.get(linkage, ()))
		previous = self._lastLiveSettings.get(linkage)
		if previous is None:
			previous = self.state['settings'].get(linkage, {})
		changedDict = None
		for callback, wantsChangedOnly in callbacks:
			if wantsChangedOnly:
				if changedDict is None:
					changedDict = self._computeChangedSettings(previous, settings)
				callback(linkage, changedDict)
			else:
				callback(linkage, settings)
		self._lastLiveSettings[linkage] = dict(settings)

	def reloadModTemplate(self, linkage, template):
		""" Re-render one mod's component subtree in the open settings window
		from a fresh template (e.g. with new-language labels), without closing it.
		The mod is responsible for filling the template with the values it wants
		shown. Has no effect if the window is closed.
		"""
		try:
			self.hotkeys.stopAccept()
		except Exception:
			_logger.exception("[ModsSettings API] stopAccept on reload of '%s' failed", linkage)
		template = copy.deepcopy(template)
		template['linkage'] = linkage
		template['collapsed'] = self.state.get('collapsed', {}).get(linkage, False)
		template['defaults'] = self.state.get('defaults', {}).get(linkage, {})
		self._attachHotkeyDisplay(linkage, template)
		self._applyTranslations(linkage, template)
		self.onReloadMod(linkage, template)

	def resetModToDefaults(self, linkage):
		""" Reset one mod's controls to their factory defaults, live, in the open window. The
		standard controls are set in place (no rebuild, so no flicker) and the change is
		uncommitted - Apply / OK keeps it, Cancel reverts it. Hotkeys are reset too, through
		their own channel (applied immediately, like any hotkey change). Has no effect on the
		standard controls if the window is closed.
		"""
		template = self.state['templates'].get(linkage)
		if not template:
			return

		defaults = self.state.get('defaults', {}).get(linkage)
		if defaults is None:
			defaults = self.getSettingsFromTemplate(template)

		try:
			self.hotkeys.stopAccept()
		except Exception:
			_logger.exception("[ModsSettings API] stopAccept failed during reset of '%s'", linkage)

		hotkeyVars = []
		for column in COLUMNS:
			for component in template.get(column, ()):
				if component.get('type') == COMPONENT_TYPE.HOTKEY and 'varName' in component:
					hotkeyVars.append(component['varName'])
		for varName in hotkeyVars:
			try:
				self.hotkeys.reset(linkage, varName)
			except Exception:
				_logger.exception("[ModsSettings API] Failed to reset hotkey '%s' of '%s'", varName, linkage)

		_logger.debug("[ModsSettings API] Reset '%s' to defaults: %d control(s), %d hotkey(s)",
			linkage, len(defaults), len(hotkeyVars))

		self.onResetMod(linkage, dict(defaults))

	def _stopHotkeyAcceptOnClose(self):
		try:
			self.hotkeys.stopAccept()
		except Exception:
			_logger.exception('[ModsSettings API] stopAccept on window close failed')

	def checkKeyset(self, keys):
		return self.hotkeys.checkKeyset(keys)

	@deprecated('checkKeyset')
	def checkKeySet(self, keys):
		return self.checkKeyset(keys)

	def compareTemplates(self, newTemplate, oldTemplate):
		if 'settingsVersion' in newTemplate and 'settingsVersion' in oldTemplate:
			return newTemplate['settingsVersion'] > oldTemplate['settingsVersion']
		return jsonDump(newTemplate, True) != jsonDump(oldTemplate, True)

	def getSettingsFromTemplate(self, template):
		result = dict()
		if 'enabled' in template:
			result['enabled'] = template['enabled']
		for column in COLUMNS:
			if column in template:
				result.update(self.getSettingsFromColumn(template[column]))
		return result

	def getSettingsFromColumn(self, column):
		result = dict()
		for component in column:
			if 'varName' in component and 'value' in component:
				result[component['varName']] = component['value']
		return result

	def _settingsStructure(self, template):
		structure = []
		if 'enabled' in template:
			structure.append(('', 'enabled'))
		for column in COLUMNS:
			for component in template.get(column, []):
				if isinstance(component, dict) and 'varName' in component:
					structure.append((component['varName'], component.get('type')))
		return sorted(structure)

	def _modSortKey(self, linkage):
		name = self.state['templates'][linkage].get('modDisplayName') or linkage
		translations = getattr(self, '_modTranslations', None)
		mapping = translations.get(linkage) if translations else None
		if mapping:
			key = name
			if isinstance(key, str):
				try:
					key = key.decode('utf-8')
				except Exception:
					key = None
			if key is not None and key in mapping:
				name = mapping[key]
		if isinstance(name, str):
			name = name.decode('utf-8', 'ignore')
		name = re.sub(u'<[^>]*>', u'', name)
		name = re.sub(u'^[\\W_]+', u'', name, flags=re.UNICODE)
		sortname = (name or unicode(linkage)).lower()
		first = sortname[:1]
		is_latin = (u'a' <= first <= u'z') or (u'0' <= first <= u'9')
		return (0 if is_latin else 1, sortname)

	def _attachHotkeyDisplay(self, linkage, template):
		for column in COLUMNS:
			if column not in template:
				continue
			for component in template[column]:
				if component.get('type') == COMPONENT_TYPE.HOTKEY and 'varName' in component:
					component['hotkey'] = self.hotkeys.getHotkeyData(linkage, component['varName'])

	def generateSettingsData(self):
		templates = []
		linkages = sorted(self.state['templates'], key=self._modSortKey)
		for linkage in linkages:
			template = copy.deepcopy(self.state['templates'][linkage])
			settings = self.getModSettings(linkage, template)
			template['linkage'] = linkage
			template['collapsed'] = self.state.get('collapsed', {}).get(linkage, False)
			template['defaults'] = self.state.get('defaults', {}).get(linkage, {})
			if 'enabled' in template:
				template['enabled'] = settings['enabled']
			for column in COLUMNS:
				if column in template:
					for component in template[column]:
						if 'varName' in component and component['varName'] in settings:
							component['value'] = settings[component['varName']]
			self._attachHotkeyDisplay(linkage, template)
			self._applyTranslations(linkage, template)
			templates.append(template)
		return templates

	def getAllHotkeys(self):
		return self.hotkeys.getAllHotkeys()

	def onHotkeyStartAccept(self, linkage, varName):
		return self.hotkeys.startAccept(linkage, varName)

	def onHotkeyStopAccept(self, linkage, varName):
		return self.hotkeys.stopAccept()

	def onHotkeyDefault(self, linkage, varName):
		return self.hotkeys.reset(linkage, varName)

	def onHotkeyClear(self, linkage, varName):
		return self.hotkeys.clear(linkage, varName)
