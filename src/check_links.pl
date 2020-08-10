#!/usr/bin/perl
# This file is part of check_links - Monitor web Resources
# Copyright (C) 2017 Martin Scharm <https://binfalse.de/contact/>
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use LWP::UserAgent;
use Getopt::Long;
use lib "/usr/lib/nagios/plugins/";
use utils qw($TIMEOUT %ERRORS);
use Data::Dumper;
use HTTP::Cookies;
use URI;

my $help = 0;
my @header = ();
my @cookies = ();
my $status = 200;
my $target = undef;
my $content = undef;
my $referer = "https://binfalse.de";
my $accept = "text/html";
my $userAgent = "binfalse.de link checker";
my $followRedirect = 0;
my $noStatusCheck = 0;

GetOptions ("status|s=i" => \$status,
						"header=s"   => \@header,
						"no-status=s"   => \$noStatusCheck,
						"cookie=s"   => \@cookies,
						"url|u=s"   => \$target,
						"content|c=s"  => \$content,
						"referer|r=s"  => \$referer,
						"accept|a=s"  => \$accept,
						"user-agent=s"  => \$userAgent,
						"timeout|t=i"  => \$TIMEOUT,
						"follow|f" => \$followRedirect,
            "help|h" => \$help)
    or help("Error in command line arguments\n");

sub help
{
    my $msg = shift;
		print STDERR "USAGE: $0 -t URL\n";
		print STDERR "\t--url|-u       \tthe URL to the site\n";
		print STDERR "\t--status|-s    \texpected HTTP status code\n";
		print STDERR "\t--no-status    \tdo not check the status\n";
		print STDERR "\t--content|-c   \texpected content within the response\n";
		print STDERR "\t--referer|-r   \treferer to be used when sending the request\n";
		print STDERR "\t--user-agent   \tpretend to be that user agent\n";
		print STDERR "\t--header       \texpected HTTP header value as KEY=VALUE (e.g. -h content-length=123) -- multiple options possible; value may be a regex\n";
		print STDERR "\t--cookie       \tsent a cookie NAME=VALUE (e.g. -c userid=karl) -- multiple options possible\n";
		print STDERR "\t--accept|-a    \tthe accept-header to be sent\n";
		print STDERR "\t--follow|-f    \tshould we follow redirects?\n";
		print STDERR "\t--timeout|-t   \tnumber of seconds to wait before timeout\n";
		print STDERR "\t--help|-h      \tshow this help\n\n";
		print STDERR "example: $0 -s 200 -f -c 'Martin Scharm' -r lesscomplex.org -a text/html --content-type text/html -u curl -h x-frame-options=DENY -h x-content-type-options=nosniff -c uid=abc123 -u binfalse.de \n\n";
    die ("$msg\n");
}


help ("") if $help;
help ("you need to specify a url site with -u") if !$target;



my $returnCode = $ERRORS{"OK"};
my $returnStr = "";
my $returnSupp = "";

sub max ($$) { $_[$_[0] < $_[1]] }

    my $ua = LWP::UserAgent->new;
    $ua->timeout ($TIMEOUT);
		
		$ua->agent ($userAgent);
		$ua->default_header ("Accept" => $accept) if $accept;
		$ua->default_header ("Referer", $referer) if $referer;
		$ua->max_redirect (10);
		$ua->max_redirect (0) if (!$followRedirect);
		
		if (@cookies)
		{
			my $cookies_jar = HTTP::Cookies->new();
			foreach my $cookie (@cookies)
			{
				my @c = split (/=/, $cookie);
				$cookies_jar->set_cookie ('', $c[0], $c[1], "/", URI->new($target)->host ());
			}
			$ua->cookie_jar ( $cookies_jar );
		}
		
    my $response = $ua->get ($target);
		# print Dumper($response);
		
		
		
		# do the checks
		
		# RESPONSE CODE
		if ($response->code != $status && !$noStatusCheck)
		{
			$returnCode = max $returnCode, $ERRORS{"CRITICAL"};
			$returnStr .= "status failed; ";
		}
		$returnSupp .= "status is " .$response->code . " (expected " .  $status . "); ";
		
		
		# CONTENT
		if ($content)
		{
			if (index ($response->decoded_content, $content) != -1)
			{
				$returnSupp .= "found expected content; ";
			}
			else
			{
				$returnStr .= "content check failed; ";
				$returnSupp .= "did not find '".$content."'; ";
				$returnCode = max $returnCode, $ERRORS{"WARNING"};
			}
		}
		
		# expected HEADER
		if (@header)
		{
			my $hok = 0;
			my $hfail = 0;
			foreach my $head (@header)
			{
				my @h = split (/=/, $head);
				my $v = $response->header ($h[0]);
				my $pattern = join '=', @h[1..$#h];
				
#  				print "check ". $h[0] . " == " . $pattern."\n";
#  				print $v."\n";
				
				if ($v =~ /$pattern/ or $v eq $pattern)
				{
					$hok++;
# 					print "same\n";
				}
				else
				{
					$returnSupp .= "header $head failed ('".$response->header ($h[0])."'); ";
					$hfail++;
				}
			}
			if ($hfail > 0)
			{
				$returnCode = max $returnCode, $ERRORS{"WARNING"};
			}
			$returnStr .= $hok . " of " . ($hok + $hfail) . " headers passed; ";
		}

$returnStr .= "all ok" if $returnCode == $ERRORS{"OK"};

# print $response->decoded_content . "\n";
print $returnStr . "|" . $returnSupp;
exit ($returnCode);


