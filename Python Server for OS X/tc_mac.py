# TuneConnect Server 2.0, conformant to Tunage API 1.1
# Copyright (C) 2007 Matt Patenaude
# iTunes Accessor Code for Mac

from iTunesAccessorClass import iTunesAccessorTemplate
from appscript import *
import string, hashlib, re, base64
from os import system, fstat, path
from json import json
from Foundation import *

# Default system locations for library and artwork files
#libraryFile = path.expanduser("~/Music/iTunes/iTunes Music Library.xml")
libraryFile = path.expanduser(str(NSDictionary.dictionaryWithContentsOfFile_(path.expanduser("~/Library/Preferences/com.apple.iApps.plist"))['iTunesRecentDatabasePaths'][0]))
artworkFile = '/tmp/iTunes_artwork'
pluginDirs = ["../PlugIns", path.expanduser("~/Library/Application Support/TuneConnect Server")]

def cleanName(name):
	if (type(name) != type(u"Unicode")):
		return name
	else:
		return string.replace(repr(name)[2:-1], '\\x', '\\u00')
	return repr(name)[2:-1]

def className(name):
	return str(name)[2:]

class iTunesAccessor(iTunesAccessorTemplate):
	iTunes = None
	lastArtwork = None
	lastArtworkData = None
	localLibrary = None
	artworkFile = None
	
	def __init__(self, localLibrary, artworkFile):
		self.methods = {'artwork':self.artwork, 'getSources':self.getSources, 'preload':self.preload, 'getPlaylists':self.getPlaylists,  'getTracks':self.getTracks, 'hydrate':self.hydrate, 'signature':self.signature, 'getArtists':self.getArtists, 'getAlbums':self.getAlbums, 'getGenres':self.getGenres, 'getComposers':self.getComposers, 'play':self.play, 'pause':self.pause, 'playPause':self.playPause, 'stop':self.stop, 'playPlaylist':self.playPlaylist, 'playTrack':self.playTrack, 'nextTrack':self.nextTrack, 'prevTrack':self.prevTrack, 'setVolume':self.setVolume, 'volumeUp':self.volumeUp, 'volumeDown':self.volumeDown, 'currentTrack':self.currentTrack, 'playerStatus':self.playerStatus, 'fullStatus':self.fullStatus, 'playSettings':self.playSettings, 'setPlayerPosition':self.setPlayerPosition, 'setPlaySettings':self.setPlaySettings, 'search':self.search, 'EQSettings':self.EQSettings, 'EQPresets':self.EQPresets, 'setEQState':self.setEQState, 'setEQBand':self.setEQBand, 'setEQPreset':self.setEQPreset, 'visuals':self.visuals, 'visualSettings':self.visualSettings, 'setVisualizations':self.setVisualizations, 'setTrackName':self.setTrackName, 'setTrackArtist':self.setTrackArtist, 'setTrackAlbum':self.setTrackAlbum, 'setTrackRating':self.setTrackRating, 'setTrackGenre':self.setTrackGenre, 'setTrackComposer':self.setTrackComposer, 'setTrackComments':self.setTrackComments, 'createPlaylist':self.createPlaylist, 'addTrackToPlaylist':self.addTrackToPlaylist, 'deleteTrackFromPlaylist':self.deleteTrackFromPlaylist, 'deletePlaylist':self.deletePlaylist}
		self.localLibrary = localLibrary
		self.artworkFile = artworkFile
		self.compare = {
			'eq': lambda b,a: a == b,
			'c': lambda b,a: a.find(b) > -1,
			'-eq': lambda b,a: a != b,
			'-c': lambda b,a: a.find(b) == -1,
			'gt': lambda b,a: a > b,
			'gte': lambda b,a: a >= b,
			'lt': lambda b,a: a < b,
			'lte': lambda b,a: a <= b
		}
	
	def iTunesCheck(self):
		if self.iTunes == None:
			self.iTunes = app('iTunes')
			if self.localLibrary != None:
				self.localLibrary.expire()
		
		try:
			v = self.iTunes.version.get()
		except:
			# We couldn't get the iTunes version, so we have an old reference
			# Let's re-dispatch!
			self.iTunes = app('iTunes')
			if self.localLibrary != None:
				self.localLibrary.expire()
		
		return self.iTunes
	
	def artwork(self, params, request):
		iTunes = self.iTunesCheck()
		
		try:
			artworks = iTunes.current_track.artworks.get()
		except:
			artworks = []
		
		if len(artworks) > 0:
			artwork = artworks[0].get()
			format = str(artwork.format.get())
			if string.find(format, "JPEG") != -1 or string.find(format,'JPG') != -1:
				type = "image/jpeg"
			elif string.find(format, 'GIF') != -1:
				type = "image/gif"
			elif string.find(format, 'PNG') != -1:
				type = "image/png"
			else:
				return self.send404(request)
			
			#fname = self.artworkFile
			
			if self.lastArtwork is None or self.lastArtwork != iTunes.current_track.album.get():
				#system("osascript SaveArtwork.scpt")
				dataString = artwork.data.get().data
				#f = open(fname, 'wb')
				#f.write(dataString[222:])
				#f.close()
				self.lastArtwork = iTunes.current_track.album.get()
				# Take a slice to chop off the PICT header
				self.lastArtworkData = dataString[222:]

			#try:
			#	f = open(fname, 'rb')
			#except IOError:
			#	return self.send404(request)
				
			request.setHeader("Content-type", type)
			#request.setHeader("Content-Length", str(fstat(f.fileno())[6]))
			request.setHeader("Content-Length", str(len(self.lastArtworkData)))
			#request.write(f.read(fstat(f.fileno())[6]))
			request.write(self.lastArtworkData)
			
			#f.close()
			return
		else:
			return self.send404(request)
		return self.send404(request)
	
	def getSources(self, params, request):
		iTunes = self.iTunesCheck()
		
		sourceList = []
		for source in iTunes.sources.get():
			sourceList.append({'name':cleanName(source.name.get()), 'id':source.id.get(), 'kind':className(source.kind.get())})
		
		return self.sendJSON({'sources':sourceList}, request)
	
	def preload(self, params, request):
		iTunes = self.iTunesCheck()
		
		if not params.has_key('source'):
			return self.send400(request)
		
		source = iTunes.sources.ID(params['source'])
		if source.kind.get() == k.library and self.localLibrary != None:
			self.localLibrary.ensureReady()
		
		return self.sendJSON({'libraryReady':True}, request)
	
	def getPlaylists(self, params, request):
		iTunes = self.iTunesCheck()
		
		if not params.has_key('ofSource'):
			return self.send400(request)
			
		playlists = []
		
		source = iTunes.sources.ID(params['ofSource'])
		
		if source.kind.get() == k.library and self.localLibrary != None:
			playlists = self.localLibrary.getPlaylists(params['ofSource'], params)
		else:
			playlistSet = source.playlists.get()
			for playlist in playlistSet:
				if (params.has_key('dehydrated') and params['dehydrated'] == '1'):
					playlistObject = {'name':cleanName(playlist.name.get()), 'ref':(str(playlist.id.get()) + ':' + params['ofSource'])}
				else:
					playlistObject = {'name':cleanName(playlist.name.get()), 'id':playlist.id.get(), 'source':int(params['ofSource']), 'duration':playlist.duration.get(), 'trackCount':len(playlist.tracks.get()), 'specialKind':className(playlist.special_kind.get())}
				
					try:
						isSmart = playlist.smart.get()
					except:
						isSmart = False
				
					playlistObject['smart'] = isSmart
				
				cancelAppend = False
				version = iTunes.version.get().split('.')
				majorVersion = int(version[0])
				if (majorVersion >= 7):
					if source.kind.get() == k.library and playlist == source.library_playlists.get()[0]:
						cancelAppend = True
				
				if not cancelAppend:
					playlists.append(playlistObject)
		
		if params.has_key('range'):
			lower, upper = params['range'].split(',', 2)
			response = {'playlists':playlists[int(lower):(int(upper) + 1)]}
		else:
			response = {'playlists':playlists}
			
		return self.sendJSON(response, request)
	
	def getArtists(self, params, request):
		pass
	
	def getAlbums(self, params, request):
		pass
	
	def getGenres(self, params, request):
		pass
	
	def getComposers(self, params, request):
		pass
	
	def getTracks(self, params, request):
		iTunes = self.iTunesCheck()
		
		if not params.has_key('ofPlaylist'):
			#return self.send400(request)
			source = iTunes.sources.get()[0]
			playlist = source.library_playlists.get()[0]
			params['ofPlaylist'] = str(playlist.id.get()) + ':' + str(source.id.get())
		
		tracks = self.composeTrackArray(params, request)
		
		response = {'tracks':tracks}
		
		if (params.has_key('signature') and params['signature'] == '1'):
			response['signature'] = self.createPlaylistSignature(tracks)
		
		if params.has_key('range'):
			lower, upper = params['range'].split(',', 2)
			response['tracks'] = tracks[int(lower):(int(upper) + 1)]
		
		return self.sendJSON(response, request)
	
	def hydrate(self, params, request):
		iTunes = self.iTunesCheck()
		
		if not params.has_key('ref'):
			return self.send400(request)
		
		refParts = params['ref'].replace('%3A', ':').split(':')
		
		if (len(refParts) == 2):
			# Playlist
			playlist = iTunes.sources.ID(refParts[1]).playlists.ID(refParts[0])
			
			playlistObject = {'name':cleanName(playlist.name.get()), 'id':playlist.id.get(), 'source':int(refParts[1]), 'duration':playlist.duration.get(), 'trackCount':len(playlist.tracks.get()), 'specialKind':className(playlist.special_kind.get())}
		
			try:
				isSmart = playlist.smart.get()
			except:
				isSmart = False
		
			playlistObject['smart'] = isSmart
			
			return self.sendJSON(playlistObject, request)
		elif (len(refParts) == 3):
			# Track
			track = iTunes.sources.ID(refParts[2]).playlists.ID(refParts[1]).tracks[its.database_ID == int(refParts[0])].get()[0]
			
			trackObject = {'name':cleanName(track.name.get()), 'id':track.database_ID.get(), 'playlist':int(refParts[1]), 'source':int(refParts[2]), 'duration':track.duration.get(), 'album':cleanName(track.album.get()), 'artist':cleanName(track.artist.get()), 'videoType':className(track.video_kind.get())}
	
			if (params.has_key('genre') and params['genre'] == '1'):
				trackObject['genre'] = cleanName(track.genre.get())
	
			if (params.has_key('rating') and params['rating'] == '1'):
				trackObject['rating'] = track.rating.get()
	
			if (params.has_key('composer') and params['composer'] == '1'):
				trackObject['composer'] = cleanName(track.composer.get())
	
			if (params.has_key('comments') and params['comments'] == '1'):
				trackObject['comments'] = cleanName(track.comment.get())
		
			if (params.has_key('dateAdded') and params['dateAdded'] == '1'):
				trackObject['dateAdded'] = track.date_added.get().isoformat() + 'Z'
		
			if (params.has_key('bitrate') and params['bitrate'] == '1'):
				trackObject['bitrate'] = track.bit_rate.get()
		
			if (params.has_key('sampleRate') and params['sampleRate'] == '1'):
				trackObject['sampleRate'] = track.sample_rate.get()
		
			if (params.has_key('playCount') and params['playCount'] == '1'):
				try:
					trackObject['playCount'] = track.played_count.get()
				except:
					trackObject['playCount'] = 0
			
			return self.sendJSON(trackObject, request)
		else:
			return self.send400(request)
	
	def signature(self, params, request):
		iTunes = self.iTunesCheck()
		
		if not params.has_key('ofPlaylist'):
			#return self.send400(request)
			source = iTunes.sources.get()[0]
			playlist = source.library_playlists.get()[0]
			params['ofPlaylist'] = str(playlist.id.get()) + ':' + str(source.id.get())
		
		return self.sendJSON({'signature':self.createPlaylistSignature(self.composeTrackArray(params, request))}, request)
	
	def createPlaylistSignature(self, trackArray):
		signature = hashlib.md5(json.write(trackArray).replace('\\\\', '\\')).hexdigest()
		return signature
	
	def composeTrackArray(self, params, request):
		iTunes = self.iTunesCheck()
			
		tracks = []
		
		playlistID, sourceID = params['ofPlaylist'].replace('%3A', ':').split(':', 2)
		source = iTunes.sources.ID(sourceID)
		
		# We make a cache exemption for Party Shuffle and TCQ Playlists
		if source.kind.get() == k.library and self.localLibrary != None and source.playlists.ID(playlistID).special_kind.get() != k.Party_Shuffle and source.playlists.ID(playlistID).name.get().find('TCQ') == -1:
			tracks = self.localLibrary.getTracksForPlaylist(playlistID, sourceID, params)
		else:
			playlist = source.playlists.ID(playlistID).tracks.get()
			for track in playlist:
				if (params.has_key('dehydrated') and params['dehydrated'] == '1'):
					trackObject = {'name':cleanName(track.name.get()), 'ref':(str(track.database_ID.get()) + ':' + playlistID + ':' + sourceID)}
				else:
					trackObject = {'name':cleanName(track.name.get()), 'id':track.database_ID.get(), 'playlist':int(playlistID), 'source':int(sourceID), 'duration':track.duration.get(), 'album':cleanName(track.album.get()), 'artist':cleanName(track.artist.get()), 'videoType':className(track.video_kind.get())}
			
					if (params.has_key('genres') and params['genres'] == '1'):
						trackObject['genre'] = cleanName(track.genre.get())
			
					if (params.has_key('ratings') and params['ratings'] == '1'):
						trackObject['rating'] = track.rating.get()
			
					if (params.has_key('composers') and params['composers'] == '1'):
						trackObject['composer'] = cleanName(track.composer.get())
			
					if (params.has_key('comments') and params['comments'] == '1'):
						trackObject['comments'] = cleanName(track.comment.get())
				
					if (params.has_key('datesAdded') and params['datesAdded'] == '1'):
						trackObject['dateAdded'] = track.date_added.get().isoformat() + 'Z'
				
					if (params.has_key('bitrates') and params['bitrates'] == '1'):
						trackObject['bitrate'] = track.bit_rate.get()
				
					if (params.has_key('sampleRates') and params['sampleRates'] == '1'):
						trackObject['sampleRate'] = track.sample_rate.get()
				
					if (params.has_key('playCounts') and params['playCounts'] == '1'):
						try:
							trackObject['playCount'] = track.played_count.get()
						except:
							trackObject['playCount'] = 0
			
				tracks.append(trackObject)
		
		if (params.has_key('filterBy')):
			tracks = self.filterTracksByPredicate(tracks, params['filterBy'])
		
		return tracks
	
	def filterTracksByPredicate(self, tracks, predicate):
		predicates = re.sub(r"\[(.+)\]", r"\1", predicate).replace('%3A', ':').split('|')
		#print len(tracks)
		#removed = 0
		newTracks = []
		for predicate in predicates:
			prType, cmpMode, data = predicate.split(':', 3)
			#print 'Type: ' + prType + ', data: ' + data
			for track in tracks:
				# Comparisons of format self.compare[cmpMode](data, --property--)
				if prType == 'nam':
					if self.compare[cmpMode](base64.urlsafe_b64decode(data), track['name']): newTracks.append(track)
				elif prType == 'alb':
					if self.compare[cmpMode](base64.urlsafe_b64decode(data), track['album']): newTracks.append(track)
				elif prType == 'art':
					if self.compare[cmpMode](base64.urlsafe_b64decode(data), track['artist']): newTracks.append(track)
				elif prType == 'gen':
					if self.compare[cmpMode](base64.urlsafe_b64decode(data), track['genre']): newTracks.append(track)
				elif prType == 'cmp':
					if self.compare[cmpMode](base64.urlsafe_b64decode(data), track['composer']): newTracks.append(track)
				elif prType == 'plc':
					if self.compare[cmpMode](int(data), track['playCount']): newTracks.append(track)
				elif prType == 'rat':
					if self.compare[cmpMode](int(data), track['rating']): newTracks.append(track)
		#print len(tracks)
		#print 'Removed: ' + str(removed)
		return newTracks
	
	def play(self, params, request):
		iTunes = self.iTunesCheck()
		success = iTunes.play()
		return self.sendJSON({"success":True}, request)
	
	def pause(self, params, request):
		iTunes = self.iTunesCheck()
		success = iTunes.pause()
		return self.sendJSON({"success":True}, request)
	
	def playPause(self, params, request):
		iTunes = self.iTunesCheck()
		success = iTunes.playpause()
		return self.sendJSON({"success":True}, request)
	
	def stop(self, params, request):
		iTunes = self.iTunesCheck()
		success = iTunes.stop()
		return self.sendJSON({"success":True}, request)
	
	def playPlaylist(self, params, request):
		iTunes = self.iTunesCheck()
		
		if not params.has_key('playlist'):
			return self.send400(request)
		
		playlistID, sourceID = params['playlist'].replace('%3A', ':').split(':', 2)
		
		try:
			playlist = iTunes.sources.ID(sourceID).playlists.ID(playlistID)
			playlist.play()
		except:
			if self.localLibrary != None:
				self.localLibrary.expire()
			return self.sendJSON({"success":False}, request)
		
		iTunes.browser_windows[1].view.set(playlist)
		return self.sendJSON({"success":True}, request)
	
	def playTrack(self, params, request):
		iTunes = self.iTunesCheck()
		
		if not params.has_key('track'):
			return self.send400(request)
		
		trackID, playlistID, sourceID = params['track'].replace('%3A', ':').split(':', 3)
		
		playlist = iTunes.sources.ID(sourceID).playlists.ID(playlistID)
		
		try:
			if (params.has_key('once') and params.has_key('once') == '1'):
				playlist.tracks[its.database_ID == int(trackID)].play(once=True)
			else:
				playlist.tracks[its.database_ID == int(trackID)].play()
		except:
			if self.localLibrary != None:
				self.localLibrary.expire()
			return self.sendJSON({"success":False}, request)
		
		iTunes.browser_windows[1].view.set(playlist)
		return self.sendJSON({"success":True}, request)
	
	def nextTrack(self, params, request):
		iTunes = self.iTunesCheck()
		
		success = iTunes.next_track()
		return self.sendJSON({"success":True}, request)
	
	def prevTrack(self, params, request):
		iTunes = self.iTunesCheck()
		
		success = iTunes.previous_track()
		return self.sendJSON({"success":True}, request)
	
	def setVolume(self, params, request):
		iTunes = self.iTunesCheck()
		
		if not params.has_key('volume'):
			return self.send400(request)
			
		success = iTunes.sound_volume.set(params['volume'])
		return self.sendJSON({"success":True}, request)
	
	def volumeUp(self, params, request):
		iTunes = self.iTunesCheck()
		
		vol = iTunes.sound_volume.get() + 10
		if vol > 100:
			vol = 100
		
		iTunes.sound_volume.set(vol)
		return self.sendJSON({"success":True}, request)
	
	def volumeDown(self, params, request):
		iTunes = self.iTunesCheck()
		
		vol = iTunes.sound_volume.get() - 10
		if vol < 0:
			vol = 0
		
		iTunes.sound_volume.set(vol)
		return self.sendJSON({"success":True}, request)
	
	def currentTrack(self, params, request):
		iTunes = self.iTunesCheck()
		
		try:
			track = iTunes.current_track
			trackObject = {"name":cleanName(track.name.get()), "artist":cleanName(track.artist.get()), "album":cleanName(track.album.get()), "duration":track.duration.get()}
			
			if len(params) > 0:
				if (params.has_key('genre') and params['genre'] == '1'):
					trackObject['genre'] = cleanName(track.genre.get())

				if (params.has_key('rating') and params['rating'] == '1'):
					trackObject['rating'] = track.rating.get()

				if (params.has_key('composer') and params['composer'] == '1'):
					trackObject['composer'] = cleanName(track.composer.get())
				
				if (params.has_key('comments') and params['comments'] == '1'):
					trackObject['comments'] = cleanName(track.comment.get())
				
				if (params.has_key('dateAdded') and params['dateAdded'] == '1'):
					trackObject['dateAdded'] = track.date_added.get().isoformat() + 'Z'

				if (params.has_key('bitrate') and params['bitrate'] == '1'):
					trackObject['bitrate'] = track.bit_rate.get()

				if (params.has_key('sampleRate') and params['sampleRate'] == '1'):
					trackObject['sampleRate'] = track.sample_rate.get()
				
				if (params.has_key('playCount') and params['playCount'] == '1'):
					try:
						trackObject['playCount'] = track.played_count.get()
					except:
						trackObject['playCount'] = 0
					
		except CommandError:
			trackObject = {"name":False}
		
		return self.sendJSON(trackObject, request)
	
	def playerStatus(self, params, request):
		iTunes = self.iTunesCheck()
		
		try:
			playerProgress = iTunes.player_position.get()
		except CommandError:
			playerProgress = 0
		
		if playerProgress == k.missing_value:
			playerProgress = 0
			
		infoObject = {"playState":className(iTunes.player_state.get()), "volume":iTunes.sound_volume.get(), "progress":playerProgress}
		return self.sendJSON(infoObject, request)
	
	def fullStatus(self, params, request):
		iTunes = self.iTunesCheck()
		
		try:
			playerProgress = iTunes.player_position.get()
		except CommandError:
			playerProgress = 0
		
		if playerProgress == k.missing_value:
			playerProgress = 0
			
		infoObject = {"playState":className(iTunes.player_state.get()), "volume":iTunes.sound_volume.get(), "progress":playerProgress}
		try:
			track = iTunes.current_track
			trackObject = {"name":cleanName(track.name.get()), "artist":cleanName(track.artist.get()), "album":cleanName(track.album.get()), "duration":track.duration.get()}
			
			if len(params) > 0:
				if (params.has_key('genre') and params['genre'] == '1'):
					trackObject['genre'] = cleanName(track.genre.get())

				if (params.has_key('rating') and params['rating'] == '1'):
					trackObject['rating'] = track.rating.get()

				if (params.has_key('composer') and params['composer'] == '1'):
					trackObject['composer'] = cleanName(track.composer.get())
				
				if (params.has_key('comments') and params['comments'] == '1'):
					trackObject['comments'] = cleanName(track.comment.get())
					
				if (params.has_key('dateAdded') and params['dateAdded'] == '1'):
					trackObject['dateAdded'] = track.date_added.get().isoformat() + 'Z'

				if (params.has_key('bitrate') and params['bitrate'] == '1'):
					trackObject['bitrate'] = track.bit_rate.get()

				if (params.has_key('sampleRate') and params['sampleRate'] == '1'):
					trackObject['sampleRate'] = track.sample_rate.get()
					
				if (params.has_key('playCount') and params['playCount'] == '1'):
					try:
						trackObject['playCount'] = track.played_count.get()
					except:
						trackObject['playCount'] = 0
					
		except CommandError:
			trackObject = {"name":False}
		
		return self.sendJSON(dict(infoObject, **trackObject), request)
	
	def setPlayerPosition(self, params, request):
		iTunes = self.iTunesCheck()
		
		if not params.has_key('position'):
			return self.send400(request)
		
		iTunes.player_position.set(params['position'])
		
		return self.sendJSON({"success":True}, request)
	
	def playSettings(self, params, request):
		iTunes = self.iTunesCheck()
		
		if not params.has_key('ofPlaylist'):
			return self.send400(request)
		
		playlistID, sourceID = params['ofPlaylist'].replace('%3A', ':').split(':', 2)
		
		playlist = iTunes.sources.ID(sourceID).playlists.ID(playlistID)
		playSettings = {"shuffle":playlist.shuffle.get(), "repeat":className(playlist.song_repeat.get())}
		
		return self.sendJSON(playSettings, request)
	
	def setPlaySettings(self, params, request):
		iTunes = self.iTunesCheck()
		
		if not params.has_key('ofPlaylist'):
			return self.send400(request)
		
		playlistID, sourceID = params['ofPlaylist'].replace('%3A', ':').split(':', 2)
		
		playlist = iTunes.sources.ID(sourceID).playlists.ID(playlistID)
		
		if params.has_key('shuffle'):
			if params['shuffle'] == '1':
				playlist.shuffle.set(True)
			else:
				playlist.shuffle.set(False)
		
		if params.has_key('repeat'):
			if params['repeat'] == "one":
				rState = k.one
			elif params['repeat'] == "all":
				rState = k.all
			else:
				rState = k.off
			
			playlist.song_repeat.set(rState)
		
		return self.sendJSON({"success":True}, request)
	
	def search(self, params, request):
		iTunes = self.iTunesCheck()
		
		if not params.has_key('for'):
			return self.send400(request)
		
		if params.has_key('ofPlaylist'):
			playlistID, sourceID = params['ofPlaylist'].replace('%3A', ':').split(':', 2)
			playlist = iTunes.sources.ID(sourceID).playlists.ID(playlistID)
			source = int(sourceID)
			playlistID = int(playlistID)
		else:
			playlist = iTunes.sources[1].playlists[1]
			source = iTunes.sources[1].id.get()
			playlistID = playlist.id.get()
		
		results = playlist.search(for_=base64.urlsafe_b64decode(params['for']))
		tracks = []
		for track in results:
			trackObject = {'name':cleanName(track.name.get()), 'id':track.database_ID.get(), 'playlist':playlistID, 'source':source, 'duration':track.duration.get(), 'album':cleanName(track.album.get()), 'artist':cleanName(track.artist.get()), 'videoType':className(track.video_kind.get())}
			
			if (params.has_key('genres') and params['genres'] == '1'):
				trackObject['genre'] = cleanName(track.genre.get())
			
			if (params.has_key('ratings') and params['ratings'] == '1'):
				trackObject['rating'] = track.rating.get()
			
			if (params.has_key('composers') and params['composers'] == '1'):
				trackObject['composer'] = cleanName(track.composer.get())
			
			if (params.has_key('comments') and params['comments'] == '1'):
				trackObject['comments'] = cleanName(track.comment.get())
			
			tracks.append(trackObject)
		
		return self.sendJSON({'tracks':tracks}, request)
	
	def EQSettings(self, params, request):
		iTunes = self.iTunesCheck()
		
		eq = iTunes.current_EQ_preset.get()
		EQInfo = {'state':iTunes.EQ_enabled.get(), 'preset':cleanName(eq.name.get()), 'id':eq.id.get(), 'preamp':eq.preamp.get(), 'band1':eq.band_1.get(), 'band2':eq.band_2.get(), 'band3':eq.band_3.get(), 'band4':eq.band_4.get(), 'band5':eq.band_5.get(), 'band6':eq.band_6.get(), 'band7':eq.band_7.get(), 'band8':eq.band_8.get(), 'band9':eq.band_9.get(), 'band10':eq.band_10.get()}
		
		return self.sendJSON(EQInfo, request)
	
	def EQPresets(self, params, request):
		iTunes = self.iTunesCheck()
		
		results = iTunes.EQ_presets.get()
		presets = []
		for preset in results:
			pObject = {'name':cleanName(preset.name.get()), 'id':preset.id.get(), 'modifiable':preset.modifiable.get()}
			
			presets.append(pObject)
		
		return self.sendJSON({'presets':presets}, request)
	
	def setEQState(self, params, request):
		iTunes = self.iTunesCheck()
		
		if not params.has_key('state'):
			return self.send400(request)
		
		if params['state'] == 'off':
			iTunes.EQ_enabled.set(False)
		else:
			iTunes.EQ_enabled.set(True)
		
		return self.sendJSON({'success':True}, request)
	
	def setEQBand(self, params, request):
		iTunes = self.iTunesCheck()
		
		if not params.has_key('band') or not params.has_key('value'):
			return self.send400(request)
		
		eq = iTunes.current_EQ_preset
		val = float(params['value'])
		
		if params['band'] == 'preamp':
			eq.preamp.set(val)
		elif params['band'] == '1':
			eq.band_1.set(val)
		elif params['band'] == '2':
			eq.band_2.set(val)
		elif params['band'] == '3':
			eq.band_3.set(val)
		elif params['band'] == '4':
			eq.band_4.set(val)
		elif params['band'] == '5':
			eq.band_5.set(val)
		elif params['band'] == '6':
			eq.band_6.set(val)
		elif params['band'] == '7':
			eq.band_7.set(val)
		elif params['band'] == '8':
			eq.band_8.set(val)
		elif params['band'] == '9':
			eq.band_9.set(val)
		elif params['band'] == '10':
			eq.band_10.set(val)
		
		return self.sendJSON({'success':True}, request)
	
	def setEQPreset(self, params, request):
		iTunes = self.iTunesCheck()
		
		if not params.has_key('preset'):
			return self.send400(request)
		
		iTunes.current_EQ_preset.set(iTunes.EQ_presets.ID(params['preset']))
		
		return self.sendJSON({'success':True}, request)
	
	def visuals(self, params, request):
		iTunes = self.iTunesCheck()
		
		visuals = iTunes.visuals.get()
		visualList = []
		for visual in visuals:
			visualList.append({"name":cleanName(visual.name.get()), "id":visual.id.get()})
		return self.sendJSON({'visuals':visualList}, request)
	
	def visualSettings(self, params, request):
		iTunes = self.iTunesCheck()
		
		visualInfo = {"name":cleanName(iTunes.current_visual.name.get()), "id":iTunes.current_visual.id.get(), "fullScreen":iTunes.full_screen.get(), "displaying":iTunes.visuals_enabled.get(), "size":className(iTunes.visual_size.get())}
		
		return self.sendJSON(visualInfo, request)
	
	def setVisualizations(self, params, request):
		iTunes = self.iTunesCheck()
		
		if not params.has_key('visual') or not params.has_key('fullScreen') or not params.has_key('size') or not params.has_key('displaying'):
			return self.send400(request)
		
		iTunes.current_visual.set(iTunes.visuals.ID(params['visual']))
		if params['size'] == "small":
			vSize = k.small
		elif params['size'] == "medium":
			vSize = k.medium
		else:
			vSize = k.large
		iTunes.visual_size.set(vSize)
		
		if params['fullScreen'] == '0':
			iTunes.full_screen.set(False)
		else:
			iTunes.full_screen.set(True)
		
		if params['displaying'] == '1':
			if not iTunes.full_screen.get():
				# Make iTunes front app?
				iTunes.activate()
			try:
				iTunes.visuals_enabled.set(True)
			except CommandError:
				pass
		else:
			try:
				iTunes.visuals_enabled.set(False)
			except CommandError:
				pass
		
		return self.sendJSON({"success":True}, request)
	
	def setTrackName(self, params, request):
		iTunes = self.iTunesCheck()
		
		if not params.has_key('name'):
			return self.send400(request)
		
		if not params.has_key('ofTrack'):
			track = iTunes.current_track
		else:
			trackID, playlistID, sourceID = params['ofTrack'].replace('%3A', ':').split(':', 3)
			track = iTunes.sources.ID(sourceID).playlists.ID(playlistID).tracks[its.database_ID == int(trackID)]
		
		track.name.set(base64.urlsafe_b64decode(params['name']))
		
		return self.sendJSON({"success":True}, request)
	
	def setTrackArtist(self, params, request):
		iTunes = self.iTunesCheck()
		
		if not params.has_key('artist'):
			return self.send400(request)
		
		if not params.has_key('ofTrack'):
			track = iTunes.current_track
		else:
			trackID, playlistID, sourceID = params['ofTrack'].replace('%3A', ':').split(':', 3)
			track = iTunes.sources.ID(sourceID).playlists.ID(playlistID).tracks[its.database_ID == int(trackID)]
		
		track.artist.set(base64.urlsafe_b64decode(params['artist']))
		
		return self.sendJSON({"success":True}, request)
	
	def setTrackAlbum(self, params, request):
		iTunes = self.iTunesCheck()
		
		if not params.has_key('album'):
			return self.send400(request)
		
		if not params.has_key('ofTrack'):
			track = iTunes.current_track
		else:
			trackID, playlistID, sourceID = params['ofTrack'].replace('%3A', ':').split(':', 3)
			track = iTunes.sources.ID(sourceID).playlists.ID(playlistID).tracks[its.database_ID == int(trackID)]
		
		track.album.set(base64.urlsafe_b64decode(params['album']))
		
		return self.sendJSON({"success":True}, request)
	
	def setTrackRating(self, params, request):
		iTunes = self.iTunesCheck()
		
		if not params.has_key('rating'):
			return self.send400(request)
		
		if not params.has_key('ofTrack'):
			track = iTunes.current_track
		else:
			trackID, playlistID, sourceID = params['ofTrack'].replace('%3A', ':').split(':', 3)
			track = iTunes.sources.ID(sourceID).playlists.ID(playlistID).tracks[its.database_ID == int(trackID)]
		
		track.rating.set(params['rating'])
		
		return self.sendJSON({"success":True}, request)
	
	def setTrackGenre(self, params, request):
		iTunes = self.iTunesCheck()
		
		if not params.has_key('genre'):
			return self.send400(request)
		
		if not params.has_key('ofTrack'):
			track = iTunes.current_track
		else:
			trackID, playlistID, sourceID = params['ofTrack'].replace('%3A', ':').split(':', 3)
			track = iTunes.sources.ID(sourceID).playlists.ID(playlistID).tracks[its.database_ID == int(trackID)]
		
		track.genre.set(base64.urlsafe_b64decode(params['genre']))
		
		return self.sendJSON({"success":True}, request)
	
	def setTrackComposer(self, params, request):
		iTunes = self.iTunesCheck()
		
		if not params.has_key('composer'):
			return self.send400(request)
		
		if not params.has_key('ofTrack'):
			track = iTunes.current_track
		else:
			trackID, playlistID, sourceID = params['ofTrack'].replace('%3A', ':').split(':', 3)
			track = iTunes.sources.ID(sourceID).playlists.ID(playlistID).tracks[its.database_ID == int(trackID)]
		
		track.composer.set(base64.urlsafe_b64decode(params['composer']))
		
		return self.sendJSON({"success":True}, request)
	
	def setTrackComments(self, params, request):
		iTunes = self.iTunesCheck()
		
		if not params.has_key('comments'):
			return self.send400(request)
		
		if not params.has_key('ofTrack'):
			track = iTunes.current_track
		else:
			trackID, playlistID, sourceID = params['ofTrack'].replace('%3A', ':').split(':', 3)
			track = iTunes.sources.ID(sourceID).playlists.ID(playlistID).tracks[its.database_ID == int(trackID)]
		
		track.comment.set(base64.urlsafe_b64decode(params['comments']))
		
		return self.sendJSON({"success":True}, request)
	
	def createPlaylist(self, params, request):
		iTunes = self.iTunesCheck()
		
		if not params.has_key('name'):
			return self.send400(request)
		
		newPlaylist = iTunes.make(new=k.playlist, with_properties={k.name: base64.urlsafe_b64decode(params['name'])})
		
		playlistObject = {"name":cleanName(newPlaylist.name.get()), "id":newPlaylist.id.get(), "source":newPlaylist.container.id.get(), "duration":0, "trackCount":0, "specialKind":className(newPlaylist.special_kind.get())}
		
		return self.sendJSON(playlistObject, request)
	
	def addTrackToPlaylist(self, params, request):
		iTunes = self.iTunesCheck()
		
		if not params.has_key('toPlaylist'):
			return self.send400(request)

		if not params.has_key('track'):
			track = iTunes.current_track
		else:
			trackID, playlistID, sourceID = params['track'].replace('%3A', ':').split(':', 3)
			track = iTunes.sources.ID(sourceID).playlists.ID(playlistID).tracks[its.database_ID == int(trackID)]
		
		destPlaylist, destSource = params['toPlaylist'].replace('%3A', ':').split(':', 2)
		newPlaylist = iTunes.sources.ID(destSource).playlists.ID(destPlaylist)
		newTrack = track.duplicate(to=newPlaylist)
		
		trackObject = {"name":cleanName(newTrack.name.get()), "id":newTrack.id.get(), "playlist":newPlaylist.id.get(), "source":newPlaylist.container.id.get(), "duration":newTrack.duration.get(), "album":cleanName(newTrack.album.get()), "artist":cleanName(newTrack.artist.get()), "videoType":className(newTrack.video_kind.get())}
		
		return self.sendJSON(trackObject, request)
	
	def deleteTrackFromPlaylist(self, params, request):
		iTunes = self.iTunesCheck()
		
		if not params.has_key('track'):
			return self.send400(request)
		
		trackID, playlistID, sourceID = params['track'].replace('%3A', ':').split(':', 3)
		track = iTunes.sources.ID(sourceID).playlists.ID(playlistID).tracks[its.database_ID == int(trackID)]
		
		track.delete()
		
		return self.sendJSON({"success":True}, request)
	
	def deletePlaylist(self, params, request):
		iTunes = self.iTunesCheck()
		
		if not params.has_key('playlist'):
			return self.send400(request)
		
		playlistID, sourceID = params['playlist'].replace('%3A', ':').split(':', 2)
		playlist = iTunes.sources.ID(sourceID).playlists.ID(playlistID)
		
		playlist.delete()
		
		return self.sendJSON({"success":True}, request)
	