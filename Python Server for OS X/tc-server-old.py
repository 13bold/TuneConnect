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
	
		#if (urlParts[1].has_key('genres') and urlParts[1]['genres'] == '1'):
		#	trackObject['genre'] = cleanName(track.genre.get())
	#
	#	if (urlParts[1].has_key('ratings') and urlParts[1]['ratings'] == '1'):
	#		trackObject['rating'] = track.rating.get()
	#
	#	if (urlParts[1].has_key('composers') and urlParts[1]['composers'] == '1'):
	#		trackObject['composer'] = cleanName(track.composer.get())
	#
	#	if (urlParts[1].has_key('comments') and urlParts[1]['comments'] == '1'):
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
				urlParts[1] = urlParts[1].split('&')
				partDict = {}
				for part in urlParts[1]:
					param = part.split('=', 1)
					partDict[param[0]] = param[1]
				
				urlParts[1] = partDict
			
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
				self.wfile.write(jOut(serverInfo))
				return
				
			elif urlBase == "/getAuthKey":
				if not urlParts[1].has_key('password'):
					raise ParamError
				
				if md5.new(password).hexdigest() == urlParts[1]['password']:
					authKey = md5.new(password + self.client_address[0]).hexdigest()
					self.wfile.write(jOut({"authKey":authKey}))
				else:
					self.wfile.write(jOut({"authKey":False}))
			
			elif urlBase == "/artwork":
				global artworkFilename
				
				if password:
					authKey = md5.new(password + self.client_address[0]).hexdigest()
					if not urlParts[1].has_key('authKey') or not urlParts[1]['authKey'] == authKey:
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
				
			elif urlBase in ('/getSources', '/getPlaylists', '/getTracks', '/play', '/pause', '/playPause', '/stop', '/playPlaylist', '/playTrack', '/nextTrack', '/prevTrack', '/setVolume', '/volumeUp', '/volumeDown', '/currentTrack', '/playerStatus', '/fullStatus', '/playSettings', '/setPlayerPosition', '/setPlaySettings', '/search', '/visuals', '/visualSettings', '/setVisualizations', '/setTrackName', '/setTrackArtist', '/setTrackAlbum', '/setTrackRating', '/setTrackGenre', '/setTrackComposer', '/setTrackComments', '/createPlaylist', '/addTrackToPlaylist', '/deleteTrackFromPlaylist', '/deletePlaylist'):
				
				if password:
					authKey = md5.new(password + self.client_address[0]).hexdigest()
					if not urlParts[1].has_key('authKey') or not urlParts[1]['authKey'] == authKey:
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
						self.wfile.write(jOut({'sources':sourceList}))
						
						del sourceList
					
					elif urlBase == "/getPlaylists":
						if not urlParts[1].has_key('ofSource'):
							raise ParamError;
						playlists = []
						
						source = iTunes.sources.ID(urlParts[1]['ofSource'])
						
						if source.kind.get() == k.library and localLibrary != None:
							playlists = getLocalPlaylists(source.id.get())
						else:
							playlistSet = source.playlists.get()
							for playlist in playlistSet:
								playlists.append({'name':cleanName(playlist.name.get()), 'id':playlist.id.get(), 'source':int(urlParts[1]['ofSource']), 'duration':playlist.duration.get(), 'trackCount':len(playlist.tracks.get()), 'specialKind':className(playlist.special_kind.get())})
							
						self.wfile.write(jOut({'playlists':playlists}))
						
						del playlists
					
					elif urlBase == "/getTracks":
						if not urlParts[1].has_key('ofPlaylist') or not urlParts[1].has_key('ofSource'):
							raise ParamError;
						tracks = []
						
						source = iTunes.sources.ID(urlParts[1]['ofSource'])
						
						if source.kind.get() == k.library and localLibrary != None:
							tracks = getLocalTracksForPlaylist(urlParts[1]['ofPlaylist'], urlParts[1]['ofSource'])
						else:
							playlist = source.playlists.ID(urlParts[1]['ofPlaylist']).tracks.get()
							for track in playlist:
								trackObject = {'name':cleanName(track.name.get()), 'id':track.database_ID.get(), 'playlist':int(urlParts[1]['ofPlaylist']), 'source':int(urlParts[1]['ofSource']), 'duration':track.duration.get(), 'album':cleanName(track.album.get()), 'artist':cleanName(track.artist.get()), 'videoType':className(track.video_kind.get())}
							
								if (urlParts[1].has_key('genres') and urlParts[1]['genres'] == '1'):
									trackObject['genre'] = cleanName(track.genre.get())
							
								if (urlParts[1].has_key('ratings') and urlParts[1]['ratings'] == '1'):
									trackObject['rating'] = track.rating.get()
							
								if (urlParts[1].has_key('composers') and urlParts[1]['composers'] == '1'):
									trackObject['composer'] = cleanName(track.composer.get())
							
								if (urlParts[1].has_key('comments') and urlParts[1]['comments'] == '1'):
									trackObject['comments'] = cleanName(track.comment.get())
							
								tracks.append(trackObject)
						
						self.wfile.write(jOut({'tracks':tracks}))
						
						del tracks
						#del playlist
					
					elif urlBase == "/play":
						success = iTunes.play()
						self.wfile.write(jOut({"success":True}))
					
					elif urlBase == "/pause":
						success = iTunes.pause()
						self.wfile.write(jOut({"success":True}))
					
					elif urlBase == "/playPause":
						success = iTunes.playpause()
						self.wfile.write(jOut({"success":True}))
					
					elif urlBase == "/stop":
						success = iTunes.stop()
						self.wfile.write(jOut({"success":True}))
					
					elif urlBase == "/playPlaylist":
						if not urlParts[1].has_key('playlist') or not urlParts[1].has_key('ofSource'):
							raise ParamError;
							
						playlist = iTunes.sources.ID(urlParts[1]['ofSource']).playlists.ID(urlParts[1]['playlist'])
						playlist.play()
						iTunes.browser_windows[1].view.set(playlist)
						self.wfile.write(jOut({"success":True}))
						del playlist
					elif urlBase == "/playTrack":
						if not urlParts[1].has_key('track') or not urlParts[1].has_key('ofPlaylist') or not urlParts[1].has_key('ofSource'):
							raise ParamError
						
						playlist = iTunes.sources.ID(urlParts[1]['ofSource']).playlists.ID(urlParts[1]['ofPlaylist'])
						
						if (urlParts[1].has_key('once') and urlParts[1].has_key('once') == '1'):
							playlist.tracks[its.database_ID == int(urlParts[1]['track'])].play(once=True)
						else:
							playlist.tracks[its.database_ID == int(urlParts[1]['track'])].play()
						iTunes.browser_windows[1].view.set(playlist)
						self.wfile.write(jOut({"success":True}))
						del playlist
						
					elif urlBase == "/nextTrack":
						success = iTunes.next_track()
						self.wfile.write(jOut({"success":True}))
					
					elif urlBase == "/prevTrack":
						success = iTunes.previous_track()
						self.wfile.write(jOut({"success":True}))
					
					elif urlBase == "/setVolume":
						if not urlParts[1].has_key('volume'):
							raise ParamError;
						success = iTunes.sound_volume.set(urlParts[1]['volume'])
						self.wfile.write(jOut({"success":True}))
					
					elif urlBase == "/volumeUp":
						vol = iTunes.sound_volume.get() + 10
						if vol > 100:
							vol = 100
						
						iTunes.sound_volume.set(vol)
						self.wfile.write(jOut({"success":True}))
						
					elif urlBase == "/volumeDown":
						vol = iTunes.sound_volume.get() - 10
						if vol < 0:
							vol = 0
						
						iTunes.sound_volume.set(vol)
						self.wfile.write(jOut({"success":True}))
					
					elif urlBase == "/currentTrack":
						try:
							track = iTunes.current_track
							trackObject = {"name":cleanName(track.name.get()), "artist":cleanName(track.artist.get()), "album":cleanName(track.album.get()), "duration":track.duration.get()}
							
							if len(urlParts) > 1:
								if (urlParts[1].has_key('genre') and urlParts[1]['genre'] == '1'):
									trackObject['genre'] = cleanName(track.genre.get())

								if (urlParts[1].has_key('rating') and urlParts[1]['rating'] == '1'):
									trackObject['rating'] = track.rating.get()

								if (urlParts[1].has_key('composer') and urlParts[1]['composer'] == '1'):
									trackObject['composer'] = cleanName(track.composer.get())
								
								if (urlParts[1].has_key('comments') and urlParts[1]['comments'] == '1'):
									trackObject['comments'] = cleanName(track.comment.get())
									
						except CommandError:
							trackObject = {"name":False}
						
						self.wfile.write(jOut(trackObject))
						del trackObject
						
					elif urlBase == "/playerStatus":
						playerProgress = iTunes.player_position.get()
						
						if playerProgress == k.missing_value:
							playerProgress = 0
							
						infoObject = {"playState":className(iTunes.player_state.get()), "volume":iTunes.sound_volume.get(), "progress":playerProgress}
						self.wfile.write(jOut(infoObject))
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
								if (urlParts[1].has_key('genre') and urlParts[1]['genre'] == '1'):
									trackObject['genre'] = cleanName(track.genre.get())

								if (urlParts[1].has_key('rating') and urlParts[1]['rating'] == '1'):
									trackObject['rating'] = track.rating.get()

								if (urlParts[1].has_key('composer') and urlParts[1]['composer'] == '1'):
									trackObject['composer'] = cleanName(track.composer.get())
								
								if (urlParts[1].has_key('comments') and urlParts[1]['comments'] == '1'):
									trackObject['comments'] = cleanName(track.comment.get())
									
						except CommandError:
							trackObject = {"name":False}
						
						self.wfile.write(jOut(dict(infoObject, **trackObject)))
						del infoObject
						del trackObject
						
					elif urlBase == "/setPlayerPosition":
						if not urlParts[1].has_key('position'):
							raise ParamError
						
						iTunes.player_position.set(urlParts[1]['position'])
						
						self.wfile.write(jOut({"success":True}))
						
					elif urlBase == "/playSettings":
						if not urlParts[1].has_key('ofPlaylist') or not urlParts[1].has_key('ofSource'):
							raise ParamError
						
						playlist = iTunes.sources.ID(urlParts[1]['ofSource']).playlists.ID(urlParts[1]['ofPlaylist'])
						playSettings = {"shuffle":playlist.shuffle.get(), "repeat":className(playlist.song_repeat.get())}
						
						self.wfile.write(jOut(playSettings))
						del playlist
						del playSettings
						
					elif urlBase == "/setPlaySettings":
						if not urlParts[1].has_key('ofPlaylist') or not urlParts[1].has_key('ofSource'):
							raise ParamError
						
						playlist = iTunes.sources.ID(urlParts[1]['ofSource']).playlists.ID(urlParts[1]['ofPlaylist'])
						
						if urlParts[1].has_key('shuffle'):
							if urlParts[1]['shuffle'] == '1':
								playlist.shuffle.set(True)
							else:
								playlist.shuffle.set(False)
						
						if urlParts[1].has_key('repeat'):
							if urlParts[1]['repeat'] == "one":
								rState = k.one
							elif urlParts[1]['repeat'] == "all":
								rState = k.all
							else:
								rState = k.off
							
							playlist.song_repeat.set(rState)
						
						self.wfile.write(jOut({"success":True}))
						del playlist
						
					elif urlBase == "/search":
						if not urlParts[1].has_key('for'):
							raise ParamError
						
						if urlParts[1].has_key('ofPlaylist') or urlParts[1].has_key('ofSource'):
							if not urlParts[1].has_key('ofPlaylist') or not urlParts[1].has_key('ofSource'):
								raise ParamError
							playlist = iTunes.sources.ID(urlParts[1]['ofSource']).playlists.ID(urlParts[1]['ofPlaylist'])
							source = int(urlParts[1]['ofSource'])
							playlistID = int(urlParts[1]['ofPlaylist'])
						else:
							playlist = iTunes.sources[1].playlists[1]
							source = iTunes.sources[1].id.get()
							playlistID = playlist.id.get()
						
						results = playlist.search(for_=base64.urlsafe_b64decode(urlParts[1]['for']))
						tracks = []
						for track in results:
							trackObject = {'name':cleanName(track.name.get()), 'id':track.database_ID.get(), 'playlist':playlistID, 'source':source, 'duration':track.duration.get(), 'album':cleanName(track.album.get()), 'artist':cleanName(track.artist.get()), 'videoType':className(track.video_kind.get())}
							
							if (urlParts[1].has_key('genres') and urlParts[1]['genres'] == '1'):
								trackObject['genre'] = cleanName(track.genre.get())
							
							if (urlParts[1].has_key('ratings') and urlParts[1]['ratings'] == '1'):
								trackObject['rating'] = track.rating.get()
							
							if (urlParts[1].has_key('composers') and urlParts[1]['composers'] == '1'):
								trackObject['composer'] = cleanName(track.composer.get())
							
							if (urlParts[1].has_key('comments') and urlParts[1]['comments'] == '1'):
								trackObject['comments'] = cleanName(track.comment.get())
							
							tracks.append(trackObject)
						
						self.wfile.write(jOut({'tracks':tracks}))
						
						del results
						del tracks
						del playlist
						
					elif urlBase == "/visuals":
						visuals = iTunes.visuals.get()
						visualList = []
						for visual in visuals:
							visualList.append({"name":cleanName(visual.name.get()), "id":visual.id.get()})
						self.wfile.write(jOut({'visuals':visualList}))
						
						del visualList
						
					elif urlBase == "/visualSettings":
						visualInfo = {"name":iTunes.current_visual.name.get(), "fullScreen":iTunes.full_screen.get(), "displaying":iTunes.visuals_enabled.get(), "size":className(iTunes.visual_size.get())}
						
						self.wfile.write(jOut(visualInfo))
						del visualInfo
						
					elif urlBase == "/setVisualizations":
						if not urlParts[1].has_key('visual') or not urlParts[1].has_key('fullScreen') or not urlParts[1].has_key('size') or not urlParts[1].has_key('displaying'):
							raise ParamError
						
						iTunes.current_visual.set(iTunes.visuals.ID(urlParts[1]['visual']))
						if urlParts[1]['size'] == "small":
							vSize = k.small
						elif urlParts[1]['size'] == "medium":
							vSize = k.medium
						else:
							vSize = k.large
						iTunes.visual_size.set(vSize)
						
						if urlParts[1]['fullScreen'] == '0':
							iTunes.full_screen.set(False)
						else:
							iTunes.full_screen.set(True)
						
						if urlParts[1]['displaying'] == '1':
							if not iTunes.full_screen.get():
								pass
								# Make iTunes front app?
							iTunes.visuals_enabled.set(True)
						else:
							iTunes.visuals_enabled.set(False)
						
						self.wfile.write(jOut({"success":True}))
						
						
					elif urlBase == "/setTrackName":
						if not urlParts[1].has_key('name'):
							raise ParamError
						
						if urlParts[1].has_key('ofTrack') or urlParts[1].has_key('ofPlaylist') or urlParts[1].has_key('ofSource'):
							if not urlParts[1].has_key('ofTrack') or not urlParts[1].has_key('ofPlaylist') or not urlParts[1].has_key('ofSource'):
								raise ParamError
						
						if not urlParts[1].has_key('ofTrack'):
							track = iTunes.current_track
						else:
							track = iTunes.sources.ID(urlParts[1]['ofSource']).playlists.ID(urlParts[1]['ofPlaylist']).tracks[its.database_ID == int(urlParts[1]['ofTrack'])]
						
						track.name.set(base64.urlsafe_b64decode(urlParts[1]['name']))
						
						self.wfile.write(jOut({"success":True}))
						
						del track
						
					elif urlBase == "/setTrackArtist":
						if not urlParts[1].has_key('artist'):
							raise ParamError
						
						if urlParts[1].has_key('ofTrack') or urlParts[1].has_key('ofPlaylist') or urlParts[1].has_key('ofSource'):
							if not urlParts[1].has_key('ofTrack') or not urlParts[1].has_key('ofPlaylist') or not urlParts[1].has_key('ofSource'):
								raise ParamError
						
						if not urlParts[1].has_key('ofTrack'):
							track = iTunes.current_track
						else:
							track = iTunes.sources.ID(urlParts[1]['ofSource']).playlists.ID(urlParts[1]['ofPlaylist']).tracks[its.database_ID == int(urlParts[1]['ofTrack'])]
						
						track.artist.set(base64.urlsafe_b64decode(urlParts[1]['artist']))
						
						self.wfile.write(jOut({"success":True}))
						
						del track
						
					elif urlBase == "/setTrackAlbum":
						if not urlParts[1].has_key('album'):
							raise ParamError
						
						if urlParts[1].has_key('ofTrack') or urlParts[1].has_key('ofPlaylist') or urlParts[1].has_key('ofSource'):
							if not urlParts[1].has_key('ofTrack') or not urlParts[1].has_key('ofPlaylist') or not urlParts[1].has_key('ofSource'):
								raise ParamError
						
						if not urlParts[1].has_key('ofTrack'):
							track = iTunes.current_track
						else:
							track = iTunes.sources.ID(urlParts[1]['ofSource']).playlists.ID(urlParts[1]['ofPlaylist']).tracks[its.database_ID == int(urlParts[1]['ofTrack'])]
						
						track.album.set(base64.urlsafe_b64decode(urlParts[1]['album']))
						
						self.wfile.write(jOut({"success":True}))
						
						del track
					
					elif urlBase == "/setTrackRating":
						if not urlParts[1].has_key('rating'):
							raise ParamError
						
						if urlParts[1].has_key('ofTrack') or urlParts[1].has_key('ofPlaylist') or urlParts[1].has_key('ofSource'):
							if not urlParts[1].has_key('ofTrack') or not urlParts[1].has_key('ofPlaylist') or not urlParts[1].has_key('ofSource'):
								raise ParamError
						
						if not urlParts[1].has_key('ofTrack'):
							track = iTunes.current_track
						else:
							track = iTunes.sources.ID(urlParts[1]['ofSource']).playlists.ID(urlParts[1]['ofPlaylist']).tracks[its.database_ID == int(urlParts[1]['ofTrack'])]
						
						track.rating.set(urlParts[1]['rating'])
						
						self.wfile.write(jOut({"success":True}))
						del track
						
					elif urlBase == "/setTrackGenre":
						if not urlParts[1].has_key('genre'):
							raise ParamError
						
						if urlParts[1].has_key('ofTrack') or urlParts[1].has_key('ofPlaylist') or urlParts[1].has_key('ofSource'):
							if not urlParts[1].has_key('ofTrack') or not urlParts[1].has_key('ofPlaylist') or not urlParts[1].has_key('ofSource'):
								raise ParamError
						
						if not urlParts[1].has_key('ofTrack'):
							track = iTunes.current_track
						else:
							track = iTunes.sources.ID(urlParts[1]['ofSource']).playlists.ID(urlParts[1]['ofPlaylist']).tracks[its.database_ID == int(urlParts[1]['ofTrack'])]
						
						track.genre.set(base64.urlsafe_b64decode(urlParts[1]['genre']))
						
						self.wfile.write(jOut({"success":True}))
						
						del track
						
					elif urlBase == "/setTrackComposer":
						if not urlParts[1].has_key('composer'):
							raise ParamError
						
						if urlParts[1].has_key('ofTrack') or urlParts[1].has_key('ofPlaylist') or urlParts[1].has_key('ofSource'):
							if not urlParts[1].has_key('ofTrack') or not urlParts[1].has_key('ofPlaylist') or not urlParts[1].has_key('ofSource'):
								raise ParamError
						
						if not urlParts[1].has_key('ofTrack'):
							track = iTunes.current_track
						else:
							track = iTunes.sources.ID(urlParts[1]['ofSource']).playlists.ID(urlParts[1]['ofPlaylist']).tracks[its.database_ID == int(urlParts[1]['ofTrack'])]
						
						track.composer.set(base64.urlsafe_b64decode(urlParts[1]['composer']))
						
						self.wfile.write(jOut({"success":True}))
						
						del track
						
					elif urlBase == "/setTrackComments":
						if not urlParts[1].has_key('comments'):
							raise ParamError
						
						if urlParts[1].has_key('ofTrack') or urlParts[1].has_key('ofPlaylist') or urlParts[1].has_key('ofSource'):
							if not urlParts[1].has_key('ofTrack') or not urlParts[1].has_key('ofPlaylist') or not urlParts[1].has_key('ofSource'):
								raise ParamError
						
						if not urlParts[1].has_key('ofTrack'):
							track = iTunes.current_track
						else:
							track = iTunes.sources.ID(urlParts[1]['ofSource']).playlists.ID(urlParts[1]['ofPlaylist']).tracks[its.database_ID == int(urlParts[1]['ofTrack'])]
						
						track.comment.set(base64.urlsafe_b64decode(urlParts[1]['comments']))
						
						self.wfile.write(jOut({"success":True}))
						
						del track
						
					elif urlBase == "/createPlaylist":
						if not urlParts[1].has_key('name'):
							raise ParamError
						
						newPlaylist = iTunes.make(new=k.playlist, with_properties={k.name: base64.urlsafe_b64decode(urlParts[1]['name'])})
						
						playlistObject = {"name":cleanName(newPlaylist.name.get()), "id":newPlaylist.id.get(), "source":newPlaylist.container.id.get(), "duration":0, "trackCount":0, "specialKind":className(newPlaylist.special_kind.get())}
						
						self.wfile.write(jOut(playlistObject))
						
						del playlistObject
						del newPlaylist
					
					elif urlBase == "/addTrackToPlaylist":
						if not urlParts[1].has_key('toPlaylist') or not urlParts[1].has_key('inSource'):
							raise ParamError
						
						if urlParts[1].has_key('track') or urlParts[1].has_key('ofPlaylist') or urlParts[1].has_key('ofSource'):
							if not urlParts[1].has_key('track') or not urlParts[1].has_key('ofPlaylist') or not urlParts[1].has_key('ofSource'):
								raise ParamError

						if not urlParts[1].has_key('track'):
							track = iTunes.current_track
						else:
							track = iTunes.sources.ID(urlParts[1]['ofSource']).playlists.ID(urlParts[1]['ofPlaylist']).tracks[its.database_ID == int(urlParts[1]['track'])]
						newPlaylist = iTunes.sources.ID(urlParts[1]['inSource']).playlists.ID(urlParts[1]['toPlaylist'])
						newTrack = track.duplicate(to=newPlaylist)
						
						trackObject = {"name":cleanName(newTrack.name.get()), "id":newTrack.id.get(), "playlist":newPlaylist.id.get(), "source":newPlaylist.container.id.get(), "duration":newTrack.duration.get(), "album":cleanName(newTrack.album.get()), "artist":cleanName(newTrack.artist.get()), "videoType":className(newTrack.video_kind.get())}
						
						self.wfile.write(jOut(trackObject))
						
						del trackObject
						del newTrack
						del newPlaylist
						del track
						
					elif urlBase == "/deleteTrackFromPlaylist":
						if not urlParts[1].has_key('track') or not urlParts[1].has_key('ofPlaylist') or not urlParts[1].has_key('ofSource'):
							raise ParamError
						
						track = iTunes.sources.ID(urlParts[1]['ofSource']).playlists.ID(urlParts[1]['ofPlaylist']).tracks[its.database_ID == int(urlParts[1]['track'])]
						
						track.delete()
						
						self.wfile.write(jOut({"success":True}))
						
						del track
						
					elif urlBase == "/deletePlaylist":
						if not urlParts[1].has_key('playlist') or not urlParts[1].has_key('ofSource'):
							raise ParamError
						
						playlist = iTunes.sources.ID(urlParts[1]['ofSource']).playlists.ID(urlParts[1]['playlist'])
						
						playlist.delete()
						
						self.wfile.write(jOut({"success":True}))
						
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