# TuneConnect Server 2.0, conformant to Tunage API 1.0
# Copyright (C) 2007 Matt Patenaude
# Based on code by Jon Berg (turtlemeat.com)

import string,cgi,time,select,sys
from os import curdir, sep, system, path, fstat, environ
from BaseHTTPServer import BaseHTTPRequestHandler, HTTPServer
from appscript import *
from json import json
import pybonjour
import shutil
import socket
import md5
import base64
import PListReader
import XMLFilter

lastArtwork = None
iTunes = None

# Somehow, get server port and password into these variables
password = None
port = 4242
libraryFileLocation = path.expanduser("~/Music/iTunes/iTunes Music Library.xml")
artworkFilename = '/tmp/iTunes_artwork'

localLibrary = None

class ParamError(Exception):
	def __init__(self):
		pass

class AuthKeyError(Exception):
	def __init__(self):
		pass

def cleanName(name):
	return repr(name)[2:-1]

def className(name):
	return str(name)[2:]

def jOut(item):
	return json.write(item).replace('\\\\', '\\')

def vForK(theObject, theKey):
	if theObject.has_key(theKey):
		return cleanName(theObject[theKey])
	else:
		return ""
	
		
def loadLibraryFile(libraryFile):
	global localLibrary
	reader = PListReader.PListReader()
	XMLFilter.parseFilePath(libraryFile, reader, features = reader.getRecommendedFeatures())
	localLibrary = reader.getResult()

def getLocalPlaylists(sourceID):
	global localLibrary
	
	playlists = []
	
	for playlist in localLibrary['Playlists']:
		pItem = {'name':cleanName(playlist['Name']), 'id':playlist['Playlist ID'], 'source':sourceID}
		
		if playlist.has_key('Playlist Items'):
			pItem['trackCount'] = len(playlist['Playlist Items'])
		else:
			pItem['trackCount'] = 0
		
		if playlist.has_key('Audiobooks') and playlist['Audiobooks']:
			pItem['specialKind'] = 'Audiobooks'
		elif playlist.has_key('Folder') and playlist['Folder']:
			pItem['specialKind'] = 'folder'
		elif playlist.has_key('Movies') and playlist['Movies']:
			pItem['specialKind'] = 'Movies'
		elif playlist.has_key('Music') and playlist['Music']:
			pItem['specialKind'] = 'Music'
		elif playlist.has_key('Party Shuffle') and playlist['Party Shuffle']:
			pItem['specialKind'] = 'Party_Shuffle'
		elif playlist.has_key('Podcasts') and playlist['Podcasts']:
			pItem['specialKind'] = 'Podcasts'
		elif playlist.has_key('TV Shows') and playlist['TV Shows']:
			pItem['specialKind'] = 'TV_Shows'
		elif playlist.has_key('Videos') and playlist['Videos']:
			pItem['specialKind'] = 'Videos'
		else:
			pItem['specialKind'] = 'none'
		
		playlists.append(pItem)
	
	return playlists

def getLocalTracksForPlaylist(ofPlaylist, ofSource):
	global localLibrary
	
	tracks = []
	
	playlist = [playlist for playlist in localLibrary['Playlists'] if playlist['Playlist ID'] == int(ofPlaylist)][0]
	
	if playlist.has_key('Playlist Items'):
		trackRefs = [ref['Track ID'] for ref in playlist['Playlist Items']]
	else:
		trackRefs = []
	
	for track in trackRefs:
		theTrack = localLibrary['Tracks'][str(track)]
		trackObject = {'name':vForK(theTrack, 'Name'), 'id':track, 'playlist':int(ofPlaylist), 'source':int(ofSource), 'album':vForK(theTrack, 'Album'), 'artist':vForK(theTrack, 'Artist')}
		
		if theTrack.has_key('Total Time'):
			trackObject['duration'] = (theTrack['Total Time'] / 1000.000)
		else:
			trackObject['duration'] = 0
		
		if theTrack.has_key('Has Video') and theTrack['Has Video']:
			if theTrack.has_key('Music Video') and theTrack['Music Video']:
				trackObject['videoType'] = 'music_video'
			elif theTrack.has_key('TV Show') and theTrack['TV Show']:
				trackObject['videoType'] = 'TV_show'
			else:
				trackObject['videoType'] = 'movie'
		else:
			trackObject['videoType'] = 'none'
	
		#if (params.has_key('genres') and params['genres'] == '1'):
		#	trackObject['genre'] = cleanName(track.genre.get())
	#
	#	if (params.has_key('ratings') and params['ratings'] == '1'):
	#		trackObject['rating'] = track.rating.get()
	#
	#	if (params.has_key('composers') and params['composers'] == '1'):
	#		trackObject['composer'] = cleanName(track.composer.get())
	#
	#	if (params.has_key('comments') and params['comments'] == '1'):
	#		trackObject['comments'] = cleanName(track.comment.get())
	#
		tracks.append(trackObject)
	
	return tracks

class TCHandler(BaseHTTPRequestHandler):
	def log_request(self, code):
		pass
		
	def do_GET(self):
		global password, iTunes
		try:
			urlParts = self.path.split('?', 1)
			urlBase = urlParts[0]
			if len(urlParts) > 1:
				params = params.split('&')
				partDict = {}
				for part in params:
					param = part.split('=', 1)
					partDict[param[0]] = param[1]
				
				params = partDict
			
			if urlBase.endswith(".html") or urlBase.endswith('.js') or urlBase.endswith('.css'):
				f = open(curdir + sep + urlBase) #urlBase has /test.html
				#note that this potentially makes every file on your computer readable by the internet
				
				self.send_response(200)
				if urlBase.endswith('.js'):
					self.send_header('Content-type', 'text/javascript')
				elif urlBase.endswith('.css'):
					self.send_header('Content-type', 'text/css')
				else:
					self.send_header('Content-type',	'text/html')
				self.end_headers()
				self.wfile.write(f.read())
				f.close()
				return
				
			if urlBase.endswith('.png'):
				f = open(curdir + sep + urlBase, 'rb')
				
				self.send_response(200)
				self.send_header("Content-type", 'image/png')
				self.send_header("Content-Length", str(fstat(f.fileno())[6]))
				self.end_headers()
				shutil.copyfileobj(f, self.wfile)
			if urlBase.endswith('.gif'):
				f = open(curdir + sep + urlBase, 'rb')

				self.send_response(200)
				self.send_header("Content-type", 'image/gif')
				self.send_header("Content-Length", str(fstat(f.fileno())[6]))
				self.end_headers()
				shutil.copyfileobj(f, self.wfile)
				
			if urlBase == "/shutdownNow":
				self.send_response(200)
				self.send_header('Content-type', 'text/plain')
				self.end_headers()
				if self.client_address[0] == '127.0.0.1':
					self.wfile.write('Server shutting down!')
					global keep_running
					keep_running = False
				else:
					self.wfile.write('Remote clients are not permitted to stop the server.')
				return
			
			elif urlBase == "/status":
				self.wfile.write("running")
				return
			
			elif urlBase == "/serverInfo.txt":
				self.send_response(200)
				self.send_header('Content-type',	'text/plain')
				self.end_headers()
				
				if password:
					reqPass = True
				else:
					reqPass = False
				
				serverInfo = {"version": 1.0, "suffix": "", "requiresPassword":reqPass, "supportsArtwork":True}
				self.sendJSON(serverInfo, request)
				return
				
			elif urlBase == "/getAuthKey":
				if not params.has_key('password'):
					raise ParamError
				
				if md5.new(password).hexdigest() == params['password']:
					authKey = md5.new(password + self.client_address[0]).hexdigest()
					self.sendJSON({"authKey":authKey}, request)
				else:
					self.sendJSON({"authKey":False}, request)
			
			elif urlBase == "/artwork":
				global artworkFilename
				
				if password:
					authKey = md5.new(password + self.client_address[0]).hexdigest()
					if not params.has_key('authKey') or not params['authKey'] == authKey:
						self.send_error(403, "Invalid AuthKey")
						return
						
				
				if (iTunes == None):		
					iTunes = app('iTunes')
					
				artworks = iTunes.current_track.artworks.get()
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
						print 'unknown: ', format
						self.send_response(404)
						return
					
					fname=artworkFilename

					global lastArtwork
					if lastArtwork is None or lastArtwork != iTunes.current_track.album.get() or not path.exists(fname):
						system("osascript SaveArtwork.scpt")
						lastArtwork = iTunes.current_track.album.get()

					try:
						f = open(fname, 'rb')
					except IOError:
						self.send_error(404, "File not found")
						return
						
					self.send_response(200)
					self.send_header("Content-type", type)
					self.send_header("Content-Length", str(fstat(f.fileno())[6]))
					self.end_headers()
					shutil.copyfileobj(f, self.wfile)
				else:
					self.send_response(404)
				
			elif urlBase in ('/getSources', '/getPlaylists', '/getTracks', '/play', '/pause', '/playPause', 'stop':self.stop, 'playPlaylist':self.playPlaylist, 'playTrack':self.playTrack, 'nextTrack':self.nextTrack, 'prevTrack':self.prevTrack, 'setVolume':self.setVolume, 'volumeUp':self.volumeUp, 'volumeDown':self.volumeDown, 'currentTrack':self.currentTrack, 'playerStatus':self.playerStatus, 'fullStatus':self.fullStatus, 'playSettings':self.playSettings, 'setPlayerPosition':self.setPlayerPosition, 'setPlaySettings':self.setPlaySettings, 'search':self.search, 'visuals':self.visuals, 'visualSettings':self.visualSettings, 'setVisualizations':self.setVisualizations, 'setTrackName':self.setTrackName, 'setTrackArtist':self.setTrackArtist, 'setTrackAlbum':self.setTrackAlbum, 'setTrackRating':self.setTrackRating, 'setTrackGenre':self.setTrackGenre, 'setTrackComposer':self.setTrackComposer, 'setTrackComments':self.setTrackComments, 'createPlaylist':self.createPlaylist, 'addTrackToPlaylist':self.addTrackToPlaylist, 'deleteTrackFromPlaylist':self.deleteTrackFromPlaylist, 'deletePlaylist':self.deletePlaylist):
				
				if password:
					authKey = md5.new(password + self.client_address[0]).hexdigest()
					if not params.has_key('authKey') or not params['authKey'] == authKey:
						self.send_error(403, "Invalid AuthKey")
						return
						
				if (iTunes == None):
					iTunes = app('iTunes')
				
				self.send_response(200)
				self.send_header('Content-type', 'text/plain') # change to application/json in production
				self.end_headers()
				try:
					if urlBase == "/getSources":
						sourceList = []
						for source in iTunes.sources.get():
							sourceList.append({'name':cleanName(source.name.get()), 'id':source.id.get(), 'kind':className(source.kind.get())})
						self.sendJSON({'sources':sourceList}, request)
						
						del sourceList
					
					elif urlBase == "/getPlaylists":
						if not params.has_key('ofSource'):
							raise ParamError;
						playlists = []
						
						source = iTunes.sources.ID(params['ofSource'])
						
						if source.kind.get() == k.library and localLibrary != None:
							playlists = getLocalPlaylists(source.id.get())
						else:
							playlistSet = source.playlists.get()
							for playlist in playlistSet:
								playlists.append({'name':cleanName(playlist.name.get()), 'id':playlist.id.get(), 'source':int(params['ofSource']), 'duration':playlist.duration.get(), 'trackCount':len(playlist.tracks.get()), 'specialKind':className(playlist.special_kind.get())})
							
						self.sendJSON({'playlists':playlists}, request)
						
						del playlists
					
					elif urlBase == "/getTracks":
						if not params.has_key('ofPlaylist') or not params.has_key('ofSource'):
							raise ParamError;
						tracks = []
						
						source = iTunes.sources.ID(params['ofSource'])
						
						if source.kind.get() == k.library and localLibrary != None:
							tracks = getLocalTracksForPlaylist(params['ofPlaylist'], params['ofSource'])
						else:
							playlist = source.playlists.ID(params['ofPlaylist']).tracks.get()
							for track in playlist:
								trackObject = {'name':cleanName(track.name.get()), 'id':track.database_ID.get(), 'playlist':int(params['ofPlaylist']), 'source':int(params['ofSource']), 'duration':track.duration.get(), 'album':cleanName(track.album.get()), 'artist':cleanName(track.artist.get()), 'videoType':className(track.video_kind.get())}
							
								if (params.has_key('genres') and params['genres'] == '1'):
									trackObject['genre'] = cleanName(track.genre.get())
							
								if (params.has_key('ratings') and params['ratings'] == '1'):
									trackObject['rating'] = track.rating.get()
							
								if (params.has_key('composers') and params['composers'] == '1'):
									trackObject['composer'] = cleanName(track.composer.get())
							
								if (params.has_key('comments') and params['comments'] == '1'):
									trackObject['comments'] = cleanName(track.comment.get())
							
								tracks.append(trackObject)
						
						self.sendJSON({'tracks':tracks}, request)
						
						del tracks
						#del playlist
					
					elif urlBase == "/play":
						success = iTunes.play()
						self.sendJSON({"success":True}, request)
					
					elif urlBase == "/pause":
						success = iTunes.pause()
						self.sendJSON({"success":True}, request)
					
					elif urlBase == "/playPause":
						success = iTunes.playpause()
						self.sendJSON({"success":True}, request)
					
					elif urlBase == "/stop":
						success = iTunes.stop()
						self.sendJSON({"success":True}, request)
					
					elif urlBase == "/playPlaylist":
						if not params.has_key('playlist') or not params.has_key('ofSource'):
							raise ParamError;
							
						playlist = iTunes.sources.ID(params['ofSource']).playlists.ID(params['playlist'])
						playlist.play()
						iTunes.browser_windows[1].view.set(playlist)
						self.sendJSON({"success":True}, request)
						del playlist
					elif urlBase == "/playTrack":
						if not params.has_key('track') or not params.has_key('ofPlaylist') or not params.has_key('ofSource'):
							raise ParamError
						
						playlist = iTunes.sources.ID(params['ofSource']).playlists.ID(params['ofPlaylist'])
						
						if (params.has_key('once') and params.has_key('once') == '1'):
							playlist.tracks[its.database_ID == int(params['track'])].play(once=True)
						else:
							playlist.tracks[its.database_ID == int(params['track'])].play()
						iTunes.browser_windows[1].view.set(playlist)
						self.sendJSON({"success":True}, request)
						del playlist
						
					elif urlBase == "/nextTrack":
						success = iTunes.next_track()
						self.sendJSON({"success":True}, request)
					
					elif urlBase == "/prevTrack":
						success = iTunes.previous_track()
						self.sendJSON({"success":True}, request)
					
					elif urlBase == "/setVolume":
						if not params.has_key('volume'):
							raise ParamError;
						success = iTunes.sound_volume.set(params['volume'])
						self.sendJSON({"success":True}, request)
					
					elif urlBase == "/volumeUp":
						vol = iTunes.sound_volume.get() + 10
						if vol > 100:
							vol = 100
						
						iTunes.sound_volume.set(vol)
						self.sendJSON({"success":True}, request)
						
					elif urlBase == "/volumeDown":
						vol = iTunes.sound_volume.get() - 10
						if vol < 0:
							vol = 0
						
						iTunes.sound_volume.set(vol)
						self.sendJSON({"success":True}, request)
					
					elif urlBase == "/currentTrack":
						try:
							track = iTunes.current_track
							trackObject = {"name":cleanName(track.name.get()), "artist":cleanName(track.artist.get()), "album":cleanName(track.album.get()), "duration":track.duration.get()}
							
							if len(urlParts) > 1:
								if (params.has_key('genre') and params['genre'] == '1'):
									trackObject['genre'] = cleanName(track.genre.get())

								if (params.has_key('rating') and params['rating'] == '1'):
									trackObject['rating'] = track.rating.get()

								if (params.has_key('composer') and params['composer'] == '1'):
									trackObject['composer'] = cleanName(track.composer.get())
								
								if (params.has_key('comments') and params['comments'] == '1'):
									trackObject['comments'] = cleanName(track.comment.get())
									
						except CommandError:
							trackObject = {"name":False}
						
						self.sendJSON(trackObject, request)
						del trackObject
						
					elif urlBase == "/playerStatus":
						playerProgress = iTunes.player_position.get()
						
						if playerProgress == k.missing_value:
							playerProgress = 0
							
						infoObject = {"playState":className(iTunes.player_state.get()), "volume":iTunes.sound_volume.get(), "progress":playerProgress}
						self.sendJSON(infoObject, request)
						del infoObject
						
					elif urlBase == "/fullStatus":
						playerProgress = iTunes.player_position.get()
						
						if playerProgress == k.missing_value:
							playerProgress = 0
							
						infoObject = {"playState":className(iTunes.player_state.get()), "volume":iTunes.sound_volume.get(), "progress":playerProgress}
						try:
							track = iTunes.current_track
							trackObject = {"name":cleanName(track.name.get()), "artist":cleanName(track.artist.get()), "album":cleanName(track.album.get()), "duration":track.duration.get()}
							
							if len(urlParts) > 1:
								if (params.has_key('genre') and params['genre'] == '1'):
									trackObject['genre'] = cleanName(track.genre.get())

								if (params.has_key('rating') and params['rating'] == '1'):
									trackObject['rating'] = track.rating.get()

								if (params.has_key('composer') and params['composer'] == '1'):
									trackObject['composer'] = cleanName(track.composer.get())
								
								if (params.has_key('comments') and params['comments'] == '1'):
									trackObject['comments'] = cleanName(track.comment.get())
									
						except CommandError:
							trackObject = {"name":False}
						
						self.sendJSON(dict(infoObject, **trackObject), request)
						del infoObject
						del trackObject
						
					elif urlBase == "/setPlayerPosition":
						if not params.has_key('position'):
							raise ParamError
						
						iTunes.player_position.set(params['position'])
						
						self.sendJSON({"success":True}, request)
						
					elif urlBase == "/playSettings":
						if not params.has_key('ofPlaylist') or not params.has_key('ofSource'):
							raise ParamError
						
						playlist = iTunes.sources.ID(params['ofSource']).playlists.ID(params['ofPlaylist'])
						playSettings = {"shuffle":playlist.shuffle.get(), "repeat":className(playlist.song_repeat.get())}
						
						self.sendJSON(playSettings, request)
						del playlist
						del playSettings
						
					elif urlBase == "/setPlaySettings":
						if not params.has_key('ofPlaylist') or not params.has_key('ofSource'):
							raise ParamError
						
						playlist = iTunes.sources.ID(params['ofSource']).playlists.ID(params['ofPlaylist'])
						
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
						
						self.sendJSON({"success":True}, request)
						del playlist
						
					elif urlBase == "/search":
						if not params.has_key('for'):
							raise ParamError
						
						if params.has_key('ofPlaylist') or params.has_key('ofSource'):
							if not params.has_key('ofPlaylist') or not params.has_key('ofSource'):
								raise ParamError
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
						
						self.sendJSON({'tracks':tracks}, request)
						
						del results
						del tracks
						del playlist
						
					elif urlBase == "/visuals":
						visuals = iTunes.visuals.get()
						visualList = []
						for visual in visuals:
							visualList.append({"name":cleanName(visual.name.get()), "id":visual.id.get()})
						self.sendJSON({'visuals':visualList}, request)
						
						del visualList
						
					elif urlBase == "/visualSettings":
						visualInfo = {"name":iTunes.current_visual.name.get(), "fullScreen":iTunes.full_screen.get(), "displaying":iTunes.visuals_enabled.get(), "size":className(iTunes.visual_size.get())}
						
						self.sendJSON(visualInfo, request)
						del visualInfo
						
					elif urlBase == "/setVisualizations":
						if not params.has_key('visual') or not params.has_key('fullScreen') or not params.has_key('size') or not params.has_key('displaying'):
							raise ParamError
						
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
								pass
								# Make iTunes front app?
							iTunes.visuals_enabled.set(True)
						else:
							iTunes.visuals_enabled.set(False)
						
						self.sendJSON({"success":True}, request)
						
						
					elif urlBase == "/setTrackName":
						if not params.has_key('name'):
							raise ParamError
						
						if params.has_key('ofTrack') or params.has_key('ofPlaylist') or params.has_key('ofSource'):
							if not params.has_key('ofTrack') or not params.has_key('ofPlaylist') or not params.has_key('ofSource'):
								raise ParamError
						
						if not params.has_key('ofTrack'):
							track = iTunes.current_track
						else:
							track = iTunes.sources.ID(params['ofSource']).playlists.ID(params['ofPlaylist']).tracks[its.database_ID == int(params['ofTrack'])]
						
						track.name.set(base64.urlsafe_b64decode(params['name']))
						
						self.sendJSON({"success":True}, request)
						
						del track
						
					elif urlBase == "/setTrackArtist":
						if not params.has_key('artist'):
							raise ParamError
						
						if params.has_key('ofTrack') or params.has_key('ofPlaylist') or params.has_key('ofSource'):
							if not params.has_key('ofTrack') or not params.has_key('ofPlaylist') or not params.has_key('ofSource'):
								raise ParamError
						
						if not params.has_key('ofTrack'):
							track = iTunes.current_track
						else:
							track = iTunes.sources.ID(params['ofSource']).playlists.ID(params['ofPlaylist']).tracks[its.database_ID == int(params['ofTrack'])]
						
						track.artist.set(base64.urlsafe_b64decode(params['artist']))
						
						self.sendJSON({"success":True}, request)
						
						del track
						
					elif urlBase == "/setTrackAlbum":
						if not params.has_key('album'):
							raise ParamError
						
						if params.has_key('ofTrack') or params.has_key('ofPlaylist') or params.has_key('ofSource'):
							if not params.has_key('ofTrack') or not params.has_key('ofPlaylist') or not params.has_key('ofSource'):
								raise ParamError
						
						if not params.has_key('ofTrack'):
							track = iTunes.current_track
						else:
							track = iTunes.sources.ID(params['ofSource']).playlists.ID(params['ofPlaylist']).tracks[its.database_ID == int(params['ofTrack'])]
						
						track.album.set(base64.urlsafe_b64decode(params['album']))
						
						self.sendJSON({"success":True}, request)
						
						del track
					
					elif urlBase == "/setTrackRating":
						if not params.has_key('rating'):
							raise ParamError
						
						if params.has_key('ofTrack') or params.has_key('ofPlaylist') or params.has_key('ofSource'):
							if not params.has_key('ofTrack') or not params.has_key('ofPlaylist') or not params.has_key('ofSource'):
								raise ParamError
						
						if not params.has_key('ofTrack'):
							track = iTunes.current_track
						else:
							track = iTunes.sources.ID(params['ofSource']).playlists.ID(params['ofPlaylist']).tracks[its.database_ID == int(params['ofTrack'])]
						
						track.rating.set(params['rating'])
						
						self.sendJSON({"success":True}, request)
						del track
						
					elif urlBase == "/setTrackGenre":
						if not params.has_key('genre'):
							raise ParamError
						
						if params.has_key('ofTrack') or params.has_key('ofPlaylist') or params.has_key('ofSource'):
							if not params.has_key('ofTrack') or not params.has_key('ofPlaylist') or not params.has_key('ofSource'):
								raise ParamError
						
						if not params.has_key('ofTrack'):
							track = iTunes.current_track
						else:
							track = iTunes.sources.ID(params['ofSource']).playlists.ID(params['ofPlaylist']).tracks[its.database_ID == int(params['ofTrack'])]
						
						track.genre.set(base64.urlsafe_b64decode(params['genre']))
						
						self.sendJSON({"success":True}, request)
						
						del track
						
					elif urlBase == "/setTrackComposer":
						if not params.has_key('composer'):
							raise ParamError
						
						if params.has_key('ofTrack') or params.has_key('ofPlaylist') or params.has_key('ofSource'):
							if not params.has_key('ofTrack') or not params.has_key('ofPlaylist') or not params.has_key('ofSource'):
								raise ParamError
						
						if not params.has_key('ofTrack'):
							track = iTunes.current_track
						else:
							track = iTunes.sources.ID(params['ofSource']).playlists.ID(params['ofPlaylist']).tracks[its.database_ID == int(params['ofTrack'])]
						
						track.composer.set(base64.urlsafe_b64decode(params['composer']))
						
						self.sendJSON({"success":True}, request)
						
						del track
						
					elif urlBase == "/setTrackComments":
						if not params.has_key('comments'):
							raise ParamError
						
						if params.has_key('ofTrack') or params.has_key('ofPlaylist') or params.has_key('ofSource'):
							if not params.has_key('ofTrack') or not params.has_key('ofPlaylist') or not params.has_key('ofSource'):
								raise ParamError
						
						if not params.has_key('ofTrack'):
							track = iTunes.current_track
						else:
							track = iTunes.sources.ID(params['ofSource']).playlists.ID(params['ofPlaylist']).tracks[its.database_ID == int(params['ofTrack'])]
						
						track.comment.set(base64.urlsafe_b64decode(params['comments']))
						
						self.sendJSON({"success":True}, request)
						
						del track
						
					elif urlBase == "/createPlaylist":
						if not params.has_key('name'):
							raise ParamError
						
						newPlaylist = iTunes.make(new=k.playlist, with_properties={k.name: base64.urlsafe_b64decode(params['name'])})
						
						playlistObject = {"name":cleanName(newPlaylist.name.get()), "id":newPlaylist.id.get(), "source":newPlaylist.container.id.get(), "duration":0, "trackCount":0, "specialKind":className(newPlaylist.special_kind.get())}
						
						self.sendJSON(playlistObject, request)
						
						del playlistObject
						del newPlaylist
					
					elif urlBase == "/addTrackToPlaylist":
						if not params.has_key('toPlaylist') or not params.has_key('inSource'):
							raise ParamError
						
						if params.has_key('track') or params.has_key('ofPlaylist') or params.has_key('ofSource'):
							if not params.has_key('track') or not params.has_key('ofPlaylist') or not params.has_key('ofSource'):
								raise ParamError

						if not params.has_key('track'):
							track = iTunes.current_track
						else:
							track = iTunes.sources.ID(params['ofSource']).playlists.ID(params['ofPlaylist']).tracks[its.database_ID == int(params['track'])]
						newPlaylist = iTunes.sources.ID(params['inSource']).playlists.ID(params['toPlaylist'])
						newTrack = track.duplicate(to=newPlaylist)
						
						trackObject = {"name":cleanName(newTrack.name.get()), "id":newTrack.id.get(), "playlist":newPlaylist.id.get(), "source":newPlaylist.container.id.get(), "duration":newTrack.duration.get(), "album":cleanName(newTrack.album.get()), "artist":cleanName(newTrack.artist.get()), "videoType":className(newTrack.video_kind.get())}
						
						self.sendJSON(trackObject, request)
						
						del trackObject
						del newTrack
						del newPlaylist
						del track
						
					elif urlBase == "/deleteTrackFromPlaylist":
						if not params.has_key('track') or not params.has_key('ofPlaylist') or not params.has_key('ofSource'):
							raise ParamError
						
						track = iTunes.sources.ID(params['ofSource']).playlists.ID(params['ofPlaylist']).tracks[its.database_ID == int(params['track'])]
						
						track.delete()
						
						self.sendJSON({"success":True}, request)
						
						del track
						
					elif urlBase == "/deletePlaylist":
						if not params.has_key('playlist') or not params.has_key('ofSource'):
							raise ParamError
						
						playlist = iTunes.sources.ID(params['ofSource']).playlists.ID(params['playlist'])
						
						playlist.delete()
						
						self.sendJSON({"success":True}, request)
						
						del playlist
						
					return
				except ParamError:
					self.send_error(403, 'Forbidden (Parameter Error): %s' % self.path)
					return
			
			else:
				self.send_error(404, 'File Not Found: %s' % self.path)
				return
		
		except IOError:
			self.send_error(404,'File Not Found: %s' % self.path)
			return
	
def main():
	try:
		global keep_running, password, port, libraryFileLocation
		keep_running = True
		
		nextIsPass = False
		nextIsPort = False
		
		if environ.has_key('TC_PORT'):
			port = int(environ['TC_PORT'])
			del environ['TC_PORT']
		
		if environ.has_key('TC_PASSWORD'):
			password = environ['TC_PASSWORD'][:]
			del environ['TC_PASSWORD']
		
		for arg in sys.argv:
			if arg == "--password":
				nextIsPass = True
			elif arg == "--port":
				nextIsPort = True
			elif nextIsPass:
				password = arg
				nextIsPass = False
			elif nextIsPort:
				port = int(arg)
				nextIsPort = False
		
		server = HTTPServer(('', port), TCHandler)
		print 'started httpserver...'
		bonjourService = pybonjour.DNSServiceRegister(
			name = socket.gethostname().replace('.local', ''),
			regtype = '_tunage._tcp',
			port = port)
		
		loadLibraryFile(libraryFileLocation)
		while keep_running:
			server.handle_request()
			
		print 'termination command received, shutting down server'
		server.socket.close()
		bonjourService.close()
		return
	except KeyboardInterrupt, SystemExit:
		print 'termination command received, shutting down server'
		server.socket.close()
		bonjourService.close()
		return

if __name__ == '__main__':
	main()