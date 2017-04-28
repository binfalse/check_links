import subprocess
import sys


def max (a, b):
	if a < b:
		return b
	return a


def execute (cmd, expected_return, expected_response = ''):
	print (">> testing: " + ' '.join (cmd))
	print ("   expecting code " + str (expected_return) + " and response '" + expected_response + "'")
	p = subprocess.Popen(cmd, shell=False, stdout=subprocess.PIPE)
	p.wait ()
	response = p.stdout.read()
	returncode = p.returncode
	if returncode == expected_return and expected_response in response:
		print ("   success")
		return 0
	else:
		print ("   FAILED! code: " + str (returncode) + " response: " + response)
		return 1


ret = 0

okstr = "all ok"

ret = max (ret, execute (['./check_links.pl', '-u', 'http://scratch.binfalse.de/debug.php?a=b', '-f', '-c', '[a] => b'], 0, okstr))
ret = max (ret, execute (['./check_links.pl', '-u', 'http://scratch.binfalse.de/debug.php?a=c', '-f', '-c', '[a] => b'], 1, 'content check failed'))
ret = max (ret, execute (['./check_links.pl', '-u', 'http://scratch.binfalse.de/debug.php', '-s', '301', '-c', 'Moved Permanently'], 0, okstr))
ret = max (ret, execute (['./check_links.pl', '-u', 'http://scratch.binfalse.de/debug.php', '-s', '301', '-c', 'Moved Permanently2'], 1, 'content check failed'))
ret = max (ret, execute (['./check_links.pl', '-u', 'http://scratch.binfalse.de/debug.php', '-s', '500', '--no-status', '-c', 'Moved Permanently'], 0, okstr))
ret = max (ret, execute (['./check_links.pl', '-u', 'http://scratch.binfalse.de/debug.php', '-f', '-a', 'text/binfalse', '-c', 'HTTP_ACCEPT: text/binfalse'], 0, okstr))

# header checks
ret = max (ret, execute (['./check_links.pl', '-u', 'http://scratch.binfalse.de/debug.php', '-f', '-a', 'text/binfalse', '-c', 'HTTP_ACCEPT: text/binfalse', '--header', 'content-type=text/plain'], 0, okstr))
ret = max (ret, execute (['./check_links.pl', '-u', 'http://scratch.binfalse.de/debug.php', '-f', '-a', 'text/binfalse', '-c', 'HTTP_ACCEPT: text/binfalse', '--header', 'content-type=text/binfalse'], 1, '0 of 1 headers passed'))
ret = max (ret, execute (['./check_links.pl', '-u', 'http://scratch.binfalse.de/debug.php', '-s', '301', '--header', 'content-type=text/html'], 0, okstr))

ret = max (ret, execute (['./check_links.pl', '-u', 'http://binfalse.de/', '-f', '--header', 'content-type=text/html', '--header', 'x-frame-options=DENY'], 0, okstr))
ret = max (ret, execute (['./check_links.pl', '-u', 'http://binfalse.de/', '-s', '301', '--header', 'Location=https://binfalse.de.*'], 0, okstr))


# referer
ret = max (ret, execute (['./check_links.pl', '-u', 'http://scratch.binfalse.de/debug.php', '-f', '-r', 'binfalse-checker', '-c', 'HTTP_REFERER: binfalse-checker'], 0, okstr))

# user agent
ret = max (ret, execute (['./check_links.pl', '-u', 'http://scratch.binfalse.de/debug.php', '-f', '--user-agent', 'binfalse-checker', '-c', 'HTTP_USER_AGENT: binfalse-checker'], 0, okstr))


# content negotiation e.g. for ontologies
ret = max (ret, execute (['./check_links.pl', '-u', 'http://purl.uni-rostock.de/comodi/comodi#Attribution', '-f', '-a', 'text/xml', '--user-agent', 'binfalse-checker', '-c', '<owl:Class rdf:about="http://purl.uni-rostock.de/comodi/comodi#Attribution">', '--header', 'content-type=application/rdf\+xml'], 0, okstr))
ret = max (ret, execute (['./check_links.pl', '-u', 'http://purl.uni-rostock.de/comodi/comodi#Attribution', '-f', '-a', 'text/xml', '--user-agent', 'binfalse-checker', '-c', '<owl:Class rdf:about="http://purl.uni-rostock.de/comodi/comodi#Attribution">', '--header', 'content-type=xml'], 0, okstr))
ret = max (ret, execute (['./check_links.pl', '-u', 'http://purl.uni-rostock.de/comodi/comodi#Attribution', '-f', '-a', 'text/html', '--user-agent', 'binfalse-checker', '-c', '<a href="#Attribution"', '--header', 'content-type=text/html'], 0, okstr))
ret = max (ret, execute (['./check_links.pl', '-u', 'http://purl.uni-rostock.de/comodi/comodi#Attribution', '-f', '-a', 'text/html', '--user-agent', 'binfalse-checker', '-c', '<a href="#Attribution"', '--header', 'content-type=xml'], 1, "0 of 1 headers passed"))



sys.exit (ret)
