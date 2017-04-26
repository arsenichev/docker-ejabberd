#!/usr/bin/python
#
# Authentication proxy app

import Api
import sys
import struct
import logging

# Logging instance
log = logging.getLogger('extauth')

class EjabberdInputError(Exception):
    def __init__(self, value):
        self.value = value
    def __str__(self):
        return repr(self.value)

class AuthApp:
	config = None
	api = None

	def __init__(self, config):
		self.config = config
		self.api = Api.Api(config)

	def read(self):
		log.debug("trying to read 2 bytes from ejabberd:")
		try:
			length = sys.stdin.read(2)
		except IOError:
			log.debug("ioerror")
		if len(length) is not 2:
			log.debug("ejabberd sent us wrong things!")
			# raise EjabberdInputError('Wrong input from ejabberd!')
		log.debug('got 2 bytes via stdin: %s'%length)
		#length = sys.stdin.read(2)
		(size,) = struct.unpack('>h', length)
		return sys.stdin.read(size).split(':')

	def write(self, success):
		answer = 0
		if success:
			answer = 1
		token = struct.pack('>hh', 2, answer)
		sys.stdout.write(token)
		sys.stdout.flush()

	def run(self):
		while True:
			try:
				data = self.read()
				if data[0] == "auth":
					self.write(self.auth(data[1], data[2], data[3]))
				elif data[0] == "isuser":
					self.write(self.isuser(data[1], data[2]))
				else:
					log.debug("asked unsupported operation: " + data[0])
					self.write(False)
			except KeyboardInterrupt:
				"""KeyboardInterrupt is the same as Ctrl-C"""
				return None
		return None

	def auth(self, username, server, password):

		# Generate body
		body = "action=checkpass"
		body+= "&domain=" + server
		body+= "&node=" + username
		body+= "&password=" + password

		# Do request
		log.info('authenticating: ' + body)
		resp = self.api.request(body, log)
		if 'success' not in resp:
			return False
		log.info('result: %s', ','.join(resp))
		return resp['success']

	def isuser(self, username, server):

		# Generate body
		body = "action=checkuser"
		body+= "&domain=" + server
		body+= "&node=" + username

		log.info('isuser: ' + body)
		# Do request
		resp = self.api.request(body, log)
		if 'exists' not in resp:
			return False
		log.info('result: %s', ','.join(resp))
		return resp['exists']
