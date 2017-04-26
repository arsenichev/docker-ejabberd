#!/usr/bin/python
#
# Options available

import os
from optparse import OptionParser
from ConfigParser import ConfigParser, NoOptionError
import logging

# Logging instance
log = logging.getLogger(__name__)

class Options:
	parser = None
	options = None
	args = None
	cfg = None

	def __init__(self):
		log.debug("Option parser instance")
		self.parser = OptionParser(version="%prog 1.0")
		self.parser.add_option("-d", "--debug", action="store_true", dest="debug", default=False, help="Emit debugging to the console")
		self.parser.add_option("-c", "--config", dest="configfile", help="INI file with settings")

	def parseArgs(self):
		"""parse command line options"""
		(self.options, self.args) = self.parser.parse_args()

		"""configfile is required"""
		if not self.options.configfile:
			raise Exception("--config is required")

		"""Check readability of the config file"""
		if not os.path.exists(self.options.configfile):
			raise Exception("invalid configuration file (file does not exist)")
		if not os.access(self.options.configfile, os.R_OK):
			raise Exception("cannot read configuration file (no permissions)")

		"""Read configuration options."""
		self.parseConfig()

	def parseConfig(self):
		self.cfg = ConfigParser()
		self.cfg.read(self.options.configfile)

	def getValue(self, key, inisection=None, default=None):

		"""Check if self.options has values"""
		if not self.options:
			raise Exception("Run parseArgs first.")

		if not inisection:
			return getattr(self.options, key, default)

		try:
			return self.cfg.get(key, inisection)
		except NoOptionError:
			return default

	def getConfig(self):
		return self.cfg

