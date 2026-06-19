
class IModsSettingsApiInternal(object):
	pass


class IModsSettingsApi(object):

	"""Public, can be shared with other mods"""
	def setModTemplate(self, linkage, template, callback, buttonHandler=None):
		""" Initialize mod settings
		:param linkage: Settings identifier
		:param template: Settings template
		:param callback: Handler called with new settings
		:param buttonHandler: Handler called on button clicks
		:return: Saved settings
		"""
		pass

	def registerCallback(self, linkage, callback, buttonHandler=None):
		""" Register handler callbacks
		:param linkage: Settings identifier
		:param callback: Handler called with new settings
		:param buttonHandler: Handler called on button clicks
		"""
		pass

	def getModSettings(self, linkage, template):
		""" Get saved settings
		:param linkage: Settings identifier
		:param template: Settings template
		:return: Saved settings, or None when there are none (or they are outdated)
		"""
		pass

	def updateModSettings(self, linkage, newSettings):
		""" Update saved settings
		:param linkage: Settings identifier
		:param newSettings: New settings
		"""
		pass

	def checkKeyset(self, keyset):
		""" Check whether a keyset is currently pressed
		:param keyset: Keys to check
		:return: bool
		"""
		pass

	def registerModTranslation(self, linkage, mapping):
		""" Register a display-only label translation for one mod (Aslain Menu only)
		:param linkage: Settings identifier of the mod to translate
		:param mapping: dict {original string: replacement string}, applied to the copy
			shown in the window only, so it never resets the mod's saved values
		"""
		pass