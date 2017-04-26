#!/usr/bin/python
#
# Call api of cobrowser.net

# Use httplib and json parsing
import httplib
import json
import logging
import socket

# Create logger instance
logging = logging.getLogger(__name__)

class Api:
	decoder = None
	config = None
	conn = None

	def __init__(self, config):
		self.decoder = json.JSONDecoder()
		self.config = config

	def __del__(self):
		if self.conn:
			self.conn.close()

	def request(self, body, logging):
		# Headers to sent
		headers = {}
		headers['Content-Type'] = 'application/x-www-form-urlencoded'
		headers['User-Agent'] = 'CoBrowser External Component'
		headers['Accept'] = '*/*'

		# Do request
		host=self.config.get('api', 'host')
		logging.info("request host: %s body: %s ", host, body)
		self.conn = httplib.HTTPConnection(host, port=80, timeout=10)
		self.conn.request('POST', self.config.get('api', 'file'), body=body, headers=headers)

		# Get response
		decode = []
		try:
			resp = self.conn.getresponse()
		except socket.timeout:
			logging.error("Response took to long to respond.")
			return decode

		# Check response
		if resp.status != 200:
			logging.error("Failed to do request")
			return decode

		data = resp.read()
		logging.info("response: " + data)
		try:
			decode = self.decoder.decode(data)
		except ValueError, e:
			logging.error("Failed to decode data: " + data)

		self.conn.close()
		return decode
