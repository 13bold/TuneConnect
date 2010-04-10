browser = {
	currentSource: null,
	sources: []
}

function getSources() {
	server.doCommand('getSources', null, processSources);
}

function processSources(response) {
	var sources = response.sources;
	
	var totalNum = sources.length;
	var validSources = [];
	for (var i = 0; i < totalNum; i++) {
		if (sources[i].kind != 'radio_tuner' && sources[i].kind != 'iPod') {
			validSources.push(sources[i]);
			sources[i].playlists = false;
			sources[i].currentPlaylist = false;
		}
	}
	
	var validNum = validSources.length;
	
	browser.sources = validSources;
	pc.log('Sources loaded: ' + totalNum + ' total, ' + validNum + ' valid');
	
	if (validNum < 1) {
		$('sourceContainer').innerHTML = 'No Valid Sources Available';
		return;
	} else if (validNum == 1) {
		browser.currentSource = validSources[0];
		$('sourceContainer').innerHTML = 'Source: ' + validSources[0].name + '<input type="hidden" id="sourceChooser" value="' + validSources[0].id + '" />';
	} else {
		browser.currentSource = validSources[0];
		$('sourceContainer').innerHTML = 'Source: <select id="sourceChooser"></select>';
		
		for (i = 0; i < validNum; i++) {
			var opt = document.createElement('option');
			opt.value = validSources[i].id;
			opt.innerHTML = validSources[i].name;
			
			$('sourceChooser').appendChild(opt);
		}
	}
	
	$('sourceChooser').onchange = sourceChanged;
	sourceChanged();
}

function sourceChanged() {
	pc.log('Source changed (' + $('sourceChooser').value + '), identifying...');
	
	var newSource = selectSource($('sourceChooser').value);
	browser.currentSource = newSource;
	pc.alert(newSource.name);
	
	emptyTrackBrowser();
	
	if (newSource.playlists == false) {
		newSource.playlists = true;
		updatePlaylistsForSource(newSource);
	} else displayPlaylistsForSource(newSource);
}

function selectSource(id) {
	var numSources = browser.sources.length;
	var newSource = browser.currentSource;
	for (var i = 0; i < numSources; i++) {
		if (browser.sources[i].id == id)
			newSource = browser.sources[i];
	}
	return newSource;
}

function updatePlaylistsForSource(source) {
	pc.log('Updating playlist listing...');
	
	this.source = source;
	
	if (source == browser.currentSource) {
		$('playlists').innerHTML = '';
		loader = document.createElement('li');
		loader.innerHTML = 'Loading...';
		$('playlists').appendChild(loader);
	}
	
	server.doCommand('getPlaylists', {'ofSource':source.id}, function(response){processPlaylists(response, this.source);}.bind(this));
}

function processPlaylists(response, source) {
	var playlists = response.playlists;
	source.playlists = playlists;
	var numPlaylists = playlists.length;
	
	for (var i = 0; i < numPlaylists; i++) {
		playlists[i].tracks = [];
		playlists[i].signature = 'notloaded';
	}
	
	pc.log('Playlists received! (' + numPlaylists + ')');
	pc.log('Current source playlist count: ' + browser.currentSource.playlists.length);
	
	if (source == browser.currentSource) displayPlaylistsForSource(source);
}

function displayPlaylistsForSource(source) {
	pc.log('Displaying playlists');
	if (source != browser.currentSource)
		pc.alert('Warning: displaying playlists for non-current source!');
	
	var playlists = source.playlists;
	var numPlaylists = playlists.length;
	
	var newList = document.createElement('ul');
	
	for (var i = 0; i < numPlaylists; i++) {
		pl = document.createElement('li');
		pl.innerHTML = playlists[i].name;
		
		pl.className = 'playlist kind_' + playlists[i].specialKind;
		
		if (playlists[i].smart && playlists[i].specialKind == 'none')
			pl.className += ' smart';
		
		if (playlists[i] == source.currentPlaylist)
			pl.className += ' selected';
		
		props = {'source':source, 'playlist':playlists[i], 'ref':(playlists[i].id + ':' + source.id), 'el':pl};
		
		pl.onclick = function(){playlistClicked(this);}.bind(props);
		
		newList.appendChild(pl);
	}
	
	pc.log('Replacing node in document...');
	$('playlists').parentNode.replaceChild(newList, $('playlists'));
	newList.id = 'playlists';
	pc.log('Playlists ready!');
	
	if (source.currentPlaylist) {
		props = {
			'source': source,
			'playlist': source.currentPlaylist,
			'ref': (source.currentPlaylist.id + ':' + source.id),
			'el': false
		};
		playlistClicked(props);
	}
}

function clearPlaylistCache() {
	var numSources = browser.sources.length;
	for (var i = 0; i < numSources; i++)
		browser.sources[i].playlists = false;
	
	sourceChanged();
}

function playlistClicked(properties) {
	var playlist = properties.playlist;
	var source = properties.source;
	var pRef = properties.ref;
	
	pc.alert('Playlist clicked: ' + playlist.name);
	
	if (!properties.el) {
		var pLists = $('playlists').getElementsByTagName('li');
		var numLists = pLists.length;

		for (var i = 0; i < numLists; i++)
			if (pLists[i].className.indexOf('selected') > -1) properties.el = pLists[i];
	}
	
	clearPlaylistSelection();
	
	source.currentPlaylist = playlist;
	properties.el.className += ' selected';
	
	checkSigAndDisplayTracksForPlaylist(playlist, source, pRef);
}

function clearPlaylistSelection() {
	var pLists = $('playlists').getElementsByTagName('li');
	var numLists = pLists.length;
	
	for (var i = 0; i < numLists; i++)
		pLists[i].className = pLists[i].className.replace(' selected', '');
}

function constructTrackItem(index, title, time, artist, album, rating, genre) {
	var row = document.createElement('tr');
	
	var iField = document.createElement('td');
	iField.innerHTML = index;
	iField.className = 'field_index';
	row.appendChild(iField);
	
	var titleField = document.createElement('td');
	titleField.innerHTML = title;
	titleField.className = 'field_name';
	row.appendChild(titleField);
	
	var timeField = document.createElement('td');
	timeField.innerHTML = time;
	timeField.className = 'field_duration';
	row.appendChild(timeField);
	
	var artistField = document.createElement('td');
	artistField.innerHTML = artist;
	artistField.className = 'field_artist';
	row.appendChild(artistField);
	
	var albumField = document.createElement('td');
	albumField.innerHTML = album;
	albumField.className = 'field_album';
	row.appendChild(albumField);
	
	var ratingField = document.createElement('td');
	ratingField.innerHTML = rating + '/100';
	ratingField.className = 'field_rating';
	row.appendChild(ratingField);
	
	var genreField = document.createElement('td');
	genreField.innerHTML = genre;
	genreField.className = 'field_genre';
	row.appendChild(genreField);
	
	return row;
}

function emptyTrackBrowser() {
	var el = $('trackBody');
	
	while (el.firstChild)
		el.removeChild(el.firstChild);
}

function checkSigAndDisplayTracksForPlaylist(playlist, source, ref) {
	pc.log('Checking signature for ' + playlist.name + '...');
	
	props = {
		'playlist': playlist,
		'source': source,
		'ref': ref
	};
	
	server.doCommand('signature', {'ofPlaylist':ref, 'ratings':1, 'genres':1}, function(response){processSignature(response, this.playlist, this.source, this.ref);}.bind(props));
}

function processSignature(response, playlist, source, ref) {
	var sig = response.signature;
	
	if (playlist.signature != sig) {
		pc.log('Signature mismatch, updating...');
		updateTracksForPlaylist(playlist, source, ref);
	} else {
		pc.log('Signatures match, displaying (if warranted)...');
		if (playlist == browser.currentSource.currentPlaylist) displayTracksForPlaylist(playlist, source);
	}
}

function updateTracksForPlaylist(playlist, source, ref) {
	pc.log('Updating track listing for ' + playlist.name + '...');
	
	props = {
		'playlist': playlist,
		'source': source,
		'ref': ref
	};
	
	/*if (playlist == browser.currentSource.currentPlaylist) {
		var loader = constructTrackItem('', 'Loading...', '', '', '', 0, '');
		emptyTrackBrowser();
		$('trackBody').appendChild(loader);
	}*/
	
	server.doCommand('getTracks', {'ofPlaylist':ref, 'ratings':1, 'genres':1, 'signature':1}, function(response){processTracks(response, this.playlist, this.source);}.bind(props));
}

function processTracks(response, playlist, source) {
	var tracks = response.tracks;
	playlist.tracks = tracks;
	var numTracks = tracks.length;
	
	for (var i = 0; i < numTracks; i++) {
		tracks[i].ref = tracks[i].id + ':' + playlist.id + ':' + source.id;
	}
	
	playlist.signature = response.signature;
	
	pc.log('Tracks received! (' + numTracks + ')');
	pc.log('Current playlist track count: ' + browser.currentSource.currentPlaylist.tracks.length);
	
	if (playlist == browser.currentSource.currentPlaylist) displayTracksForPlaylist(playlist, source);
}

function displayTracksForPlaylist(playlist, source) {
	pc.log('Displaying tracks');
	if (playlist != browser.currentSource.currentPlaylist)
		pc.alert('Warning: displaying tracks for non-current playlist!');
	
	var tracks = playlist.tracks;
	var numTracks = tracks.length;
	
	var body = document.createElement('tbody');
	emptyTrackBrowser();
	
	for (var i = 0; i < numTracks; i++) {
		var track = tracks[i];
		var tr = constructTrackItem(i+1, track.name, track.duration, track.artist, track.album, track.rating, track.genre);
		
		tr.className = 'track';
		if (i % 2 == 0) tr.className += ' odd';
		
		props = {'source':source, 'playlist':playlist, 'track':track, 'ref':track.ref, 'el':tr};
		
		tr.onclick = function(){trackClicked(this);}.bind(props);
		tr.ondblclick = function(){return trackPlay(this);}.bind(props);
		
		body.appendChild(tr);
	}
	
	pc.log('Replacing node in document...');
	$('trackBody').parentNode.replaceChild(body, $('trackBody'));
	body.id = 'trackBody';
	pc.log('Tracks ready!');
}

function trackClicked(properties) {		
	clearTrackSelection();
	properties.el.className += ' selected';
}

function clearTrackSelection() {
	var ts = $('trackBody').getElementsByTagName('tr');
	var numLists = ts.length;
	
	for (var i = 0; i < numLists; i++)
		ts[i].className = ts[i].className.replace(' selected', '');
}

function trackPlay(properties) {
	var track = properties.track;
	var playlist = properties.playlist;
	var source = properties.source;
	var tRef = properties.ref;
	
	pc.alert('Playing "' + track.name + '"...');
	
	server.doCommand('playTrack', {'track':tRef});
	return false;
}