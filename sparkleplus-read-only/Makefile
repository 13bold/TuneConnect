.PHONY: all localizable-strings

localizable-strings:
	rm en.lproj/Sparkle.strings || TRUE
	genstrings -o English.lproj -s SULocalizedString *.m *.h
	mv en.lproj/Localizable.strings English.lproj/Sparkle.strings

