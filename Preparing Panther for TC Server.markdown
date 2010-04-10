Preparing Panther for TC Server
===============================
Blah blah blah, prepare Python installation.

1. Prepare Python installation

	Use http://www.python.org/ftp/python/2.5.2/python-2.5.2-macosx.dmg
	WATCH FOR FAILURE!
	error: could not create...

2. Get ready to install. Open Terminal, etc.

		mkdir prep
		cd prep

3. Install Twisted

		wget http://tmrc.mit.edu/mirror/twisted/Twisted/2.5/Twisted-2.5.0.tar.bz2
		tar -jxvf Twisted\*
		cd Twisted\*/zope\*
		python setup.py install
		cd ..
		python setup.py install
		cd ..

3. Install pybonjour

		wget http://o2s.csail.mit.edu/download/pybonjour/pybonjour-1.1.0.tar.gz
		tar -zxvf pybonjour\*
		cd pybonjour\*
		python setup.py install
		cd ..

4. Install Appscript

		wget http://downloads.sourceforge.net/appscript/appscript-0.18.1.tar.gz
		tar -zxvf appscript\*
		cd appscript\*
		python setup.py install
		cd ..

5. Install PyObjC (snapshot provided by TuneConnect) METAPACKAGE

		wget http://www.tuneconnect.net/pyobjc-1.4.tar.bz2
		tar -jxvf pyobjc\*
		cd pyobjc\*
		python setup.py bdist\_mpkg --open
		cd ..

6. Install py2app (OPTIONAL, snapshot provided by TuneConnect)

		wget http://www.tuneconnect.net/py2app.tar.bz2
		tar -jxvf py2app\*
		cd py2app\*
		python setup.py install
		cd ../..

7. Remove your preparation directory

		rm -rf prep