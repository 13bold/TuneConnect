# TuneConnect Server 2.0, conformant to Tunage API 1.1
# Copyright (C) 2007 Matt Patenaude
# iTunes Accessor Class Template

from json import json
import plistlib
import re

class iTunesAccessorTemplate:
	methods = None
	lastArtwork = None
	libraryFile = None
	artworkFile = None
	
	def __init__(self, libraryFile, artworkFile):
		self.libraryFile = libraryFile
		self.artworkFile = artworkFile
		
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
			return plistlib.writePlistToString(jObj).decode('unicode_escape').encode('ascii', 'xmlcharrefreplace')
		else:
			request.setHeader('Content-type', 'text/plain')
			return json.write(jObj).replace('\\\\', '\\')