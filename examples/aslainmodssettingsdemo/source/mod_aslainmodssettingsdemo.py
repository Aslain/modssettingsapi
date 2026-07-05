# -*- coding: utf-8 -*-
"""Demo / test mod for aslainMenu (Aslain's ModsSettings API).

Showcases the features aslainMenu added on top of the original izeberg menu, for manual
testing and as a copy-paste reference:
  - every common control type
  - createControlsGroup (sub-options greyed while the master is off)
  - enableWhen + all conditions (==, !=, >, >=, <, <=) and the CONDITION constants
  - visibleWhen (hide + reflow instead of greying)
  - enableWhenAll / enableWhenAny / visibleWhenAll / visibleWhenAny (multi-master AND/OR)
  - sprite-sheet atlas animation (createImage atlas=...), shown/hidden by visibleWhen
  - getVersion() version-gating + settingsVersion
  - createHotkey(float='right') long-label wrap
  - a Language dropdown that reloads the mod in place (reloadModTemplate) and re-wraps the
    long labels in the picked language, plus a toggle that grows/shrinks column 1 above the
    long wrapping rows - both to test that wrapping/layout survive a live reflow
  - templates.escape() for literal <, >, & in HTML labels
  - markNew (1.6.0): "new option" red flare + per-mod counter, cleared by clicking the
    row or changing its value; covers every trigger type, a hidden (visibleWhen) row
    and a greyed (group) row. NOTE: a fresh install of this demo never lights up - to
    see the highlights, the demo must have been registered before (or delete only this
    linkage's entry from 'seenFeatures' in aslainmenu.dat).
  - markNew token (1.6.0): the language dropdown passes token=str(len(LANG_NAMES)), so
    it re-lights whenever a language is ADDED (the token changes) even for users who
    already dismissed it - the pattern for a dropdown whose content grows over versions.

Every aslainMenu-only call is feature-detected with hasattr(), so the mod still loads (with
fewer demos) on the plain izeberg menu or an older aslainMenu build.
"""
import BigWorld
import Keys

try:
    from gui.aslainMenu import g_modsSettingsApi, templates
except ImportError:
    try:
        from gui.modsSettingsApi import g_modsSettingsApi, templates
    except ImportError:
        g_modsSettingsApi = None
        templates = None

try:
    from gui.aslainMenu import CONDITION
except ImportError:
    CONDITION = None

LINKAGE = 'aslain.modssettingsdemo'
PREVIEW_ICON = 'gui/maps/icons/aslainMenu/icon.png'
ATLAS_SRC = 'gui/maps/icons/aslainmodssettingsdemo/illuminati.png'
ATLAS_FRAME = 96
ATLAS_COLS = 4
ATLAS_COUNT = 16
ATLAS_FPS = 20

KEY_ALT = -1
KEY_CONTROL = -2
KEY_SHIFT = -3

LONG_LABEL = ('This is a very long hotkey description label, used to test how the key box '
              'and the wrapped caption share the row when the text will not fit on one line')
TIP = '{HEADER}Tooltip{/HEADER}{BODY}Info icon shown next to the control label.{/BODY}'
DD_OPTIONS = ['Custom', 'Blue', 'Pink', 'Red', 'Gold', 'Green', 'Violet', 'Dark']

# Rows added live under a checkbox, to exercise reloadModTemplate + height reflow.
BLOCKS = [('blkA', 'Block A (+1 row)', 1), ('blkB', 'Block B (+3 rows)', 3)]

# Language switch demo - a TEST HARNESS for reloadModTemplate, NOT a fully localized mod:
# only the labels relevant to the reload / wrapping test are translated (the long wrapping
# labels plus the column-test labels); the rest of the ~50-control showcase stays English on
# purpose. A real mod localizes the same way - it translates just the strings it chooses via
# a table like this and calls reloadModTemplate. Each language gives the long labels a
# different length so you can check they re-wrap correctly on reload. Native names; unicode
# via \u escapes so the source stays plain ASCII on disk while the menu shows the accents.
LANG_NAMES = [u'English', u'Deutsch', u'Polski', u'Français']

TR = {
    'lang': [u'Menu language (reloads the mod in place)',
             u'Menüsprache (lädt den Mod direkt neu)',
             u'Język menu (przeładowuje mod w miejscu)',
             u'Langue du menu (recharge le mod sur place)'],
    'colHead': [u'--- Column-1 length test ---',
                u'--- Längentest Spalte 1 ---',
                u'--- Test długości kolumny 1 ---',
                u'--- Test longueur colonne 1 ---'],
    'colToggle': [u'Add rows here (grow column 1)',
                  u'Zeilen hinzufügen (Spalte 1)',
                  u'Dodaj wiersze (kolumna 1)',
                  u'Ajouter des lignes (colonne 1)'],
    'longHotkey': [
        u'This is a very long hotkey description label, used to test how the key box and the '
        u'wrapped caption share the row when the text will not fit on one line',
        u'Dies ist eine sehr lange Hotkey-Beschriftung, mit der getestet wird, wie sich das '
        u'Tastenfeld und die umgebrochene Beschriftung die Zeile teilen, wenn der Text nicht '
        u'in eine einzige Zeile passt',
        u'To jest bardzo długa etykieta opisu klawisza skrótu, użyta do sprawdzenia, '
        u'jak pole klawisza i zawinięty podpis dzielą wiersz, gdy tekst nie mieści '
        u'się w jednej linii',
        u'Ceci est une étiquette de raccourci très longue, utilisée pour tester '
        u'comment la touche et la légende renvoyée partagent la ligne quand le texte ne '
        u'tient pas sur une seule ligne'],
    'longCbc': [
        u'A long label to test wrapping onto its own extra lines under the checkbox',
        u'Eine lange Beschriftung zum Testen des Zeilenumbruchs auf eigene Zusatzzeilen unter '
        u'dem Kontrollkästchen',
        u'Długa etykieta do testu zawijania na własne dodatkowe linie pod polem wyboru',
        u'Une longue étiquette pour tester le renvoi à la ligne sous la case à cocher'],
}


def _gate(name, control, *args, **kw):
    if templates is not None and hasattr(templates, name):
        return getattr(templates, name)(control, *args, **kw)
    return control


def _new(control, token=None):
    """templates.markNew on 1.6.0+, a no-op passthrough on older builds. token (optional)
    re-lights the row when it changes - for a control whose content grew, not a new one."""
    if templates is not None and hasattr(templates, 'markNew'):
        return templates.markNew(control, token)
    return control


def _cond(name, fallback):
    return getattr(CONDITION, name, fallback) if CONDITION is not None else fallback


def _hotkey(text, varName, value, **kw):
    """createHotkey, dropping the aslainMenu-only float= kwarg on API builds that lack it."""
    try:
        return templates.createHotkey(text, varName, value, **kw)
    except TypeError:
        kw.pop('float', None)
        return templates.createHotkey(text, varName, value, **kw)


def _esc(text):
    """templates.escape if the API has it, else escape inline (older builds)."""
    if templates is not None and hasattr(templates, 'escape'):
        return templates.escape(text)
    return text.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')


def _try(fn, *args, **kw):
    """Call fn, dropping the useHTML kwarg on API builds that don't accept it."""
    try:
        return fn(*args, **kw)
    except TypeError:
        kw.pop('useHTML', None)
        return fn(*args, **kw)


class Demo(object):

    def __init__(self):
        # Current menu language index (see LANG_NAMES); picking another in the dropdown
        # reloads the mod in place, so it is the source of truth, not a saved value.
        self.lang = 0
        self.state = {
            'dChk': True, 'dRadio': 0, 'dDrop': 1, 'dSlider': 5, 'dStep': 1,
            'dInput': 'hello', 'dNum': 10, 'dColor': 'FFCC00',
            'ewMaster': 5,
            'vwMode': 0,
            'masterChk': True, 'grpVol': 5,
            'mcA': 7, 'mcB': True,
            'previewMode': 0, 'iconSize': 50,
            'demoLang': 0, 'demoColGrow': False,
            'demoColR1': 5, 'demoColR2': 5, 'demoColR3': 5,
            'dccDmg': {'enabled': True, 'color': 'F23030'},
            'dccLong': {'enabled': False, 'color': '30A0F2'},
            'dccGated': {'enabled': True, 'color': '40D040'},
            'dccMaster': True,
            'dccColMaster': {'enabled': True, 'color': 'F2A030'},
            'dccColChild': 5,
        }
        for var, _label, _n in BLOCKS:
            self.state[var] = False

        if g_modsSettingsApi is None or templates is None:
            return

        g_modsSettingsApi.setModTemplate(LINKAGE, self._template(), self._onApply)

        # Re-render the mod in place the moment the language dropdown changes (before Apply),
        # to exercise reloadModTemplate + the long-label re-wrap. fullsettings=False delivers
        # only the changed keys; guard both, so the demo still loads on older API builds.
        if hasattr(g_modsSettingsApi, 'registerLiveSettingsChange'):
            try:
                g_modsSettingsApi.registerLiveSettingsChange(LINKAGE, self._onLive, fullsettings=False)
            except TypeError:
                g_modsSettingsApi.registerLiveSettingsChange(LINKAGE, self._onLive)

    def _L(self, key):
        row = TR.get(key)
        if not row:
            return key
        return row[self.lang] if self.lang < len(row) else row[0]

    def _onLive(self, linkage, changed):
        if linkage != LINKAGE or not isinstance(changed, dict):
            return
        if 'demoLang' in changed:
            newLang = int(changed['demoLang'])
            if newLang != self.lang and hasattr(g_modsSettingsApi, 'reloadModTemplate'):
                self.lang = newLang
                g_modsSettingsApi.reloadModTemplate(LINKAGE, self._template())

    def _apiVersion(self):
        fn = getattr(g_modsSettingsApi, 'getVersionTuple', None)
        return fn() if fn else (0, 0, 0)

    def _versionLabel(self):
        fn = getattr(g_modsSettingsApi, 'getVersion', None)
        return '--- aslainMenu demo (API v%s) ---' % (fn() if fn else '?')

    def _template(self, values=None):
        st = dict(self.state)
        if values:
            st.update(values)

        EQ = _cond('EQUAL', '==')
        GE = _cond('GREATER_EQUAL', '>=')
        LE = _cond('LESS_EQUAL', '<=')
        NE = _cond('NOT_EQUAL', '!=')

        column1 = [
            templates.createLabel(self._versionLabel()),
            # These new test controls are also flagged with markNew, so the "new option"
            # highlight can be exercised on them too (dropdown, checkbox, and gated rows).
            # Language dropdown: changing it reloads the mod in place (see _onLive), so the
            # long labels below re-wrap in the picked language - a live re-wrap stress test.
            # token=language count demonstrates re-flare: add a language and the dropdown
            # lights up again for everyone who dismissed it (the language-dropdown use case).
            _new(templates.createDropdown(self._L('lang'), 'demoLang', LANG_NAMES, self.lang), token=str(len(LANG_NAMES))),
            # A toggle that grows/shrinks column 1 ABOVE the long wrapping rows, so its rows
            # appearing/disappearing reflows the long hotkey + CheckBoxColor labels underneath.
            templates.createLabel(self._L('colHead')),
            _new(templates.createCheckbox(self._L('colToggle'), 'demoColGrow', st['demoColGrow'])),
            _gate('visibleWhen', _new(templates.createSlider('Extra row 1', 'demoColR1', st['demoColR1'], 1, 10, 1)), 'demoColGrow', True, indent=True),
            _gate('visibleWhen', _new(templates.createSlider('Extra row 2', 'demoColR2', st['demoColR2'], 1, 10, 1)), 'demoColGrow', True, indent=True),
            _gate('visibleWhen', _new(templates.createSlider('Extra row 3', 'demoColR3', st['demoColR3'], 1, 10, 1)), 'demoColGrow', True, indent=True),
            templates.createLabel('--- Control types ---'),
            templates.createCheckbox('Checkbox', 'dChk', st['dChk'], tooltip=TIP),
            templates.createRadioButtonGroup('Radio group', 'dRadio', ['One', 'Two', 'Three'], st['dRadio']),
            templates.createDropdown('Dropdown', 'dDrop', DD_OPTIONS, st['dDrop']),
            templates.createSlider('Slider', 'dSlider', st['dSlider'], 0, 10, 1),
            templates.createStepSlider('Step slider', 'dStep', ['Low', 'Mid', 'High'], st['dStep']),
            templates.createInput('Text input', 'dInput', st['dInput']),
            templates.createNumericStepper('Numeric stepper', 'dNum', st['dNum'], 0, 100, 1, manual=True),
            templates.createColorChoice('Color choice', 'dColor', st['dColor']),
            _try(templates.createLabel, 'useHTML=False -> literal: a < b & c > d', useHTML=False),
            _hotkey('Hotkey (short)', 'dHotkey', [Keys.KEY_F2], tooltip=TIP),
            _hotkey(self._L('longHotkey'), 'dHotkeyLong',
                    [Keys.KEY_BACKSPACE, KEY_CONTROL, KEY_ALT, KEY_SHIFT], float='right'),
            templates.createEmpty(8),
            templates.createLabel('--- enableWhen: single master (drag it) ---'),
            templates.createSlider('Master value (0-10)', 'ewMaster', st['ewMaster'], 0, 10, 1),
            _gate('enableWhen', templates.createSlider('enabled when master >= 5', 'ewGe', 5, 1, 10, 1),
                  'ewMaster', 5, indent=True, condition=GE),
            _gate('enableWhen', templates.createSlider(_esc('enabled when master <= 5'), 'ewLe', 5, 1, 10, 1),
                  'ewMaster', 5, indent=True, condition=LE),
            _gate('enableWhen', templates.createSlider('enabled when master != 5', 'ewNe', 5, 1, 10, 1),
                  'ewMaster', 5, indent=True, condition=NE),
        ]

        if hasattr(templates, 'createCheckboxColor'):
            column1.append(templates.createLabel('--- CheckBoxColor: checkbox + color on one row ---'))
            column1.append(templates.createCheckboxColor('Damage', 'dccDmg', st['dccDmg']['enabled'], st['dccDmg']['color'], tooltip=TIP))
            column1.append(templates.createCheckboxColor(self._L('longCbc'), 'dccLong', st['dccLong']['enabled'], st['dccLong']['color'], tooltip=TIP))
            column1.append(templates.createCheckbox('Master: toggle to grey the 2 rows below', 'dccMaster', st['dccMaster']))
            column1.append(_gate('enableWhen', templates.createSlider('Gated slider (reference)', 'dccGateSlider', 5, 1, 10, 1), 'dccMaster', True, indent=True))
            column1.append(_gate('enableWhen',
                templates.createCheckboxColor('Gated CheckBoxColor', 'dccGated', st['dccGated']['enabled'], st['dccGated']['color'], tooltip=TIP),
                'dccMaster', True, indent=True))
            column1.append(templates.createCheckboxColor('CheckBoxColor as master: uncheck to grey the row below', 'dccColMaster', st['dccColMaster']['enabled'], st['dccColMaster']['color']))
            column1.append(_gate('enableWhen', templates.createSlider('Greyed by the checkbox+color master above', 'dccColChild', st['dccColChild'], 1, 10, 1), 'dccColMaster', True, indent=True))

        column2 = [
            templates.createLabel('--- visibleWhen: hides + reflows instead of greying ---'),
            templates.createDropdown('Mode', 'vwMode', ['Simple', 'Advanced'], st['vwMode']),
            _gate('visibleWhen', templates.createSlider('Advanced-only option', 'vwAdv', 5, 1, 10, 1),
                  'vwMode', 1, indent=True, condition=EQ),
        ]

        master = templates.createCheckbox('Enable group', 'masterChk', st['masterChk'])
        child = templates.createSlider('Group volume', 'grpVol', st['grpVol'], 1, 10, 1)
        column2.append(templates.createLabel('--- createControlsGroup (master on/off) ---'))
        if hasattr(templates, 'createControlsGroup'):
            column2 += templates.createControlsGroup(master, [child])
        else:
            column2 += [master, child]

        condsAB = [{'varName': 'mcA', 'condition': GE, 'value': 5}, {'varName': 'mcB', 'value': True}]
        column2.append(templates.createLabel('--- Multi-condition: master A >= 5  +  master B ---'))
        column2.append(templates.createSlider('Master A (0-10)', 'mcA', st['mcA'], 0, 10, 1))
        column2.append(templates.createCheckbox('Master B', 'mcB', st['mcB']))
        column2.append(_gate('enableWhenAll', templates.createSlider('enabled when A>=5 AND B', 'mcAndE', 5, 1, 10, 1), condsAB, indent=True))
        column2.append(_gate('enableWhenAny', templates.createSlider('enabled when A>=5 OR B', 'mcOrE', 5, 1, 10, 1), condsAB, indent=True))
        column2.append(_gate('visibleWhenAll', templates.createSlider('shown when A>=5 AND B', 'mcAndV', 5, 1, 10, 1), condsAB, indent=True))
        column2.append(_gate('visibleWhenAny', templates.createSlider('shown when A>=5 OR B', 'mcOrV', 5, 1, 10, 1), condsAB, indent=True))

        column2.append(templates.createLabel('--- Image: static icon vs animated atlas, switched by visibleWhen ---'))
        column2.append(templates.createRadioButtonGroup('Preview', 'previewMode', ['Icon', 'Animated', 'None'], st['previewMode']))
        if hasattr(templates, 'createImage'):
            icon = templates.createImage(
                PREVIEW_ICON, st['iconSize'], st['iconSize'],
                varName='previewIcon', align='center', valign='center',
                containerWidth=120, containerHeight=120,
                label='Static icon', labelAlign='center')
            column2.append(_gate('visibleWhen', icon, 'previewMode', 0))
            if hasattr(g_modsSettingsApi, 'updateImageAtlas'):
                anim = templates.createImage(
                    '', ATLAS_FRAME, ATLAS_FRAME,
                    varName='previewAtlas', align='center', valign='center',
                    containerWidth=120, containerHeight=120,
                    label='Illuminati (animated)', labelAlign='center',
                    atlas={'source': ATLAS_SRC, 'frameWidth': ATLAS_FRAME, 'frameHeight': ATLAS_FRAME,
                           'columns': ATLAS_COLS, 'count': ATLAS_COUNT, 'fps': ATLAS_FPS, 'loop': True})
                column2.append(_gate('visibleWhen', anim, 'previewMode', 1))

        column2.append(templates.createLabel('--- Conditional rows: shown via visibleWhen on a checkbox ---'))
        for var, label, n in BLOCKS:
            column2.append(templates.createCheckbox(label, var, bool(st[var])))
            for i in range(n):
                row = templates.createSlider('%s row %d' % (var, i + 1), '%s_%d' % (var, i), 5, 1, 10, 1)
                column2.append(_gate('visibleWhen', row, var, True, indent=True))

        # markNew (1.6.0): red flare on the row + a red counter next to the mod title.
        # Cleared by clicking anywhere on the row (label included) OR changing the value.
        # One row per trigger type, plus a hidden and a greyed row for the edge cases.
        if hasattr(templates, 'markNew'):
            column2.append(templates.createLabel('--- markNew: red flare + title counter (1.6.0) ---'))
            column2.append(_new(templates.createCheckbox('New checkbox (click its label to clear)', 'nfChk', True)))
            column2.append(_new(templates.createSlider('New slider (drag to clear)', 'nfSlider', 5, 1, 10, 1)))
            column2.append(_new(templates.createDropdown('New dropdown (pick to clear)', 'nfDrop', ['One', 'Two'], 0)))
            column2.append(_new(templates.createColorChoice('New color (open picker to clear)', 'nfColor', '30A0F2')))
            column2.append(_new(_hotkey('New hotkey (rebind or click to clear)', 'nfHotkey', [Keys.KEY_F3])))
            column2.append(templates.createCheckbox('Reveal the hidden new option below', 'nfReveal', False))
            column2.append(_gate('visibleWhen',
                _new(templates.createSlider('Hidden new option (counted while hidden)', 'nfHidden', 5, 1, 10, 1)),
                'nfReveal', True, indent=True))
            nfMaster = templates.createCheckbox('Group master (off = new row below not clickable)', 'nfGrpMaster', False)
            nfChild = _new(templates.createSlider('Greyed new option (enable master first)', 'nfGrpChild', 5, 1, 10, 1))
            if hasattr(templates, 'createControlsGroup'):
                column2 += templates.createControlsGroup(nfMaster, [nfChild])
            else:
                column2 += [nfMaster, nfChild]

        # Title kept constant on purpose: reloadModTemplate only takes the fast IN-PLACE
        # reconcile path (reuse unchanged controls, rebuild only what changed) while the
        # mod's display name is unchanged. Changing it would force a full rebuild instead -
        # the language switch here exercises the in-place path other mods use.
        return {
            'modDisplayName': 'aslainMenu Demo (features)',
            'settingsVersion': 12,
            'enabled': True,
            'column1': column1,
            'column2': column2,
        }

    def _onApply(self, linkage, settings):
        if linkage != LINKAGE:
            return
        self.state.update(settings)
        if 'demoLang' in settings:
            self.lang = int(settings['demoLang'])


g_demo = Demo()
