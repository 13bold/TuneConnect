"""
This is a setup.py script generated by py2applet

Usage:
    python setup.py py2app
"""

from setuptools import setup

APP = ['tc-server.py']
DATA_FILES = ['web']
OPTIONS = {'argv_emulation': True, 'plist': {
		'CFBundleIdentifier': 'net.tuneconnect.Server',
		'LSBackgroundOnly': True,
		'LSUIElement': True,
		'CFBundleVersion': '2.1',
		'NSHumanReadableCopyright': u'\u00A9 The TuneConnect Project, 2007 - 2008'
	},
	'iconfile': 'TuneConnect-Server.icns'
}

setup(
    app=APP,
    data_files=DATA_FILES,
    options={'py2app': OPTIONS},
    setup_requires=['py2app'],
)
