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
		}
		self.userSettings = {}
		self._liveSettingsChangeCallbacks = {}
		self._lastLiveSettings = {}
		self.hotkeys = HotkeysController(self)

		self.onWindowOpened = Event.Event()
		self.onWindowClosed = Event.Event()
		# TODO: remove from public API
		self.onHotkeysUpdated = Event.Event()
		self.onButtonClicked = Event.Event()
		self.onSettingsChanged = Event.Event()
		self.onImageUpdate = Event.Event()
		self.onReloadMod = Event.Event()

		# Live changes are uncommitted, so the diff baseline must not survive a window
		# session: drop it on open so the first change re-diffs against committed settings.
		self.onWindowOpened += self._resetLiveSettingsBaseline

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
				self.__migrateState()
		except Exception:
			_logger.exception('Error occured when trying to load state!')

	# TODO: delete in next release
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

	def setModTemplate(self, linkage, template, callback, buttonHandler=None):
		try:
			self.activeMods.add(linkage)
			currentTemplate = self.state['templates'].get(linkage)
			if not currentTemplate or self.compareTemplates(template, currentTemplate):
				self.state['templates'][linkage] = template
				self.state['settings'][linkage] = self.getSettingsFromTemplate(template)
				self.saveState()
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
		# Persist per-mod collapsed state of the settings list (UI only, no settings impact)
		self.state.setdefault('collapsed', {})[linkage] = bool(collapsed)
		self.saveState()

	def updateImage(self, linkage, varName, source, width=None, height=None, removeImage=False, label=None):
		w = int(width) if width else 0
		h = int(height) if height else 0
		self.onImageUpdate(linkage, varName, source, w, h, bool(removeImage), label)

	def registerLiveSettingsChange(self, linkage, callback, mode=LIVE_SETTINGS_MODE.FULL_SETTINGS):
		# mode=FULL_SETTINGS (default): callback gets the full settings dict (legacy behavior).
		# mode=CHANGED_ONLY: callback gets only the keys whose value changed since the previous
		# live event. Any unknown mode degrades to FULL_SETTINGS so a bad value never raises.
		if mode not in LIVE_SETTINGS_MODE.ALL:
			mode = LIVE_SETTINGS_MODE.FULL_SETTINGS
		self._liveSettingsChangeCallbacks.setdefault(linkage, []).append((callback, mode))

	def unregisterLiveSettingsChange(self, linkage, callback):
		# Unregister by callback identity regardless of the mode it was registered with;
		# the public signature is (linkage, callback), matching legacy behavior.
		callbacks = self._liveSettingsChangeCallbacks.get(linkage)
		if callbacks:
			self._liveSettingsChangeCallbacks[linkage] = [
				entry for entry in callbacks if entry[0] != callback
			]

	def _resetLiveSettingsBaseline(self):
		# Runtime-only diff baseline; never persisted. Cleared on window open so the
		# first live change re-diffs against committed settings (uncommitted live
		# values from a previous session must not leak into the next one).
		self._lastLiveSettings = {}

	def _computeChangedSettings(self, previous, settings):
		# A key is "changed" if it is new or its value differs from the baseline.
		return dict(
			(key, value) for key, value in settings.items()
			if key not in previous or previous[key] != value
		)

	def notifyLiveSettingsChange(self, linkage, settings):
		callbacks = tuple(self._liveSettingsChangeCallbacks.get(linkage, ()))
		# Diff against the previous live settings; on the first change after the window
		# opened (no live baseline yet) diff against the committed settings instead.
		previous = self._lastLiveSettings.get(linkage)
		if previous is None:
			previous = self.state['settings'].get(linkage, {})
		changedOnly = None
		for callback, mode in callbacks:
			if mode == LIVE_SETTINGS_MODE.CHANGED_ONLY:
				if changedOnly is None:
					changedOnly = self._computeChangedSettings(previous, settings)
				callback(linkage, changedOnly)
			else:
				callback(linkage, settings)
		# Update the baseline only after diffing this event.
		self._lastLiveSettings[linkage] = dict(settings)

	def reloadModTemplate(self, linkage, template):
		""" Re-render one mod's component subtree in the open settings window
		from a fresh template (e.g. with new-language labels), without closing it.
		The mod is responsible for filling the template with the values it wants
		shown. Has no effect if the window is closed.
		"""
		template = dict(template)
		template['linkage'] = linkage
		self.onReloadMod(linkage, template)
		# Re-rendered hotkey controls start blank; re-apply their stored values so
		# they keep their keysets (otherwise Apply would persist empty hotkeys).
		self.onHotkeysUpdated()

	def checkKeyset(self, keys):
		return self.hotkeys.checkKeyset(keys)

	# TODO: delete in next release
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

	def _modSortKey(self, linkage):
		# Sort key for the mods list / A-Z jump: ignore a leading image badge or any
		# symbols/whitespace before the real name so e.g. an '<img>'-prefixed mod still
		# sorts under its first real letter
		name = self.state['templates'][linkage].get('modDisplayName') or linkage
		name = re.sub('<[^>]*>', '', name)
		name = re.sub('^[^0-9A-Za-z]+', '', name)
		return (name or linkage).lower()

	def generateSettingsData(self):
		# Make copy of current templates and updates component's values from actual settings
		templates = []
		# Sort by display name (case-insensitive) so the A-Z quick-jump bar is monotonic;
		# fall back to the linkage when a mod has no display name
		linkages = sorted(self.state['templates'], key=self._modSortKey)
		for linkage in linkages:
			template = copy.deepcopy(self.state['templates'][linkage])
			settings = self.getModSettings(linkage, template)
			template['linkage'] = linkage
			template['collapsed'] = self.state.get('collapsed', {}).get(linkage, False)
			if 'enabled' in template:
				template['enabled'] = settings['enabled']
			for column in COLUMNS:
				if column in template:
					for component in template[column]:
						if 'varName' in component and component['varName'] in settings:
							component['value'] = settings[component['varName']]
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
