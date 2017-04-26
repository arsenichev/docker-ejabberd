#!/usr/bin/python
#
# Python auth handling.

import sys
import logging
from CoBrowser import Options, Api, AuthApp

if __name__ == "__main__":

	# Get the logger object

	log = logging.getLogger('extauth')
	fh = logging.FileHandler("/var/log/ejabberd/extauth.log")
	fh.setLevel(logging.DEBUG)
	formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
	fh.setFormatter(formatter)
	log.addHandler(fh)

	stderr = None
	log.setLevel(logging.INFO)

# Option parser
	opts = Options.Options()
	opts.parseArgs()
	
	if opts.getValue("debug"):
		sys.stderr = open('/var/log/ejabberd/extauth_err.log', 'a')
		log.setLevel(logging.DEBUG)

	log.info('extauth script started, waiting for ejabberd requests')

	# Run application
	app = AuthApp.AuthApp(opts.getConfig())

	# No need for daemonizing
	app.run()

	# Return exit status 0
	sys.exit(0)
