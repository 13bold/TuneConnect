Tunage API, Version 1.2
=======================

> The Tunage API is currently in the process of being replaced by the Arena Protocol. More information will be posted here as it becomes available.

The Tunage API is designed to be flexible and portable, separate from any particular visual interface, allowing for a wide-range of different clients on many platforms. Servers are free to implement the API as they wish, within a small number of communication-related constraints for cross-client compatibility.

Communication Constraints
-------------------------
For version 1 of the Tunage API, communication MUST be completed via the HTTP protocol. Therefore, it makes sense to build Tunage servers off existing web servers, such as lighttpd, or a stripped down version of Apache. However, the communication is such a limited set of HTTP that it is indeed possible to reimplement only the portions of the protocol that are needed. The TuneConnect Project recommends [Python](http://www.python.org) as a viable tool for creating custom servers. Monitor outgoing requests from an official TuneConnect client to see what is necessary.

All requests must be made as HTTP GETs according to the specified URL structure below. All responses will be returned as single JSON objects, containing either the required result set, or a simple boolean key called "success".

The Tunage API is meant to be platform-independent. Thus, a crucial piece of the server specification is the `suffix` parameter returned from the server information request. When at all possible, we ask that your server directly support the below command URLs. However, we realize that in many cases this may not be possible. If a suffix is returned by your server (like `.php` for example), control URLs like `/currentTrackInfo` will instead be addressed as `/currentTrackInfo.php`. This feature allows a server to use any number of scripting languages, even on servers that do not support explicit URL rewriting.

### Zeroconf, Auto-discovery, and Bonjour ###

It is strongly suggested that, for servers running on OS X, and servers running on Windows and Linux with the appropriate software installed (Bonjour for Windows, or some other Zeroconf library), Tunage servers publish a Bonjour service. The service type should be `_tunage._tcp`.

### On Ports ###

The default port for any Tunage server MUST be **4242**. This is the standardized Tunage API port, and clients that aren't smart enough to correctly interpret Bonjour records, or accept a specified port from their users, should try here first. Servers may, at their option, provide a facility to change the port, but the default must remain at 4242.

### Plist Responses ###

Since Tunage was developed first for use with Mac OS X, it is to this platform that it caters most. As such, *ALL* commands (except `/artwork`) must be capable of returning their results in Apple's [XML Plist](http://en.wikipedia.org/wiki/Property_list) format. Commands are signaled that their results should be returned as a plist by the `asPlist=1` parameter, which should be checked by all commands.

The benefit of plist responses is the incredible parsing time gain: in Cocoa/Objective-C applications, a plist can parse up to 50 times faster than a JSON string of equal length. Plus, many languages include support for XML parsing, which may make it easier for client developers to write a plist parser than a JSON parser.

### Sending Strings ###

Because any strings sent will be transmitted via GET request, it's very possible that data can become mangled in transmission, especially across different clients and servers (as a result of URL special characters, incompatible escaping, etc.). As such, all string data being transmitted to the server from the client (but not in reverse-- JSON provides sufficient escaping facilities) MUST be encoded as [RFC 3548][]-compliant URL-safe Base64 (see Section 4). Simply put, it must be encoded as Base64, with all `+`'s replaced with `-`'s, and all `/`'s replaced with `_`'s.

[RFC 3548]: http://www.faqs.org/rfcs/rfc3548.html

The only exceptions to the Base64 rule are the password and the auth key, because they will already be SHA-1-hashed, which is an acceptable transport encoding.

Protocol Information
--------------------
There are a variety of factors that one must take into consideration when implementing the Tunage API.

### Extensibility ###

Extensions of the protocol are determined on a per-server and per-client basis-- there is no standardized plug-in model (it would be entirely impossible, as not every server will be built on the same codebase). However, there are some conventions to follow when adding features to the protocol.

First of all, it is recommended (but not required) that all extension methods be given a period-separated prefix. For instance, TuneConnect on Mac includes features for changing the AirPort speakers, one method being `availableSpeakers`. In the server, this would likely appear as `tc.availableSpeakers`, to indicate that it is not part of the official protocol.

Beyond that, it is only necessary that the server add the method's name into the `extensions` array under `serverInfo.txt` (see the method documentations below for more information). That way, clients will know whether or not a custom method is supported by the server.

### A Note on Track IDs ###

It should be noted that, wherever referenced, the track ID refers to the track's `database_ID` property, not any other property. This is available via Apple Events as `database_ID`, and is simply the track ID in the iTunes Music Library XML file.

### Using References ###

Version 1.0 of the protocol used a deprecated "track/ofPlaylist/ofSource" parameter syntax that was overly verbose, and quite frankly a pain to write. Version 1.1 introduces a new, more comfortable syntax: references. A reference is composed by separating the IDs of components with colons in order from lowest-level (ie, track) to highest-level (ie, source). For instance, a reference for track 400 of playlist 92 of source 40 would be written as `400:92:40`. This eliminates much of the verbosity and naming confusion associated with old-style parameters.

Servers conformant to version 1.1 of the protocol *SHOULD NOT* support old-style track referencing: this convenience can only impede adoption of the newer method. References are not a convenience, they are a revision to the protocol itself. Clients are welcome to support both formats for the purposes of backwards compatibility. Old-style parameters are listed under each respective command.

### Playlist Signatures ###

In order to allow clients to easily check for changes in playlists, the protocol provides for the use of a signature facility: the `getTracks` command (and the separate `signature` command, using the same parameters) may return a signature representing the set of track information returned from that command. In the official TuneConnect implementation, this signature is created by generating an MD5 hash of the JSON result of the command, but the signatures can be generated in any way, as long as they reliably indicate when track information has changed.

Keep in mind that signatures *must* differ based upon the parameters passed to the `getTracks`/`signature` command, as all of this information must be taken into account to determine expiration.

### Filtering and Filter Predicates ###

As it is not always desirable to browse tracks solely by playlist, version 1.2 of the protocol added support for filtering by means of *filter predicates*. Filter predicates are structural rules that define what tracks are acceptable in a result set, based on data about the track such as album association, artist, genre, composer, etc. By filtering the contents of the Library playlist by artist, for example, it is possible for clients to implement a music browser similar to that of iTunes, and that found on iPods.

Filter predicates are composed of a series of predicate expressions, contained within square brackets and separated by pipes (|). Multiple predicate expressions in a single filter predicate are logical AND evaluated on each item-- it is currently not possible to perform logical OR lookups. A predicate expression is composed of three components separated by colons: the three-letter type identifier, the filter mode, and the data to filter against. Please note that if the data is, or is expected to be, a string, it must be Base64-encoded.

In order to filter by a specific data type, the value for that data type *MUST* appear in the unfiltered result set (ie, to filter `getTracks` by genre, the `genres` parameter must be set to 1). Available three-letter type identifiers and associated data types include:

* `nam`: name (string)
* `alb`: album (string)
* `art`: artist (string)
* `gen`: genre (string)
* `cmp`: composer (string)
* `plc`: play count (int)
* `rat`: rating (int, 0 - 100)

The filter mode defines how the filter comparison is made. Available filter modes include:

* `eq`: the specified property of the track must exactly equal the data provided
* `c`: the specified property of the track must contain the data provided (strings only)
* `-eq`: the specified property of the track must NOT be equal to the data provided
* `-c`: the specified property of the track must NOT contain the data provided (strings only)
* `gt`: the specified property of the track must be greater than the data provided
* `gte`: the specified property of the track must be greater than or equal to the data provided
* `lt`: the specified property of the track must be less than the data provided
* `lte`: the specified property of the track must be less than or equal to the data provided

To provide an example: in order to filter a track set to only tracks with artist of U2, a genre that contains Rock but does not contain Holiday, and that has been played at least 10 times, you would use a predicate that looks like this.

	[art:eq:VTI=|gen:c:Um9jaw==|gen:-c:SG9saWRheQ==|plc:gte:10]
	
A little messy, but it gets the job done. To make it a little clearer, below is a COMPLETELY INVALID predicate without the Base64 encoding on the strings.

	[art:eq:U2|gen:c:Rock|gen:-c:Holiday|plc:gte:10]

### Memory Management: Ranges and Hydration ###

Tunage clients accessing servers from portable devices (or just really, really old ones) are likely to have very limited memory to work with. As such, version 1.2 of the Tunage API introduces two powerful memory management aids: ranges and object hydration.

*Ranges* do exactly what their name implies: they allow you to limit a result set to a certain *range* of items. In this way, you can selectively load data for a large result set in different chunks. To limit a result set, simply pass the `range` parameter to a supported command in the form of (lowerIndex),(upperIndex), using 0-based indexes. For example, if you only wanted the first 50 items of a list of playlists, you could specify:

	range=0,49

And then to retrieve the next set of 50...

	range=50,99

If the upper index exceeds the upper index of the result set, never fear -- the server will simply return every item in the result set. Ranges *DO NOT* affect signatures.

*Object hydration* is a very powerful tool for even the most stringent of memory conditions. By passing the parameter `dehydrated=1` to a supporting command, the server will eliminate all properties of the objects in question from the result set, with the exception of `name`, and will add the property `ref` in the traditional format. This then allows the client to lazy-load each object's information when it is necessary, and optionally discard that extra information (at the client's discretion) when the memory limit is approached.

Information for a dehydrated object is returned by calling the `hydrate` command with the single parameter `ref`. Some object types also allow you to call the singular form of the optional parameters of the parent-level command (ie, for tracks, you can add the `rating=1` parameter to get the track's rating). Object hydration is *NOT* recommended for desktop Tunage clients, as it can potentially interrupt application flow with loading delays. However, it is *STRONGLY* recommended for portable devices, in order to prevent potential crashes and memory warnings. In many cases, object hydration eliminates the need to use the aforementioned ranges, but not all -- test your client in both situations to see how it best performs. Object hydration *DOES* affect signatures -- signatures returned only represent the dehydrated data.

### `tunage` URLs ###

Clients, at their option, may respond to Tunage URLs of the form `tunage://host:port`, or simply `tunage://host` (assuming port 4242). Terminating slashes should not make any difference; generally speaking, the URL should conform to RFC 1808, containing only a host and port.

Server Information
------------------
**URL: `/serverInfo.txt`**
> This URL must return a single JSON object with five simple properties: `version`, containing a floating point representation of the server API's version, `suffix`, containing the required URL suffix (if any) to be appended to control URLs, `requiresPassword`, a boolean value specifying whether or not a password is required, `supportsArtwork`, a boolean value specifying whether or not the server is capable of serving the current iTunes album artwork, and `extensions`, an array listing the names of all non-standard methods that have been added to that particular server implementation (completely standard implementations should only send an empty array). Here is an example file for a PHP-powered Tunage server.

	{
		"version": 1.0,
		"suffix": ".php",
		"requiresPassword": false,
		"supportsArtwork": true,
		"extensions":[]
	}

**URL: `/getAuthKey?password=(password)`**
> A call to this method, with the SHA-1 hash of the appropriate password will return a simple JSON object with a single key, `authKey`, a string which contains the authorization key for making calls to the server. If the server requires a password, whatever this method returns as the auth key MUST be included in every other request (as the `authKey` parameter). The auth key is unique to the server's current password, and the client machine, making it somewhat difficult to hijack (but NOT IMPOSSIBLE).
>
> The auth key is generated by concatenating the SHA-1 hash of the server password and the IP address of the client machine, and then generating an SHA-1 hash of *that* (in pseudocode, `sha1(sha1(password) + ipAddress)`). The auth key will be a boolean false value if the password was incorrect. An example response follows.

	{"authKey": "63322cdb7977c2ec642fa4dbbb924ddef3238ad6"}

Sources
-------
**URL: `/getSources`**
> This URL must return a single JSON object with one key, `sources`: an array of objects, each object representing a source in iTunes. Each source must contain its `name` (string), its `id` (int), and its `kind` (string, being one of "library", "iPod", "audio\_CD", "MP3\_CD", "device", "radio\_tuner", "shared\_library", or "unknown"). A sample library response might look something like this.

	{
		sources: [
			{
				"kind":"library",
				"name":"Library",
				"id":41
			},
			{
				"kind":"radio_tuner",
				"name":"Radio",
				"id":6464
			},
			{
				"kind":"iPod",
				"name":"Matt\u2019s iPod",
				"id":6522
			}
		]
	}

**URL: `/preload?source=(sourceRef)`**
> This URL will ensure that a reference to the library, if cached, is loaded as soon as possible. This will speed up access from impatient devices, as it can be performed in the background, and eliminates the need to worry about expired libraries and long delays. This URL will return a single JSON object with one boolean key, `libraryReady`, as soon as the library has been loaded. Send this request asynchronously for best results.

Playlists
---------
**URL: `/getPlaylists?ofSource=(sourceRef)[&range=(lowerBound,upperBound)&dehyrdated=1]`**
> This URL must return a single JSON object with one key, `playlists`: an array of objects, each object representing a playlist in iTunes. Each playlist must contain its `name` (string), its `id` (int), its `source` (int, the ID of the source), the `trackCount` (int), `smart` (boolean), and its `specialKind` (string). Note that, in iTunes versions ≥ 7, it is appropriate to omit the Library playlist of the main source, as it is technically nonexistent.

**URL: `/signature?[ofPlaylist=(playlistRef)&filteredBy=(filterPredicate)&genres=1&ratings=1&composers=1&comments=1&datesAdded=1&bitrates=1&sampleRates=1&playCounts=1&dehydrated=1]`**
> This URL must return a single JSON object with one key, `signature`, which is a string specifying the track signature for the given request. The parameters are identical to those of the `getTracks` command, with the exception of the `signature` parameter (for obvious reasons). Please note that object hydration changes this signature, so if the original request was made for dehydrated objects, that parameter must be reflected here.
>
> Old-style parameters for this command: ofPlaylist=(playlistID)&ofSource=(sourceID)

Tracks
------
**URL: `/getTracks?[ofPlaylist=(playlistRef)&filteredBy=(filterPredicate)&genres=1&ratings=1&composers=1&comments=1&datesAdded=1&bitrates=1&sampleRates=1&playCounts=1&signature=1&range=(lowerBound,upperBound)&dehyrdated=1]`**
> This URL must return a single JSON object with one key (by default), `tracks`: an array of objects, each object representing a track in iTunes. Each track must contain its `name` (string), its `id` (int), its `playlist` (int, the ID of the playlist), its `source` (int, the ID of the source), its `duration` (float, in seconds), its `album` (string), its `artist` (string), and its `videoType` (string, from "none", "movie", "music\_video", and "TV\_show"-- "none" if not a video). Additionally, for each of the optional parameters, this function must include the track's `genre` (string), `rating` (int, out of 100), `composer` (string), `comments` (string), `dateAdded` (string), `bitrate` (int, in kbps), `sampleRate` (int, in Hz), and `playCount` (int). If the optional `signature` parameter is set to 1, a second key, `signature`, will be returned in addition to `tracks`, which will contain the track signature for that request. The playlist ref should be of the form `playlistID:sourceID`. If the playlist ref is not specified, the server should search within the Library playlist of the main source. Optionally, tracks can be filtered using a filter predicate, as composed using the format in the introduction. 
>
> Old-style parameters for this command: ofPlaylist=(playlistID)&ofSource=(sourceID)

Hydration
---------
**URL: `/hydrate?ref=(objectRef)[&genre=1&rating=1&composer=1&comments=1&dateAdded=1&bitrate=1&sampleRate=1&playCount=1]`**
> This URL returns a single object containing the properties that would normally apply to a response from this object's parent request (ie, for a track, the response from `getTracks`).

Controlling Music
-----------------
**URL: `/play`**
> Requests sent to this URL should simply invoke the iTunes "play" command. They should return a single object with one key, `success` (boolean).

**URL: `/pause`**
> Requests sent to this URL should simply invoke the iTunes "pause" command. They should return a single object with one key, `success` (boolean).

**URL: `/playPause`**
> Requests sent to this URL should simply invoke the iTunes "play/pause" command. They should return a single object with one key, `success` (boolean).

**URL: `/stop`**
> Requests sent to this URL should simply invoke the iTunes "stop" command. They should return a single object with one key, `success` (boolean).

**URL: `/playPlaylist?playlist=(playlistRef)`**
> Requests sent to this URL should switch the iTunes currently selected playlist to the playlist specified, and then execute the "play" command on the playlist object, thereby playing from the beginning of the list. They should return a single object with one key, `success` (boolean). The playlist ref should be of the form `playlistID:sourceID`.
>
> Old-style parameters for this command: playlist=(playlistID)&ofSource=(sourceID)

**URL: `/playTrack?track=(trackRef)[&once=0]`**
> Requests sent to this URL should switch the iTunes currently selected playlist to the playlist specified, then execute the "play" command on the specified track. They should return a single object with one key, `success` (boolean). Note that, if `once` is set to 1, the track will play once, then stop (rather than continuing in the playlist). The track ref should be of the form `trackID:playlistID:sourceID`.
>
> Old-style parameters for this command: track=(trackID)&ofPlaylist=(playlistID)&ofSource=(sourceID)

**URL: `/nextTrack`**
> Requests sent to this URL should simply invoke the iTunes "next track" command. They should return a single object with one key, `success` (boolean).

**URL: `/prevTrack`**
> Requests sent to this URL should simply invoke the iTunes "previous track" command. They should return a single object with one key, `success` (boolean).

**URL: `/setVolume?volume=(volume)`**
> Requests sent to this URL should set the iTunes playing volume to the provided integer value, between 0 and 100. They should return a single object with one key, `success` (boolean).

**URL: `/volumeUp`**
> Requests sent to this URL will increase the volume by 10, or to the max, whichever comes first. They should return a single object with one key, `success` (boolean).

**URL: `/volumeDown`**
> Requests sent to this URL will decrease the volume by 10, or to the minimum, whichever comes first. They should return a single object with one key, `success` (boolean).

Status Information
------------------
**URL: `/currentTrack?[genre=1&rating=1&composer=1&comments=1&dateAdded=1&bitrate=1&sampleRate=1&playCount=1]`**
> This URL must return a single object containing information on the currently playing track: the `name` (string), `artist` (string), `album` (string), and `duration` (float, in seconds -- yes, it's very precise). Additionally, for each of the optional parameters, this function must include the track's `genre` (string), `rating` (int, out of 100), `composer` (string), `comments` (string), `dateAdded` (string), `bitrate` (int, in kbps), and `sampleRate` (int, in Hz). If there is no current track playing, the object should only contain one key: `name` (bool), which should be set to boolean false. This request is designed for minimal clients, and runs slightly faster than `/fullStatus`. Clients that provide a full interface should instead use `/fullStatus`.

**URL: `/playerStatus`**
> This URL must return a single object containing information on the current status of iTunes: the `playState` (string, from "stopped", "playing", "paused", "fast\_forwarding", "rewinding"), `volume` (int, 1 to 100), and `progress` (int, seconds into current track).

**URL: `/fullStatus?[genre=1&rating=1&composer=1&comments=1&dateAdded=1&bitrate=1&sampleRate=1&playCount=1]`**
> In a sense, this is just a combination of `/currentTrack` and `/playerStatus` -- same parameters, and should return the combined information of both of them. Separating requests to `/currentTrack` (to check for track changes) and `/playerStatus` may speed things up a bit. That, of course, is up to how much work the client developer wants to put into the software.

**URL: `/setPlayerPosition?position=(position)`**
> This URL will set the player position (aka, the progress) of the current track to the number of seconds specified. Position should be an integer. The request will return a single object containing a single boolean property, `success`.

**URL: `/artwork`**
> This URL should return the data (including appropriate content-type and content-length headers) of the current album artwork from iTunes. This should be the same as if the URL pointed to a static image file, and the server were serving an ordinary image. Note that a server only needs to be able to respond to this URL if it returns a `supportsArtwork` value of `true` via the server information URL.

Play Settings (Shuffle, Repeat, etc.)
-------------------------------------
**URL: `/playSettings?ofPlaylist=(playlistRef)`**
> This URL should return an object containing information on the current play settings of the specified playlist: `shuffle` (bool), and `repeat` (string, from "off", "one", and "all"). The playlist ref should be of the form `playlistID:sourceID`.
>
> Old-style parameters for this command: ofPlaylist=(playlistID)&ofSource=(sourceID)

**URL: `/setPlaySettings?ofPlaylist=(playlistRef)[&shuffle=1&repeat=(off|one|all)]`**
> This URL should set the play settings of the specified playlist. The only required parameters are those that specify which playlist to operate on. Other than those, the user may specify settings for the playlist's shuffle and repeat options. This URL should return a single object with the `success` (bool) key. The playlist ref should be of the form `playlistID:sourceID`.
>
> Old-style parameters for this command: ofPlaylist=(playlistID)&ofSource=(sourceID)

Searching
---------
**URL: `/search?for=(search query)[&ofPlaylist=(playlistRef)&genres=1&ratings=1&composers=1&comments=1]`**
> This URL should return a result identical to that of `getTracks`, except the criteria for songs should be the search query. If a playlist is specified, the search should be performed within it. Otherwise, the search should apply to the main library. The search query should be passed as a URL-safe Base64 string. The playlist ref should be of the form `playlistID:sourceID`.
>
> Old-style parameters for this command: ofPlaylist=(playlistID)&ofSource=(sourceID)

Equalization
------------
**URL: `/EQSettings`**
> This URL should return a single object with several keys, representing the status of the equalizer at the time: `state` (boolean, representing on/off), `preset` (string), `id` (int, corresponding to current preset), and then `preamp`, `band1`, `band2`, ... `band10` (float, -12.0 to 12.0 representing band values).

**URL: `/EQPresets`**
> This URL should return a single object with one key, `presets`, which is an array of all of the EQ presets. Each preset is represented by an object with three properties: `name` (string), `id` (int), and `modifiable` (boolean). Clients should use `modifiable` to indicate whether or not they should first switch to the Manual preset (should be first in the list) when changes are made.

**URL: `/setEQState?state=(on|off)`**
> This URL turns the equalizer on or off. A single object containing the `success` (bool) should be returned.

**URL: `/setEQBand?band=(1-10,preamp)&value=(-12.0 - 12.0)`**
> This URL sets a given band (1 - 10, or the preamp) to the given floating point value between -12.0 and 12.0. A single object containing the `success` (bool) should be returned.

**URL: `/setEQPreset?preset=(presetID)`**
> This URL changes the current EQ preset to the one represented by the ID passed to `preset`. A single object containing the `success` (bool) should be returned.

Visualizations
--------------
**URL: `/visuals`**
> This URL returns a single object with one key, `visuals`, which is an array of all visuals installed in the copy of iTunes, each visual represented by an object with two properties: `name` (string) and `id` (int).

**URL: `/visualSettings`**
> This URL returns an object containing the information on the current visualization settings: `name` (string), `id` (int, corresponding to current visual), `fullScreen` (bool), `displaying` (bool), `size` (string, from "small", "medium", "large").

**URL: `/setVisualizations?visual=(visualID)&fullScreen=1&size=(small|medium|large)&displaying=1`**
> This URL sets the current visualization display settings. All parameters are required, though size is irrelevant if the visualizations are playing in fullscreen mode. A single object containing the `success` (bool) should be returned.

Song Information Editing
------------------------
**URL: `/setTrackName?name=(new name)[&ofTrack=(trackRef)]`**
> This URL only needs a single parameter, `name` (base64-encoded string), which represents the new name of the track in question. If no other parameters are passed, the function will be applied to the current track. Otherwise, a track, playlist, and source must all be specified to set the name of a specified track. The URL should return a single object with one key, `success` (boolean). The track ref should be of the form `trackID:playlistID:sourceID`.
>
> Old-style parameters for this command: ofTrack=(trackID)&ofPlaylist=(playlistID)&ofSource=(sourceID)

**URL: `/setTrackArtist?artist=(new artist)[&ofTrack=(trackRef)]`**
> This URL only needs a single parameter, `artist` (base64-encoded string), which represents the new artist of the track in question. If no other parameters are passed, the function will be applied to the current track. Otherwise, a track, playlist, and source must all be specified to set the artist of a specified track. The URL should return a single object with one key, `success` (boolean). The track ref should be of the form `trackID:playlistID:sourceID`.
>
> Old-style parameters for this command: ofTrack=(trackID)&ofPlaylist=(playlistID)&ofSource=(sourceID)

**URL: `/setTrackAlbum?album=(new album)[&ofTrack=(trackRef)]`**
> This URL only needs a single parameter, `album` (base64-encoded string), which represents the new album of the track in question. If no other parameters are passed, the function will be applied to the current track. Otherwise, a track, playlist, and source must all be specified to set the album of a specified track. The URL should return a single object with one key, `success` (boolean). The track ref should be of the form `trackID:playlistID:sourceID`.
>
> Old-style parameters for this command: ofTrack=(trackID)&ofPlaylist=(playlistID)&ofSource=(sourceID)

**URL: `/setTrackRating?rating=(new rating)[&ofTrack=(trackRef)]`**
> This URL needs only a single parameter, `rating`, which is a number from 1 to 100. If no other parameters are passed, it will set the rating of the current track (use increments of 20: 1 star = 20, 2 stars = 40, 4.5 stars = 90, etc.). Otherwise, a track, playlist, and source must all be specified to set the rating of a specific track. The URL should return a single object with one key, `success` (boolean). The track ref should be of the form `trackID:playlistID:sourceID`.
>
> Old-style parameters for this command: ofTrack=(trackID)&ofPlaylist=(playlistID)&ofSource=(sourceID)

**URL: `/setTrackGenre?genre=(new genre)[&ofTrack=(trackRef)]`**
> This URL only needs a single parameter, `genre` (base64-encoded string), which represents the new genre of the track in question. If no other parameters are passed, the function will be applied to the current track. Otherwise, a track, playlist, and source must all be specified to set the genre of a specified track. The URL should return a single object with one key, `success` (boolean). The track ref should be of the form `trackID:playlistID:sourceID`.
>
> Old-style parameters for this command: ofTrack=(trackID)&ofPlaylist=(playlistID)&ofSource=(sourceID)

**URL: `/setTrackComposer?composer=(new composer)[&ofTrack=(trackRef)]`**
> This URL only needs a single parameter, `composer` (base64-encoded string), which represents the new composer of the track in question. If no other parameters are passed, the function will be applied to the current track. Otherwise, a track, playlist, and source must all be specified to set the composer of a specified track. The URL should return a single object with one key, `success` (boolean). The track ref should be of the form `trackID:playlistID:sourceID`.
>
> Old-style parameters for this command: ofTrack=(trackID)&ofPlaylist=(playlistID)&ofSource=(sourceID)

**URL: `/setTrackComments?comments=(new comments)[&ofTrack=(trackRef)]`**
> This URL only needs a single parameter, `comments` (base64-encoded string), which represents the new comments for the track in question. If no other parameters are passed, the function will be applied to the current track. Otherwise, a track, playlist, and source must all be specified to set the comments for a specified track. The URL should return a single object with one key, `success` (boolean). The track ref should be of the form `trackID:playlistID:sourceID`.
>
> Old-style parameters for this command: ofTrack=(trackID)&ofPlaylist=(playlistID)&ofSource=(sourceID)

Playlist Manipulation
---------------------
**URL: `/createPlaylist?name=(name)`**
> This URL only needs a single parameter, `name` (base64-encoded string), which represents the name of the new playlist. At this point in time, iTunes only supports the creation of playlists on the main library source. The URL should return an object representing the playlist (should be identical to its `getPlaylist` result).

**URL: `/addTrackToPlaylist[?track=(trackRef)]&toPlaylist=(playlistRef)`**
> This URL requires only a playlist reference, and is intended to add tracks to a playlist. If no track information is specified, the current track will be added to the specified playlist (note that the playlist specification uses `toPlaylist` and `inSource`, as opposed to `ofPlaylist` and `ofSource`). To add a different track, pass the track ID, playlist, and source to the normal parameters. The URL should return an object representing the newly added track (should be identical to a single entry from a `getTracks` result, without any optional parameters). The track ref should be of the form `trackID:playlistID:sourceID`; the playlist ref should be of the form `playlistID:sourceID`.
>
> Old-style parameters for this command: [track=(track)&ofPlaylist=(playlist)&ofSource=(source)]&toPlaylist=(playlist)&inSource=(source)

**URL: `/deleteTrackFromPlaylist?track=(trackRef)`**
> This URL requires a reference to a track, and will remove the specified track from the playlist. If the Library playlist is specified, the track will be removed from the iTunes library. The URL should return a single object with one key, `success` (boolean). The track ref should be of the form `trackID:playlistID:sourceID`.
>
> Old-style parameters for this command: track=(trackID)&ofPlaylist=(playlistID)&ofSource=(sourceID)

**URL: `/deletePlaylist?playlist=(playlistRef)`**
> This URL should be self-explanatory. The URL should return a single object with one key, `success` (boolean). The playlist ref should be of the form `playlistID:sourceID`.
>
> Old-style parameters for this command: playlist=(playlist)&ofSource=(source)