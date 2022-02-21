#!/usr/bin/python3
#
#  Usage: transcribe.py REQUEST
#
#  REQUEST must be in format ID/CC/WORDS or ID/LON/LAT/WORDS.
#

import socket
import struct
import sys

def die_usage():
    sys.stdout.write("uasge: %s ID/CC/WORDS|ID/LON/LAT/WORDS\n" % sys.argv[0])
    sys.exit(1)

if (len(sys.argv) != 2):
    die_usage()

arglen =len(sys.argv[1].split('/'))
if (arglen < 2) or (arglen > 3):
    die_usage()

sock = socket.create_connection(('localhost', 8033))

data = sys.argv[1].encode('utf-8')
length = len(data)
sock.sendall(struct.pack('I', length) + data)

lendata = sock.recv(4)
if len(lendata) == 0:
    exit
length = struct.unpack('I', lendata)
print(sock.recv(length[0]).decode('utf-8'))

