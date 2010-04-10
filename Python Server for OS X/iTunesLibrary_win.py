# TuneConnect Server 2.0, conformant to Tunage API 1.0
# Copyright (C) 2007 Matt Patenaude
# iTunes Local Library Container (Windows, index-based)

import plistlib
from time import time

def cleanName(name):
	if (type(name) != type(u"Unicode")):
		return name
	else:
		return string.replace(repr(name)[2:-1], '\\x', '\\u00')
	return repr(name)[1:-1]

def className(name):
	return str(name)[2:]
	
def vForK(theObject, theKey):
	if theObject.has_key(theKey):
		return cleanName(theObject[theKey])
	else:
		return ""

class iTunesLibrary:
	library = None
	libraryFile = None
	lastUpdatedAt = 0
	expirationTime = 60
	
	def __init__(self, libraryFile, expirationTime = 60):
		self.libraryFile = libraryFile
		self.expirationTime = expirationTime
		
	def loadLibrary(self):
		self.library = plistlib.readPlist(self.libraryFile)
		self.lastUpdatedAt = time()
		return self.library
		
	def expire(self):
		self.lastUpdatedAt = 0
		
	def hasExpired(self):
		if self.expirationTime == None:
			return False
		return (time() - self.lastUpdatedAt) >= self.expirationTime
		
	def currentLibrary(self):
		if (self.hasExpired()):
			return self.loadLibrary()
		else:
			return self.library

	def getPlaylists(self, sourceID):
		localLibrary = self.currentLibrary()
		
		playlists = []
		
		index = 1
		
		for playlist in localLibrary['Playlists']:
			pItem = {'name':cleanName(playlist['Name']), 'id':index, 'source':sourceID}

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
			elif playlist.has_key('Purchased Music') and playlist['Purchased Music']:
				pItem['specialKind'] = 'Purchased_Music'
			elif playlist.has_key('Podcasts') and playlist['Podcasts']:
				pItem['specialKind'] = 'Podcasts'
			elif playlist.has_key('TV Shows') and playlist['TV Shows']:
				pItem['specialKind'] = 'TV_Shows'
			elif playlist.has_key('Videos') and playlist['Videos']:
				pItem['specialKind'] = 'Videos'
			else:
				pItem['specialKind'] = 'none'
				
			if playlist.has_key('Smart Info'):
				pItem['smart'] = True
			else:
				pItem['smart'] = False

			playlists.append(pItem)
			index += 1

		return playlists

	def getTracksForPlaylist(self, ofPlaylist, ofSource, params):
		localLibrary = self.currentLibrary()

		tracks = []

		playlist = localLibrary['Playlists'][int(ofPlaylist) - 1]

		if playlist.has_key('Playlist Items'):
			trackRefs = [ref['Track ID'] for ref in playlist['Playlist Items']]
		else:
			trackRefs = []
			
		index = 1
		for track in trackRefs:
			theTrack = localLibrary['Tracks'][str(track)]
			trackObject = {'name':vForK(theTrack, 'Name'), 'id':index, 'playlist':int(ofPlaylist), 'source':int(ofSource), 'album':vForK(theTrack, 'Album'), 'artist':vForK(theTrack, 'Artist')}

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

			if (params.has_key('genres') and params['genres'] == '1'):
				trackObject['genre'] = vForK(theTrack, 'Genre')
		
			if (params.has_key('ratings') and params['ratings'] == '1'):
				if theTrack.has_key('Rating'):
					result = theTrack['Rating']
				else:
					result = 0
				trackObject['rating'] = result
		
			if (params.has_key('composers') and params['composers'] == '1'):
				trackObject['composer'] = vForK(theTrack, 'Composer')
		
			if (params.has_key('comments') and params['comments'] == '1'):
				trackObject['comments'] = vForK(theTrack, 'Comments')
			
			if (params.has_key('datesAdded') and params['datesAdded'] == '1'):
				trackObject['dateAdded'] = theTrack['Date Added'].isoformat() + 'Z'

			if (params.has_key('bitrates') and params['bitrates'] == '1'):
				trackObject['bitrate'] = theTrack['Bit Rate']

			if (params.has_key('sampleRates') and params['sampleRates'] == '1'):
				trackObject['sampleRate'] = theTrack['Sample Rate']
		
			tracks.append(trackObject)
			index += 1

		return tracks