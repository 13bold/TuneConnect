# TuneConnect Server Install Agent
# Copyright (C) 2008 Matt Patenaude

from Foundation import *
from os import path, spawnv, P_NOWAIT
from shutil import copytree, move
from appscript import *
from datetime import datetime
from time import sleep

def main():
	# First, we need to open up the server settings
	prefLocation = path.expanduser("~/Library/Preferences/net.tuneconnect.Server.plist")

	if not path.exists(prefLocation):
		# Assume default values for preferences
		prefs = {'libraryExpiryTime':86400, 'password':'', 'port':4242, 'useLibraryFile':True}
	else:
		# Load into a dictionary
		prefs = NSDictionary.dictionaryWithContentsOfFile_(prefLocation)
	
	# Grab the server port
	port = prefs['port']

	# Check if the server is running
	url = NSURL.URLWithString_('http://localhost:' + str(port) + '/tc.status')
	stopUrl = NSURL.URLWithString_('http://localhost:' + str(port) + '/tc.shutdownNow')
	error = None
	result, error = NSString.stringWithContentsOfURL_encoding_error_(url, NSUTF8StringEncoding)

	if (result != "Server Running"):
		# Not running, we're good
		pass
	else:
		# Gotta' stop that server
		result, error = NSString.stringWithContentsOfURL_encoding_error_(stopUrl, NSUTF8StringEncoding)
		if (result == None) or (result == ""):
			# Success!
			pass
		else:
			print "Error: Could not stop server"
			return
	
	# And finally, open the new pane :)
	spawnv(P_NOWAIT, '/usr/bin/open', ["", "TuneConnect Server.prefPane"])

if __name__ == '__main__':
	main()