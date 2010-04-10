Notifications = {
	rNotes: {},
	addObserver: function(observer, notification) {
		if (!this.rNotes[notification])
			this.rNotes[notification] = [];
		
		this.rNotes[notification].push(observer);
	},
	
	postNotification: function(notification, userInfo) {
		userInfo = (userInfo == null) ? {} : userInfo;
		
		if (this.rNotes[notification])
			for (var i = 0; i < this.rNotes[notification].length; i++)
				if (typeof this.rNotes[notification][i] != 'undefined') this.rNotes[notification][i](userInfo);
	}
};