#!/opt/local/bin/python2.7
"""Reports character encoding detected by the external chardet library.

Easiest install is via macports: "sudo port install py27-chardet"
"""
import chardet
import sys

for filename in sys.argv[1:]:
    print("%45s\t%s" % (filename, chardet.detect( open( filename , "r").read() ) ) )
