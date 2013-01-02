#!/usr/bin/env python
"""
Checks if textutil will use the specified encoding to read one or more files.

Just wraps a call to textutil. Because there is no deterministic way to sniff the encoding
  of a text file, textutil can give false positives -- that is, it will read a file with
  a given encoding, even though this produces garbage.
  
However, my experiments indicate that it does this less readily than the Cocoa
  method +[NSString stringWithContentsOfFile:encoding:error:], indicating that textutil is not
  just a wrapper for NSString but is using some additional heuristics. In particular, textutil
  will correctly read UTF-16LE files when it is instructed to read them as UTF-8 or CP-1252.
  
  Those heuristics seem to be significantly more elaborate than whatever is applied by
  +[NSString stringWithContentsOfFile:encodingUsed:error:].
"""
import sys

def usage():
    print("usage:\n\t%s IANA_encoding_name FILE.." % sys.argv[0])
        
def main():
    if len(sys.argv) != 3:
        usage()
        sys.exit(2)

    input_encoding_name = sys.argv[1]
    files = sys.argv[2:]

    # assert: files and input_encoding_name initialized, but not validated

    for filename in files:
        did_read = can_read_file_with_encoding(filename,input_encoding_name)
        print("{0:45}, readable as {1:10} : {2}".format(filename,input_encoding_name,did_read))

def can_read_file_with_encoding(filename,input_encoding):
    import os, subprocess
    commandcomponents="textutil -cat txt -stdout -encoding utf-8 -format txt -inputencoding %s %s" % (input_encoding,filename)
    with open(os.devnull, "w") as fnull:
        retcode = subprocess.call(commandcomponents.split(),stdout=fnull,stderr=fnull)
    return (retcode == 0)
    
if __name__ == "__main__":
    main()
