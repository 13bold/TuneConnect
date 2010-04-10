# TuneConnect Server 2.0, conformant to Tunage API 1.1
# Copyright (C) 2007 - 2008 Matt Patenaude
# Inspired by code by Jon Berg (turtlemeat.com)
# Powered by Twisted

import sys, re
from os import path, fstat, walk, chdir, getcwd
from twisted.web import server, resource, static
from twisted.internet import reactor
from json import json
from time import time
import pybonjour
import socket
import hashlib
import plistlib

#from twisted.python.log import startLogging; startLogging(sys.stdout)

# Swap the next two lines' commenting to change platform
platform = "Mac"
#platform = "Win"

if platform == "Mac":
	from iTunesLibrary_mac import iTunesLibrary
	from tc_mac import iTunesAccessor, libraryFile, artworkFile, pluginDirs
	from Foundation import *
	
	prefLocation = path.expanduser("~/Library/Preferences/net.tuneconnect.Server.plist")
elif platform == "Win":
	from iTunesLibrary_win import iTunesLibrary
	from tc_win import iTunesAccessor, libraryFile, artworkFile, pluginDirs
	
	prefLocation = "settings.plist"

defaults = {'libraryExpiryTime':86400, 'password':'', 'port':4242, 'useLibraryFile':True, 'dsThreshold':.6}

# Time to check our settings file, and create if non-existent with the defaults
if not path.exists(prefLocation):
	plistlib.writePlist(defaults, prefLocation)
	prefs = defaults
else:
	if platform == "Mac":
		prefs = NSDictionary.dictionaryWithContentsOfFile_(prefLocation)
	else:
		prefs = plistlib.readPlist(prefLocation)

# Somehow, get server port and password into these variables
password = prefs['password'] if not (prefs['password'] == "") else None
port = int(prefs['port'])
libraryExpiryTime = int(prefs['libraryExpiryTime'])	# time in seconds after which a loaded library should be dubbed invalid
useLibraryFile = bool(prefs['useLibraryFile'])		# set to False to proxy all track info directly from iTunes
dsThreshold = float(prefs['dsThreshold']) if (prefs.has_key('dsThreshold')) else defaults['dsThreshold']


# To override system locations of library and artwork files, uncomment these lines
#libraryFile = path.expanduser("~/Music/iTunes/iTunes Music Library.xml")
#artworkFile = '/tmp/iTunes_artwork'
#pluginDirs = ["../PlugIns", path.expanduser("~/Library/Application Support/TuneConnect Server")]

class TCServer(resource.Resource):
	isLeaf = True
	iTunes = None
	
	serverURIs = None
	serverInfo = None
	
	dsThreshold = 0
	
	lastCommand = ""
	lastParams = ""
	lastCommandTime = None
	lastResponse = ""
	
	idempotent = ["artwork"]
	
	def __init__(self, password, localLibrary, artworkFile, pluginClasses, dsThreshold):
		resource.Resource.__init__(self)
		self.iTunes = iTunesAccessor(localLibrary, artworkFile)
		self.serverURIs = {'serverInfo.txt': self.provideServerInfo, 'getAuthKey': self.getAuthKey}
		self.pluginURIs = {}
		self.plugins = []
			
		if password:
			reqPass = True
		else:
			reqPass = False
		
		self.serverInfo = {"version": 1.2, "suffix": "", "requiresPassword":reqPass, "supportsArtwork":True, "extensions":[]}
		
		self.dsThreshold = dsThreshold
		
		for pluginClass in pluginClasses:
			plugin = pluginClass(self.iTunes, reactor)
			self.plugins.append(plugin)
			methodDict = plugin.methods()
			self.pluginURIs.update(methodDict)
			self.serverInfo['extensions'].extend(methodDict.keys())
	
	def parseURI(self, uri):
		baseLookup = re.compile('.*?/')
		urlParts = uri.split('?', 1)
		urlBase = baseLookup.sub('', urlParts[0], 1)
		partDict = {}
		if len(urlParts) > 1:
			urlParts[1] = urlParts[1].split('&')
			for part in urlParts[1]:
				param = part.split('=', 1)
				partDict[param[0]] = param[1]
		
		return urlBase, partDict
	
	def send404(self, request):
		request.setResponseCode(404)
		return self.sendJSON({"error":True}, request)
	
	def send400(self, request):
		request.setResponseCode(400, "Parameter Error")
		return self.sendJSON({"error":True}, request)

	def sendJSON(self, jObj, request):
		methodName, params = self.parseURI(request.uri)

		if (params.has_key('asPlist') and params['asPlist'] == '1'):
			request.setHeader('Content-type', 'text/xml')
			return plistlib.writePlistToString(jObj)
		else:
			request.setHeader('Content-type', 'text/plain')
			return json.write(jObj).replace('\\\\', '\\')
	
	def render_GET(self, request):
		methodName, params = self.parseURI(request.uri)
		
		#print "Request: %s, %f" % (request.uri, time())
		
		if (self.lastCommand == methodName) and (self.lastParams == params) and not (methodName in self.idempotent):
			if (time() - self.lastCommandTime) < self.dsThreshold:
				print "CFNetwork/NSURLConnection bugfix applied... (%f)" % (time() - self.lastCommandTime)
				if (params.has_key('asPlist') and params['asPlist'] == '1'):
					request.setHeader('Content-type', 'text/xml')
				else:
					request.setHeader('Content-type', 'text/plain')
				return self.lastResponse
		
		self.lastCommand = methodName
		self.lastParams = params
		self.lastCommandTime = time()
		
		if self.pluginURIs.has_key(methodName) and callable(self.pluginURIs[methodName]):
			if not self.authorizationValid(params, request):
				request.setResponseCode(403, "Invalid AuthKey")
				self.lastResponse = self.sendJSON({"error":True}, request)
				return self.lastResponse
			self.lastResponse = self.pluginURIs[methodName](params, request)
			return self.lastResponse
		
		if self.serverURIs.has_key(methodName):
			self.lastResponse = self.serverURIs[methodName](params, request)
			return self.lastResponse
			
		if self.iTunes.methods.has_key(methodName) and callable(self.iTunes.methods[methodName]):
			if not self.authorizationValid(params, request):
				request.setResponseCode(403, "Invalid AuthKey")
				self.lastResponse = self.sendJSON({"error":True}, request)
				return self.lastResponse
			self.lastResponse = self.iTunes.methods[methodName](params, request)
			return self.lastResponse
		
		if path.exists(methodName):
			ftype = 'text/plain'
			if methodName.endswith('.png'):
				ftype = 'image/png'
			elif methodName.endswith('.html'):
				ftype = 'text/html'
			elif methodName.endswith('.js'):
				ftype = 'text/javascript'
			elif methodName.endswith('.css'):
				ftype = 'text/css'
				
			f = open(methodName, 'rb')
			request.setHeader("Content-type", ftype)
			request.setHeader("Content-Length", str(fstat(f.fileno())[6]))
			request.write(f.read(fstat(f.fileno())[6]))
			
			f.close()
			return
		
		# Perform some UA checking to go to the appropriate page from base URL
		# Currently, just redirects to generic web interface
		request.setResponseCode(302, "Found")
		
		uaLook = re.compile("iPod|iPhone")
		if (uaLook.search(request.getHeader("User-agent"))):
			request.setHeader("Location", request.prePathURL() + "web/iphone/index.html")
		else:
			request.setHeader("Location", request.prePathURL() + "web/index.html")
		return "Redirecting to web client..."
	
	def authorizationValid(self, params, request):
		if request.getClientIP() == "127.0.0.1":
			return True
		
		global password
		if password:
			authKey = hashlib.sha1(password + request.getClientIP()).hexdigest()
			if not params.has_key('authKey') or not params['authKey'] == authKey:
				return False
		return True
	
	def provideServerInfo(self, params, request):
		return self.sendJSON(self.serverInfo, request)
	
	def getAuthKey(self, params, request):
		global password
		
		if not params.has_key('password'):
			return self.send400(request)
		
		if password and password == params['password']:
			authKey = hashlib.sha1(password + request.getClientIP()).hexdigest()
			return self.sendJSON({"authKey":authKey}, request)
		else:
			return self.sendJSON({"authKey":False}, request)

class QuitCommand(Exception):
	def __init__(self):
		pass

def main():
	try:
		global password, port, libraryFile, artworkFile, pluginDirs, libraryExpiryTime, useLibraryFile, reactor, platform, dsThreshold
		keep_running = True
		
		nextIsPass = False
		nextIsPort = False
		
		for arg in sys.argv:
			if arg == "--password":
				nextIsPass = True
			elif arg == "--port":
				nextIsPort = True
			elif nextIsPass:
				password = hashlib.sha1(arg).hexdigest()
				nextIsPass = False
			elif nextIsPort:
				port = int(arg)
				nextIsPort = False
		
		if useLibraryFile and path.exists(libraryFile):
			libFile = iTunesLibrary(libraryFile, libraryExpiryTime)
		else:
			libFile = None
		
		# Let's load our plugins. Yay!
		pluginClasses = []
		
		for pluginDir in pluginDirs:
			if path.exists(pluginDir):
				sys.path.append(path.abspath(pluginDir))
				#print ("Found plug-in dir! -- " + pluginDir)
				for root, dirs, files in walk(pluginDir):
					plugins = [plugin for plugin in files if plugin.endswith('_plugin.py')]
					for plugin in plugins:
						plugin = plugin.replace('.py', '')
						#print ("Found a plug-in -- " + plugin)
						pRoot = __import__(plugin, globals(), locals(), [], 0)
						if (pRoot.classTable.has_key(platform)):
							pluginClasses.append(pRoot.classTable[platform])
		
		
		root = TCServer(password, libFile, artworkFile, pluginClasses, dsThreshold)
		site = server.Site(root)
		reactor.listenTCP(port, site)
		
		print 'started httpserver...'
		
		if platform == "Mac":
			config = NSDictionary.dictionaryWithContentsOfFile_('/Library/Preferences/SystemConfiguration/preferences.plist')
			hostname = config['System']['System']['ComputerName']
		else:
			hostname = socket.gethostname()
		
		bonjourService = pybonjour.DNSServiceRegister(
			name = hostname,
			regtype = '_tunage._tcp',
			port = port)
		bonjourWeb = pybonjour.DNSServiceRegister(
			name = hostname + " TuneConnect Server",
			regtype = '_http._tcp',
			port = port)
		
		reactor.run()
		
		print 'termination command received, shutting down server'
		bonjourService.close()
		bonjourWeb.close()
		return
	except KeyboardInterrupt, QuitCommand:
		print 'termination command received, shutting down server'
		reactor.stop()
		bonjourService.close()
		bonjourWeb.close()
		return

if __name__ == '__main__':
	main()