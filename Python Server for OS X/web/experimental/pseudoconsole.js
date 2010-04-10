pc = {
	element: null,
	alert: function(alertText) {
		var old = this.element.innerHTML;
		var newText = old + "\n<strong>" + alertText + "</strong>";
		this.element.innerHTML = newText;
	},
	log: function(logText) {
		var old = this.element.innerHTML;
		var newText = old + "\n" + logText;
		this.element.innerHTML = newText;
	}
}