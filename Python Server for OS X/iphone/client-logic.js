Event.observe(window, 'load', prepareClient);

items = Array();

settings = Array();

server = null;


function prepareClient() {
	loader = new Image();
	loader.src = './ajax-loader.gif';
	
	check = new Image();
	check.src = './checkmark.gif';
	
	error = new Image();
	error.src = './error.gif';
	
	if (BrowserDetect.browser != 'iPhone') {
		overlayMessage('This interface was designed for use with the iPhone, and may not display correctly in your browser.', 7500);
		setTimeout(loadTCClient, 7550);
	} else {
		loadTCClient();
	}
}

function loadTCClient() {
	loaderStart('Loading TuneConnect...');
	server = new TCServer();

	server.serverConnected = serverConnected;
	server.authKeyResponseReceived = authKeyResponseReceived;
	server.serverReady = serverReady;
}

function serverConnected(theServer) {
	if (server.requiresPassword) {
		passwordOverlay();
	}
}

function authKeyResponseReceived(success) {
	if (!success) {
		loaderFail('Invalid password!');
		setTimeout(passwordOverlay, 1550);
	} else {
		loaderStop('Valid password!');
		setTimeout(listItemClick.bind(pluginItem), 1550);
	}
}

function serverReady(theServer) {
	//console.log('Server ready');
	loaderStart('Loading sources...');
	server.doCommand('getSources', null, sourcesReceived);
}

function sourcesReceived(response) {
	loaderStop('Sources ready!');
}

function loaderStart(message) {
	window.scrollTo(0,0);
	$('message').innerHTML = message;
	$('passwordForm').innerHTML = '';
	$('statusImage').src = './ajax-loader.gif';
	$('overlayImage').style.display = '';
	$('overlay').style.display = '';
}

function loaderStop(completedMessage, timeout) {
	window.scrollTo(0,0);
	$('overlayImage').style.display = '';
	$('passwordForm').innerHTML = '';
	$('statusImage').src = './checkmark.gif';
	$('message').innerHTML = completedMessage;
	
	if (!timeout) {
		timeout = 1500;
	}
	setTimeout(loaderHide, timeout);
}

function loaderFail(completedMessage, timeout) {
	window.scrollTo(0,0);
	$('overlayImage').style.display = '';
	$('passwordForm').innerHTML = '';
	$('statusImage').src = './error.gif';
	$('message').innerHTML = completedMessage;
	
	if (!timeout) {
		timeout = 1500;
	}
	setTimeout(loaderHide, timeout);
}

function overlayMessage(message, timeout) {
	window.scrollTo(0,0);
	$('message').innerHTML = message;
	$('passwordForm').innerHTML = '';
	$('overlayImage').style.display = 'none';
	$('overlay').style.display = '';
	
	if (!timeout) {
		timeout = 1500;
	}
	setTimeout(loaderHide, timeout);
}

function passwordOverlay() {
	window.scrollTo(0,0)
	$('message').innerHTML = 'Please enter your password';
	$('passwordForm').innerHTML = '<form method="post" action="#" onsubmit="return processPassword();"><p><input type="password" id="pass" /></p></form>';
	$('overlayImage').style.display = 'none';
	$('overlay').style.display = '';
	$('pass').focus();
}

function processPassword() {
	password = $F('pass');
	$('pass').blur();
	window.scrollTo(0,0);
	loaderStart('Validating password...');
	server.getAuthKeyForPassword(password);
	// do password processing
	return false;
}

function loaderHide() {
	$('overlay').style.display = 'none';
	$('overlayImage').style.display = 'none';
	$('passwordForm').innerHTML = '';
	$('statusImage').src = '#';
}

function displayList(originalRequest) {
	response = originalRequest.responseText.evalJSON(true);
	
	if (response.error) {
		loaderFail(response.message, 2000);
		
		resetter = listItemClick.bind(this.previousItem);
		setTimeout(resetter, 2050);
					
		return;
	}
	
	items = response.items;
	
	container = document.createElement('ol');
	for (var i=0; i < items.length; i++) {
		item = items[i];
		thisItem = document.createElement('li');
		thisItem.innerHTML = item.label;
		if (item.label2) {
			thisItem.innerHTML = item.label + '<span class="line2">'+item.label2+'</span>';
		}
		if (item.isGroup) {
			thisItem.className = 'group';
		}
		item.previousItem = this;
		thisItem.onclick = listItemClick.bind(item);
		container.appendChild(thisItem);
	}
	
	
	if (!this.omitBack) {
		$('backButton').onclick = backButtonClick.bind(this);
		$('backButton').style.display = '';
	} else {
		$('backButton').style.display = 'none';
	}
	
	
	if (response.more !== false) {
		moreItem = document.createElement('li');
		
		moreMessage = (response.more == 1) ? 'There is 1 more item.' : 'There are '+response.more+' more items.';
		moreItem.innerHTML = '<span class="more">Show More</span><span class="line2">'+moreMessage+'</span>';
		moreItem.onclick = moreButtonClick.bind(this);
		container.appendChild(moreItem);
	}
	
	$('header').onclick = homeClick.bind(this);
	
	$('contentScroll').innerHTML = '';
	window.scrollTo(0,0);
	$('contentScroll').appendChild(container);
	
	loaderStop(this.completedMessage, 2000);
}

function stopContainer(originalRequest) {
	response = originalRequest.responseText.evalJSON(true);
	if (response.error) {
		loaderFail(response.message, 2000);
	} else {
		loaderStop(this.completedMessage, 2000);
	}
}

function backButtonClick() {
	if (this.listStart > 0) {
		this.listStart -= 25;
		doThis = listItemClick.bind(this);
	} else {
		doThis = listItemClick.bind(this.previousItem);
	}
	
	doThis();
}

function moreButtonClick() {
	if (!this.listStart) {
		this.listStart = 0;
	}
	this.listStart += 25;
	doThis = listItemClick.bind(this);
	
	doThis();
}

function homeClick() {
	this.listStart = 0;
	doThis = listItemClick.bind(this);
	
	doThis();
}

function listItemClick() {
	loaderStart(this.loadingMessage);
	request = {
		method: this.callback,
		expectsList: this.isGroup,
		listStart: (this.listStart) ? this.listStart : 0,
		data: this.data
	};
	if (this.isGroup) {
		$('header').innerHTML = this.label;
		$('contentScroll').innerHTML = '';
	}
	complete = (this.isGroup) ? displayList.bind(this) : stopContainer.bind(this);
	request = $H(request).toJSON();
	new Ajax.Request('handler.php', {
		method: 'post',
		postBody: request,
		contentType: 'application/json',
		onComplete: complete
	});
}