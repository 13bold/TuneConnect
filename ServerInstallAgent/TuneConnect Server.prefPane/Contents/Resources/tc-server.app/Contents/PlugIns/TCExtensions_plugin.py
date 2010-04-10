# TCExtensions (Mac edition)
# A part of TuneConnect Server 2

import plistlib
from json import json
import re
from appscript import *

class TCExtensions_template(object):
	def __init__(self, iTunesAccessor, reactor):
		self.methodList = {'tc.shutdownNow': self.shutdown, 'tc.status': self.heartbeat, 'tc.clearCache': self.clearLibraryCache}
		self.reactor = reactor
		self.iTunes = iTunesAccessor
		#print "Plugin loaded"
	
	def methods(self):
		return self.methodList
	
	def shutdown(self, params, request):
		if request.getClientIP() == "127.0.0.1":
			self.reactor.stop()
		else:
			request.setResponseCode(403, "Forbidden")
			return self.sendJSON({"error":True}, request)

	def heartbeat(self, params, request):
		return "Server Running"
	
	def clearLibraryCache(self, params, request):
		if self.iTunes.localLibrary != None:
			self.iTunes.localLibrary.expire()
		
		return self.sendJSON({"success":True}, request)
	
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
	
	def sendJSON(self, jObj, request):
		methodName, params = self.parseURI(request.uri)

		if (params.has_key('asPlist') and params['asPlist'] == '1'):
			request.setHeader('Content-type', 'text/xml')
			return plistlib.writePlistToString(jObj)
		else:
			request.setHeader('Content-type', 'text/plain')
			return json.write(jObj).replace('\\\\', '\\')

class TCExtensions_Mac(TCExtensions_template):
	def __init__(self, iTunesAccessor, reactor):
		TCExtensions_template.__init__(self, iTunesAccessor, reactor)
		self.methodList['tc.queueTrackToPlaylist'] = self.queueTrackToPlaylist
		
	# Extensions #

	# Queue Track to Playlist:
	# Usage: /tc.queueTrackToPlaylist?[track=(trackRef)]&toPlaylist=(playlistRef)
	#   If playlist is currently being played from, adds track as next song in play order.
	#   If playlist is not being played from, adds track to beginning of playlist.
	# Thanks to Nicholas Jitkoff for the AppleScript equivalent of below
	def queueTrackToPlaylist(self, params, request):
		iTunes = self.iTunes.iTunesCheck()

		if not params.has_key('toPlaylist'):
			return self.iTunes.send400(request)

		if not params.has_key('track'):
			track = iTunes.current_track
		else:
			trackID, playlistID, sourceID = params['track'].split(':', 3)
			track = iTunes.sources.ID(sourceID).playlists.ID(playlistID).tracks[its.database_ID == int(trackID)]

		destPlaylist, destSource = params['toPlaylist'].split(':', 2)
		playlist = iTunes.sources.ID(destSource).playlists.ID(destPlaylist)

		try:
			isPlaying = (iTunes.current_track.container.get() == playlist.get())
			if (isPlaying):
				startIndex = iTunes.current_track.index.get()
			else:
				startIndex = 0
		except:
			isPlaying = False
			startIndex = 0

		maxIndex = playlist.count(each=k.track)

		track.duplicate(to=playlist)
		playlist.tracks[(its.index > startIndex).AND(its.index <= maxIndex)].duplicate()
		playlist.tracks[(its.index > startIndex).AND(its.index <= maxIndex)].delete()

		return self.iTunes.sendJSON({"success":True}, request)

# Don't forget to specify a classTable variable!
classTable = {"Mac":TCExtensions_Mac}