#!/usr/bin/python

# need root privileges

import struct
import sys
import time

from socket import AF_INET, AF_INET6, inet_ntoa

sys.path.append('python')
sys.path.append('build/python')
import nfqueue

count = 0

def cb(payload):
	global count

	print("python callback called !")
	count += 1

	data = payload.get_data()
	print(data)

	payload.set_verdict(nfqueue.NF_ACCEPT)

	sys.stdout.flush()
	return 1

q = nfqueue.queue()

print("open")
q.open()

print("bind")
q.bind(AF_INET)

#print "setting callback (should fail, wrong arg type)"
#try:
#	q.set_callback("blah")
#except TypeError, e:
#	print "type failure (expected), continuing"

print("setting callback")
q.set_callback(cb)

print("creating queue")
q.create_queue(0)

q.set_queue_maxlen(50000)

print("trying to run")
try:
	q.try_run()
except KeyboardInterrupt as e:
	print("interrupted")

print("%d packets handled" % count)

print("unbind")
q.unbind(AF_INET)

print("close")
q.close()
