# coding: utf-8

__author__ = 'Renat Iliev (izeberg)'
__copyright__ = 'Original work Copyright Renat Iliev; Aslain Menu enhancements Copyright 2026 Aslain'
__credits__ = ['Renat Iliev (izeberg) - original author',
	'Andrii Andrushchyshyn (poliroid) - original contributor',
	'Paul Ekshmidt (Kurzdor) - original maintainer']
__license__ = 'CC BY-NC-SA 4.0'
__version__ = '1.6.1'
__maintainer__ = 'Aslain'
__doc__ = 'https://github.com/Aslain/modssettingsapi'

import templates
from .api import ModsSettingsApi
from .skeleton import IModsSettingsApi
from ._constants import SPECIAL_KEYS, CONDITION, VERSION, VERSION_TUPLE
from .utils import getDependencyManager

__all__ = ('g_modsSettingsApi', 'IModsSettingsApi', 'templates', 'SPECIAL_KEYS', 'CONDITION', 'VERSION', 'VERSION_TUPLE', )

class _ModsSettingsApi(IModsSettingsApi):
	"""
	Public API of the mods settings menu
	"""

	def __init__(self):
		super(_ModsSettingsApi, self).__init__()
		self.__instance = ModsSettingsApi()

		manager = getDependencyManager()
		if manager is not None:
			manager.addInstance(IModsSettingsApi, self)

	def saveModData(self, linkage, version, data):
		""" Save mod data
		:param linkage: Mod identifier
		:param version: Data version
		:param data: Data to save
		:return: Saved data
		"""
		return self.__instance.saveModData(linkage, version, data)

	def getModData(self, linkage, version, default):
		""" Get mod data
		If the requested version does not match the saved one, the default data is saved and returned
		:param linkage: Mod identifier
		:param version: Data version
		:param default: Default data
		:return: Saved data
		"""
		return self.__instance.getModData(linkage, version, default)

	def setModTemplate(self, linkage, template, callback, buttonHandler=None):
		""" Initialize mod settings
		:param linkage: Settings identifier
		:param template: Settings template
		:param callback: Handler called with new settings
		:param buttonHandler: Handler called on button clicks
		:return: Saved settings
		"""
		return self.__instance.setModTemplate(linkage, template, callback, buttonHandler)

	def registerCallback(self, linkage, callback, buttonHandler=None):
		""" Register handler callbacks
		:param linkage: Settings identifier
		:param callback: Handler called with new settings
		:param buttonHandler: Handler called on button clicks
		"""
		return self.__instance.registerCallback(linkage, callback, buttonHandler)

	def getModSettings(self, linkage, template):
		""" Get saved settings
		:param linkage: Settings identifier
		:param template: Settings template
		:return: Saved settings, or None when there are none (or they are outdated)
		"""
		return self.__instance.getModSettings(linkage, template)

	def updateModSettings(self, linkage, newSettings):
		""" Update saved settings
		:param linkage: Settings identifier
		:param newSettings: New settings
		"""
		return self.__instance.updateModSettings(linkage, newSettings)

	def updateImage(self, linkage, varName, source, width=None, height=None, removeImage=False, label=None):
		""" Live-update of an Image component while the settings window is open.
		:param linkage: Mod linkage
		:param varName: varName of the Image component to update
		:param source: New image path (root-relative, e.g. 'gui/maps/...' or 'mods/configs/...')
		:param width: Image width in pixels, optional. When omitted the image renders at
			its natural size, shrunk to fit the container if oversized (never upscaled)
		:param height: Image height in pixels, optional (see width)
		:param removeImage: When True, collapse the image container to zero height so the
			controls below it jump up (source/width/height are ignored). Default False keeps
			the current behaviour (reserved slot), so existing mods need no change.
		:param label: New text for the image's label, optional. None (default) keeps the
			current text, '' clears it. Only applies when the Image was created with a
			label slot (createImage(..., label=...)).
		"""
		return self.__instance.updateImage(linkage, varName, source, width, height, removeImage, label)

	def updateImageAtlas(self, linkage, varName, atlasSource, frameWidth, frameHeight, columns, count, fps, loop=True, width=None, height=None):
		""" Live-update of an Image component as a looping sprite-sheet animation (Aslain Menu only).
		Plays the atlas at atlasSource - a grid of `columns` cells, each frameWidth x
		frameHeight, `count` frames total, row-major - at `fps`, scaled to width/height like
		updateImage. The sheet is loaded once and animated with copyPixels, so it stays light.
		:param linkage: Mod linkage
		:param varName: varName of the Image component to animate
		:param atlasSource: atlas image path (root-relative, e.g. 'mods/configs/...atlas.png')
		:param frameWidth: width of one frame cell in px
		:param frameHeight: height of one frame cell in px
		:param columns: number of columns in the grid
		:param count: number of frames
		:param fps: playback speed
		:param loop: loop the animation (default True)
		:param width: display width in px, optional (scaled-to-fit like updateImage)
		:param height: display height in px, optional
		"""
		return self.__instance.updateImageAtlas(linkage, varName, atlasSource, frameWidth, frameHeight, columns, count, fps, loop, width, height)

	def checkKeyset(self, keyset):
		""" Check whether a keyset is currently pressed
		:param keyset: Keys to check
		:return: bool
		"""
		return self.__instance.checkKeyset(keyset)

g_modsSettingsApi = ModsSettingsApi()
