# TuneConnect Server 2.0, conformant to Tunage API 1.0
# Copyright (C) 2007 Matt Patenaude
# iTunes Accessor Code for Windows

from iTunesAccessorClass import iTunesAccessorTemplate
import win32com.client
import string, hashlib
from os import system, fstat, path
from json import json

# Default system locations for library and artwork files
libraryFile = path.expanduser("~/Music/iTunes/iTunes Music Library.xml")
artworkFile = "C:\\WINDOWS\\Temp\\iTunes_artwork"
pluginDirs = ["Plug-ins"]

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
	localLibrary = None
	artworkFile = None
	
	def __init__(self, localLibrary, artworkFile):
		self.methods = {'artwork':self.artwork, 'getSources':self.getSources, 'getPlaylists':self.getPlaylists, 'getTracks':self.getTracks, 'signature':self.signature, 'play':self.play, 'pause':self.pause, 'playPause':self.playPause, 'stop':self.stop, 'playPlaylist':self.playPlaylist, 'playTrack':self.playTrack, 'nextTrack':self.nextTrack, 'prevTrack':self.prevTrack, 'setVolume':self.setVolume, 'volumeUp':self.volumeUp, 'volumeDown':self.volumeDown, 'currentTrack':self.currentTrack, 'playerStatus':self.playerStatus, 'fullStatus':self.fullStatus, 'playSettings':self.playSettings, 'setPlayerPosition':self.setPlayerPosition, 'setPlaySettings':self.setPlaySettings, 'search':self.search, 'EQSettings':self.EQSettings, 'EQPresets':self.EQPresets, 'setEQState':self.setEQState, 'setEQBand':self.setEQBand, 'setEQPreset':self.setEQPreset, 'visuals':self.visuals, 'visualSettings':self.visualSettings, 'setVisualizations':self.setVisualizations, 'setTrackName':self.setTrackName, 'setTrackArtist':self.setTrackArtist, 'setTrackAlbum':self.setTrackAlbum, 'setTrackRating':self.setTrackRating, 'setTrackGenre':self.setTrackGenre, 'setTrackComposer':self.setTrackComposer, 'setTrackComments':self.setTrackComments, 'createPlaylist':self.createPlaylist, 'addTrackToPlaylist':self.addTrackToPlaylist, 'deleteTrackFromPlaylist':self.deleteTrackFromPlaylist, 'deletePlaylist':self.deletePlaylist}
		self.localLibrary = localLibrary
		self.artworkFile = artworkFile
		
		self.sourceKinds = {"0":"unknown", "1":"library", "2":"iPod", "3":"audio_CD", "4":"MP3_CD", "5":"device", "6":"radio_tuner", "7":"shared_library"}
		self.artworkFormats = {"0":"unknown", "1":"JPEG", "2":"PNG", "3":"BMP"}
		self.playerStateTypes = {"0":"stopped", "1":"playing", "2":"fast_forwarding", "3":"rewinding"}
		self.repeatTypes = {"0":"off", "1":"one", "2":"all"}
		self.visualSizes = {"0":"small", "1":"medium", "2":"large"}
	
	def iTunesCheck(self):
		if self.iTunes == None:
			self.iTunes = win32com.client.gencache.EnsureDispatch('iTunes.Application')
			if self.localLibrary != None:
				self.localLibrary.expire()
			
		try:
			v = self.iTunes.Version
		except:
			# We couldn't get the iTunes version, so we have an old reference
			# Let's re-dispatch!
			self.iTunes = win32com.client.gencache.EnsureDispatch('iTunes.Application')
			if self.localLibrary != None:
				self.localLibrary.expire()

		return self.iTunes
	
	def artwork(self, params, request):
		iTunes = self.iTunesCheck()
		
		try:
			artworks = iTunes.CurrentTrack.Artwork
		except:
			return self.send404(request)
		
		if len(artworks) > 0:
			artwork = artworks.Item(1)
			format = self.artworkFormats[str(artwork.Format)]
			if string.find(format, "JPEG") != -1 or string.find(format,'JPG') != -1:
				type = "image/jpeg"
			elif string.find(format, 'GIF') != -1:
				type = "image/gif"
			elif string.find(format, 'PNG') != -1:
				type = "image/png"
			else:
				return self.send404(request)
			
			fname = self.artworkFile
			
			if self.lastArtwork is None or self.lastArtwork != iTunes.CurrentTrack.Album or not path.exists(fname):
				artwork.SaveArtworkToFile(fname)
				self.lastArtwork = iTunes.CurrentTrack.Album

			try:
				f = open(fname, 'rb')
			except IOError:
				return self.send404(request)
				
			request.setHeader("Content-type", type)
			request.setHeader("Content-Length", str(fstat(f.fileno())[6]))
			request.write(f.read(fstat(f.fileno())[6]))
			
			f.close()
			return
		else:
			return self.send404(request)
		return self.send404(request)
	
	def getSources(self, params, request):
		iTunes = self.iTunesCheck()
		
		sourceList = []
		for source in iTunes.Sources:
			sourceList.append({'name':cleanName(source.Name), 'id':source.Index, 'kind':self.sourceKinds[str(source.Kind)]})
		
		return self.sendJSON({'sources':sourceList}, request)
	
	def getPlaylists(self, params, request):
		iTunes = self.iTunesCheck()
		
		if not params.has_key('ofSource'):
			return self.send400(request)
			
		playlists = []
		
		source = iTunes.Sources.Item(int(params['ofSource']))
		
		if source.Kind == 1 and self.localLibrary != None:
			playlists = self.localLibrary.getPlaylists(source.Index)
		else:
			playlistSet = source.Playlists
			for playlist in playlistSet:
				playlists.append({'name':cleanName(playlist.Name), 'id':playlist.Index, 'source':int(params['ofSource']), 'duration':playlist.Duration, 'trackCount':playlist.Tracks.Count, 'specialKind':playlist.Kind})
				
		return self.sendJSON({'playlists':playlists}, request)
	
	def getTracks(self, params, request):
		if not params.has_key('ofPlaylist') or not params.has_key('ofSource'):
			return self.send400(request)
		
		tracks = self.composeTrackArray(params, request)
		
		response = {'tracks':tracks}
		
		if (params.has_key('signature') and params['signature'] == '1'):
			response['signature'] = self.createPlaylistSignature(tracks)
		
		return self.sendJSON(response, request)
	
	def signature(self, params, request):
		if not params.has_key('ofPlaylist') or not params.has_key('ofSource'):
			return self.send400(request)

		return self.sendJSON({'signature':self.createPlaylistSignature(self.composeTrackArray(params, request))}, request)

	def createPlaylistSignature(self, trackArray):
		signature = hashlib.md5(json.write(trackArray).replace('\\\\', '\\')).hexdigest()
		return signature
	
	def composeTrackArray(self, params, request):
		iTunes = self.iTunesCheck()

		tracks = []
		
		source = iTunes.Sources.Item(int(params['ofSource']))
		
		if source.Kind == 1 and self.localLibrary != None:
			tracks = self.localLibrary.getTracksForPlaylist(params['ofPlaylist'], params['ofSource'], params)
		else:
			playlist = source.Playlists.Item(int(params['ofPlaylist'])).Tracks
			for track in playlist:
				trackObject = {'name':cleanName(track.Name), 'id':track.Index, 'playlist':int(params['ofPlaylist']), 'source':int(params['ofSource']), 'duration':track.Duration, 'album':cleanName(track.Album), 'artist':cleanName(track.Artist), 'videoType':"unknown"}
			
				if (params.has_key('genres') and params['genres'] == '1'):
					trackObject['genre'] = cleanName(track.Genre)
			
				if (params.has_key('ratings') and params['ratings'] == '1'):
					trackObject['rating'] = track.Rating
			
				if (params.has_key('composers') and params['composers'] == '1'):
					trackObject['composer'] = cleanName(track.Composer)
			
				if (params.has_key('comments') and params['comments'] == '1'):
					trackObject['comments'] = cleanName(track.Comment)
			
				tracks.append(trackObject)
		
		return tracks
	
	def play(self, params, request):
		iTunes = self.iTunesCheck()
		success = iTunes.Play()
		return self.sendJSON({"success":True}, request)
	
	def pause(self, params, request):
		iTunes = self.iTunesCheck()
		success = iTunes.Pause()
		return self.sendJSON({"success":True}, request)
	
	def playPause(self, params, request):
		iTunes = self.iTunesCheck()
		success = iTunes.PlayPause()
		return self.sendJSON({"success":True}, request)
	
	def stop(self, params, request):
		iTunes = self.iTunesCheck()
		success = iTunes.Stop()
		return self.sendJSON({"success":True}, request)
	
	def playPlaylist(self, params, request):
		iTunes = self.iTunesCheck()
		
		if not params.has_key('playlist') or not params.has_key('ofSource'):
			return self.send400(request)
			
		playlist = iTunes.Sources.Item(int(params['ofSource'])).Playlists.Item(int(params['playlist']))
		playlist.PlayFirstTrack()
		try:
			playlist.Reveal()
		except:
			pass
		return self.sendJSON({"success":True}, request)
	
	def playTrack(self, params, request):
		iTunes = self.iTunesCheck()
		
		if not params.has_key('track') or not params.has_key('ofPlaylist') or not params.has_key('ofSource'):
			return self.send400(request)

		source = iTunes.Sources.Item(int(params['ofSource']))
		playlist = source.Playlists.Item(int(params['ofPlaylist']))
		if (params.has_key('once') and params.has_key('once') == '1' and False):
			#playlist.tracks[its.database_ID == int(params['track'])].play(once=True)
			pass
		else:
			playlist.Tracks.Item(int(params['track'])).Play()
		try:
			playlist.Reveal()
		except:
			pass
		return self.sendJSON({"success":True}, request)
	
	def nextTrack(self, params, request):
		iTunes = self.iTunesCheck()
		
		success = iTunes.NextTrack()
		return self.sendJSON({"success":True}, request)
	
	def prevTrack(self, params, request):
		iTunes = self.iTunesCheck()
		
		success = iTunes.PreviousTrack()
		return self.sendJSON({"success":True}, request)
	
	def setVolume(self, params, request):
		iTunes = self.iTunesCheck()
		
		if not params.has_key('volume'):
			return self.send400(request)
			
		iTunes.SoundVolume = float(params['volume'])
		return self.sendJSON({"success":True}, request)
	
	def volumeUp(self, params, request):
		iTunes = self.iTunesCheck()
		
		vol = iTunes.SoundVolume + 10.0
		if vol > 100:
			vol = 100.0
		
		iTunes.SoundVolume = vol
		return self.sendJSON({"success":True}, request)
	
	def volumeDown(self, params, request):
		iTunes = self.iTunesCheck()
		
		vol = iTunes.SoundVolume - 10.0
		if vol < 0.0:
			vol = 0.0
		
		iTunes.SoundVolume = vol
		return self.sendJSON({"success":True}, request)
	
	def currentTrack(self, params, request):
		iTunes = self.iTunesCheck()
		
		try:
			track = iTunes.CurrentTrack
			trackObject = {"name":cleanName(track.Name), "artist":cleanName(track.Artist), "album":cleanName(track.Album), "duration":track.Duration}
			
			if len(params) > 0:
				if (params.has_key('genre') and params['genre'] == '1'):
					trackObject['genre'] = cleanName(track.Genre)

				if (params.has_key('rating') and params['rating'] == '1'):
					trackObject['rating'] = track.Rating

				if (params.has_key('composer') and params['composer'] == '1'):
					trackObject['composer'] = cleanName(track.Composer)
				
				if (params.has_key('comments') and params['comments'] == '1'):
					trackObject['comments'] = cleanName(track.Comment)
					
		except:
			trackObject = {"name":False}
		
		return self.sendJSON(trackObject, request)
	
	def playerStatus(self, params, request):
		iTunes = self.iTunesCheck()
		
		try:
			playerProgress = iTunes.PlayerPosition
		except:
			playerProgress = 0
			
		infoObject = {"playState":self.playerStateTypes[str(iTunes.PlayerState)], "volume":iTunes.SoundVolume, "progress":playerProgress}
		return self.sendJSON(infoObject, request)
	
	def fullStatus(self, params, request):
		iTunes = self.iTunesCheck()
		
		try:
			playerProgress = iTunes.PlayerPosition
		except:
			playerProgress = 0
			
		infoObject = {"playState":self.playerStateTypes[str(iTunes.PlayerState)], "volume":iTunes.SoundVolume, "progress":playerProgress}
		try:
			track = iTunes.CurrentTrack
			trackObject = {"name":cleanName(track.Name), "artist":cleanName(track.Artist), "album":cleanName(track.Album), "duration":track.Duration}
			
			if len(params) > 0:
				if (params.has_key('genre') and params['genre'] == '1'):
					trackObject['genre'] = cleanName(track.Genre)

				if (params.has_key('rating') and params['rating'] == '1'):
					trackObject['rating'] = track.Rating

				if (params.has_key('composer') and params['composer'] == '1'):
					trackObject['composer'] = cleanName(track.Composer)
				
				if (params.has_key('comments') and params['comments'] == '1'):
					trackObject['comments'] = cleanName(track.Comment)
					
		except:
			trackObject = {"name":False}
		
		return self.sendJSON(dict(infoObject, **trackObject), request)
		
	def setPlayerPosition(self, params, request):
		iTunes = self.iTunesCheck()
		
		if not params.has_key('position'):
			return self.send400(request)
		
		iTunes.PlayerPosition = float(params['position'])
		
		return self.sendJSON({"success":True}, request)
	
	def playSettings(self, params, request):
		iTunes = self.iTunesCheck()

		if not params.has_key('ofPlaylist') or not params.has_key('ofSource'):
			return self.send400(request)

		playlist = iTunes.Sources.Item(int(params['ofSource'])).Playlists.Item(int(params['ofPlaylist']))
		playSettings = {"shuffle":playlist.Shuffle, "repeat":self.repeatTypes[str(playlist.SongRepeat)]}

		return self.sendJSON(playSettings, request)
	
	def setPlaySettings(self, params, request):
		iTunes = self.iTunesCheck()

		if not params.has_key('ofPlaylist') or not params.has_key('ofSource'):
			return self.send400(request)

		playlist = iTunes.Sources.Item(int(params['ofSource'])).Playlists.Item(int(params['ofPlaylist']))

		if params.has_key('shuffle'):
			if params['shuffle'] == '1':
				playlist.Shuffle = True
			else:
				playlist.Shuffle = False

		if params.has_key('repeat'):
			if params['repeat'] == "one":
				rState = 1
			elif params['repeat'] == "all":
				rState = 2
			else:
				rState = 0

			playlist.SongRepeat = rState

		return self.sendJSON({"success":True}, request)
	
	def search(self, params, request):
		iTunes = self.iTunesCheck()

		if not params.has_key('for'):
			return self.send400(request)

		if params.has_key('ofPlaylist') or params.has_key('ofSource'):
			if not params.has_key('ofPlaylist') or not params.has_key('ofSource'):
				return self.send400(request)
			playlist = iTunes.sources.ID(params['ofSource']).playlists.ID(params['ofPlaylist'])
			source = int(params['ofSource'])
			playlistID = int(params['ofPlaylist'])
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

		eq = iTunes.CurrentEQPreset
		EQInfo = {'state':iTunes.EQEnabled, 'preset':cleanName(eq.Name), 'id':0, 'preamp':eq.Preamp, 'band1':eq.Band1, 'band2':eq.Band2, 'band3':eq.Band3, 'band4':eq.Band4, 'band5':eq.Band5, 'band6':eq.Band6, 'band7':eq.Band7, 'band8':eq.Band8, 'band9':eq.Band9, 'band10':eq.Band10}

		return self.sendJSON(EQInfo, request)
	
	def EQPresets(self, params, request):
		iTunes = self.iTunesCheck()

		results = iTunes.EQPresets
		presets = []
		index = 1
		for preset in results:
			pObject = {'name':cleanName(preset.Name), 'id':index, 'modifiable':preset.Modifiable}
			index += 1

			presets.append(pObject)

		return self.sendJSON({'presets':presets}, request)
	
	def setEQState(self, params, request):
		iTunes = self.iTunesCheck()

		if not params.has_key('state'):
			return self.send400(request)

		if params['state'] == 'off':
			iTunes.EQEnabled = False
		else:
			iTunes.EQEnabled = True

		return self.sendJSON({'success':True}, request)
	
	def setEQBand(self, params, request):
		iTunes = self.iTunesCheck()

		if not params.has_key('band') or not params.has_key('value'):
			return self.send400(request)

		eq = iTunes.CurrentEQPreset
		val = float(params['value'])

		if params['band'] == 'preamp':
			eq.Preamp = val
		elif params['band'] == '1':
			eq.Band1 = val
		elif params['band'] == '2':
			eq.Band2 = val
		elif params['band'] == '3':
			eq.Band3 = val
		elif params['band'] == '4':
			eq.Band4 = val
		elif params['band'] == '5':
			eq.Band5 = val
		elif params['band'] == '6':
			eq.Band6 = val
		elif params['band'] == '7':
			eq.Band7 = val
		elif params['band'] == '8':
			eq.Band8 = val
		elif params['band'] == '9':
			eq.Band9 = val
		elif params['band'] == '10':
			eq.Band10 = val

		return self.sendJSON({'success':True}, request)
	
	def setEQPreset(self, params, request):
		iTunes = self.iTunesCheck()

		if not params.has_key('preset'):
			return self.send400(request)

		iTunes.current_EQ_preset.set(iTunes.EQ_presets.ID(params['preset']))

		return self.sendJSON({'success':True}, request)
	
	def visuals(self, params, request):
		iTunes = self.iTunesCheck()

		visuals = iTunes.Visuals
		visualList = []
		
		index = 1
		
		for visual in visuals:
			visualList.append({"name":cleanName(visual.Name), "id":index})
			index += 1
			
		return self.sendJSON({'visuals':visualList}, request)
	
	def visualSettings(self, params, request):
		iTunes = self.iTunesCheck()

		visualInfo = {"name":cleanName(iTunes.CurrentVisual.Name), "id":0, "fullScreen":iTunes.FullScreenVisuals, "displaying":iTunes.VisualsEnabled, "size":self.visualSizes[str(iTunes.VisualSize)]}

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

		if params.has_key('ofTrack') or params.has_key('ofPlaylist') or params.has_key('ofSource'):
			if not params.has_key('ofTrack') or not params.has_key('ofPlaylist') or not params.has_key('ofSource'):
				return self.send400(request)

		if not params.has_key('ofTrack'):
			track = iTunes.current_track
		else:
			track = iTunes.sources.ID(params['ofSource']).playlists.ID(params['ofPlaylist']).tracks[its.database_ID == int(params['ofTrack'])]

		track.name.set(base64.urlsafe_b64decode(params['name']))

		return self.sendJSON({"success":True}, request)
	
	def setTrackArtist(self, params, request):
		iTunes = self.iTunesCheck()

		if not params.has_key('artist'):
			return self.send400(request)

		if params.has_key('ofTrack') or params.has_key('ofPlaylist') or params.has_key('ofSource'):
			if not params.has_key('ofTrack') or not params.has_key('ofPlaylist') or not params.has_key('ofSource'):
				return self.send400(request)

		if not params.has_key('ofTrack'):
			track = iTunes.current_track
		else:
			track = iTunes.sources.ID(params['ofSource']).playlists.ID(params['ofPlaylist']).tracks[its.database_ID == int(params['ofTrack'])]

		track.artist.set(base64.urlsafe_b64decode(params['artist']))

		return self.sendJSON({"success":True}, request)
	
	def setTrackAlbum(self, params, request):
		iTunes = self.iTunesCheck()

		if not params.has_key('album'):
			return self.send400(request)

		if params.has_key('ofTrack') or params.has_key('ofPlaylist') or params.has_key('ofSource'):
			if not params.has_key('ofTrack') or not params.has_key('ofPlaylist') or not params.has_key('ofSource'):
				return self.send400(request)

		if not params.has_key('ofTrack'):
			track = iTunes.current_track
		else:
			track = iTunes.sources.ID(params['ofSource']).playlists.ID(params['ofPlaylist']).tracks[its.database_ID == int(params['ofTrack'])]

		track.album.set(base64.urlsafe_b64decode(params['album']))

		return self.sendJSON({"success":True}, request)
	
	def setTrackRating(self, params, request):
		iTunes = self.iTunesCheck()

		if not params.has_key('rating'):
			return self.send400(request)

		if params.has_key('ofTrack') or params.has_key('ofPlaylist') or params.has_key('ofSource'):
			if not params.has_key('ofTrack') or not params.has_key('ofPlaylist') or not params.has_key('ofSource'):
				return self.send400(request)

		if not params.has_key('ofTrack'):
			track = iTunes.CurrentTrack
		else:
			source = iTunes.Sources.Item(int(params['ofSource']))
			playlist = source.Playlists.Item(int(params['ofPlaylist']))
			track = playlist.Tracks.Item(params['track'])

		track.Rating = int(params['rating'])

		return self.sendJSON({"success":True}, request)
	
	def setTrackGenre(self, params, request):
		iTunes = self.iTunesCheck()

		if not params.has_key('genre'):
			return self.send400(request)

		if params.has_key('ofTrack') or params.has_key('ofPlaylist') or params.has_key('ofSource'):
			if not params.has_key('ofTrack') or not params.has_key('ofPlaylist') or not params.has_key('ofSource'):
				return self.send400(request)

		if not params.has_key('ofTrack'):
			track = iTunes.current_track
		else:
			track = iTunes.sources.ID(params['ofSource']).playlists.ID(params['ofPlaylist']).tracks[its.database_ID == int(params['ofTrack'])]

		track.genre.set(base64.urlsafe_b64decode(params['genre']))

		return self.sendJSON({"success":True}, request)
	
	def setTrackComposer(self, params, request):
		iTunes = self.iTunesCheck()

		if not params.has_key('composer'):
			return self.send400(request)

		if params.has_key('ofTrack') or params.has_key('ofPlaylist') or params.has_key('ofSource'):
			if not params.has_key('ofTrack') or not params.has_key('ofPlaylist') or not params.has_key('ofSource'):
				return self.send400(request)

		if not params.has_key('ofTrack'):
			track = iTunes.current_track
		else:
			track = iTunes.sources.ID(params['ofSource']).playlists.ID(params['ofPlaylist']).tracks[its.database_ID == int(params['ofTrack'])]

		track.composer.set(base64.urlsafe_b64decode(params['composer']))

		return self.sendJSON({"success":True}, request)
	
	def setTrackComments(self, params, request):
		iTunes = self.iTunesCheck()

		if not params.has_key('comments'):
			return self.send400(request)

		if params.has_key('ofTrack') or params.has_key('ofPlaylist') or params.has_key('ofSource'):
			if not params.has_key('ofTrack') or not params.has_key('ofPlaylist') or not params.has_key('ofSource'):
				return self.send400(request)

		if not params.has_key('ofTrack'):
			track = iTunes.current_track
		else:
			track = iTunes.sources.ID(params['ofSource']).playlists.ID(params['ofPlaylist']).tracks[its.database_ID == int(params['ofTrack'])]

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

		if not params.has_key('toPlaylist') or not params.has_key('inSource'):
			return self.send400(request)

		if params.has_key('track') or params.has_key('ofPlaylist') or params.has_key('ofSource'):
			if not params.has_key('track') or not params.has_key('ofPlaylist') or not params.has_key('ofSource'):
				return self.send400(request)

		if not params.has_key('track'):
			track = iTunes.current_track
		else:
			track = iTunes.sources.ID(params['ofSource']).playlists.ID(params['ofPlaylist']).tracks[its.database_ID == int(params['track'])]
		newPlaylist = iTunes.sources.ID(params['inSource']).playlists.ID(params['toPlaylist'])
		newTrack = track.duplicate(to=newPlaylist)

		trackObject = {"name":cleanName(newTrack.name.get()), "id":newTrack.id.get(), "playlist":newPlaylist.id.get(), "source":newPlaylist.container.id.get(), "duration":newTrack.duration.get(), "album":cleanName(newTrack.album.get()), "artist":cleanName(newTrack.artist.get()), "videoType":className(newTrack.video_kind.get())}

		return self.sendJSON(trackObject, request)
	
	def deleteTrackFromPlaylist(self, params, request):
		iTunes = self.iTunesCheck()

		if not params.has_key('track') or not params.has_key('ofPlaylist') or not params.has_key('ofSource'):
			return self.send400(request)

		track = iTunes.sources.ID(params['ofSource']).playlists.ID(params['ofPlaylist']).tracks[its.database_ID == int(params['track'])]

		track.delete()

		return self.sendJSON({"success":True}, request)
	
	def deletePlaylist(self, params, request):
		iTunes = self.iTunesCheck()

		if not params.has_key('playlist') or not params.has_key('ofSource'):
			return self.send400(request)

		playlist = iTunes.sources.ID(params['ofSource']).playlists.ID(params['playlist'])

		playlist.delete()

		return self.sendJSON({"success":True}, request)
	