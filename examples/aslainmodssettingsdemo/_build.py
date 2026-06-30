# -*- coding: utf-8 -*-
import os, py_compile, zipfile, shutil

HERE = os.path.dirname(os.path.abspath(__file__))
VERSION = '1.0.2'
SRC = os.path.join(HERE, 'source', 'mod_aslainmodssettingsdemo.py')
BUILD = os.path.join(HERE, 'build')
PYC = os.path.join(BUILD, 'mod_aslainmodssettingsdemo.pyc')
WOTMOD = os.path.join(HERE, 'aslain.modssettingsdemo_' + VERSION + '.wotmod')

META = (
    '<root>\n'
    '\t<id>aslain.modssettingsdemo</id>\n'
    '\t<version>' + VERSION + '</version>\n'
    '\t<name>aslainMenu Demo</name>\n'
    '\t<description>Demo and test mod for the aslainMenu features of modsSettingsApi</description>\n'
    '</root>\n'
)

if os.path.isdir(BUILD):
    shutil.rmtree(BUILD)
os.makedirs(BUILD)

py_compile.compile(SRC, cfile=PYC, dfile='mod_aslainmodssettingsdemo.py', doraise=True)

if os.path.isfile(WOTMOD):
    os.remove(WOTMOD)

z = zipfile.ZipFile(WOTMOD, 'w', zipfile.ZIP_STORED)
z.writestr('meta.xml', META)
z.write(PYC, 'res/scripts/client/gui/mods/mod_aslainmodssettingsdemo.pyc')
z.write(os.path.join(HERE, 'assets', 'illuminati.png'), 'res/gui/maps/icons/aslainmodssettingsdemo/illuminati.png')
z.close()

print('OK -> ' + WOTMOD)
