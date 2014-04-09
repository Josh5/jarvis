#!/usr/bin/perl
#
# Nested Dataset unit tests against demo app database.
#
use strict;
use warnings;

package TestUtils;

use LWP::UserAgent;
use HTTP::Cookies;
use Data::Dumper;
use JSON qw(encode_json decode_json);
use URI::Encode qw(uri_encode uri_decode);

# Jarvis base URL.
my $base_url = "http://localhost/jarvis-agent/demo";
my %passwords = ("admin" => "admin", "guest" => "guest");

# This user agent will perform all our tests.
my $ua = LWP::UserAgent->new;
$ua->cookie_jar (HTTP::Cookies->new (file => "cookies.txt", autosave => 1));

################################################################################
# Perform a logout as part of a test.
#
# Params:
#		<None>
#
# Returns:
#       Returned $json (die on error)
################################################################################
#
sub logout {

	# Request is a simple GET.
 	my $req = HTTP::Request->new (GET => "$base_url/__logout");

 	# Check request succeeded, and result is interpretable as JSON.
 	my $res = $ua->request ($req);
 	($res->is_success) || die "Failed: __logout: " . $res->status_line;
 	($res->header ('Content-Type') =~ m|^text/plain|) || die "Wrong Content-Type: " . $res->header ('Content-Type');
 	my $json = decode_json ($res->content ());

 	# Check this looks like a valid response.
 	(defined $json->{logged_in}) || die "Missing 'logged_in' in response: " . &Dumper ($json);

 	return $json;
}

################################################################################
# Perform a login as part of a test.
#
# Params:
#		$username - Must a be a known username.  We will supply the password.
#
# Returns:
#       Returned $json (die on error)
################################################################################
#
sub login {
	my ($username) = @_;

	# Username and password are sent.
	my $password = $passwords{$username} || die "Unknown user: $username";
	my %query_args = (username => $username, password => $password);
	my $urlencoded_form = join ('&', map { uri_encode ($_) . '=' . uri_encode ($query_args{$_}) } (keys %query_args));

	# Request is a POST with user/pass.
 	my $req = HTTP::Request->new (POST => "$base_url/__status");
    $req->content_type ('application/x-www-form-urlencoded');
    $req->content ($urlencoded_form); 	

 	# Check request succeeded, and result is interpretable as JSON.
 	my $res = $ua->request ($req);
 	($res->is_success) || die "Failed: __status: " . $res->status_line;
 	($res->header ('Content-Type') =~ m|^text/plain|) || die "Wrong Content-Type: " . $res->header ('Content-Type');
 	my $json = decode_json ($res->content ());

 	# Check this looks like a valid response.
 	(defined $json->{logged_in}) || die "Missing 'logged_in' in response: " . &Dumper ($json);

 	return $json;
}

################################################################################
# Perform a fetch, with specified args.  Assumes we are logged in already.
#
# Params:
#		$url_parts - Array of URL parts, dataset plus any restful args.  We will encode.
#		$query_args - Hash of CGI args.
#
# Returns:
#       Returned $json (die on error)
################################################################################
#
sub fetch {
	my ($url_parts, $query_args) = @_;

	# Query args are sent to a restful url.
	my $restful_url = join ('/', map { uri_encode ($_) } @$url_parts);
	my $urlencoded_args = join ('&', map { uri_encode ($_) . '=' . uri_encode ($query_args->{$_}) } (keys %$query_args));

	# Request is a GET with query args in the URL.
 	my $req = HTTP::Request->new (GET => "$base_url/$restful_url?$urlencoded_args");

  	# Check request succeeded, and result is interpretable as JSON.
	my $res = $ua->request ($req);
 	($res->is_success) || die "Failed: __status: " . $res->status_line;
 	($res->header ('Content-Type') =~ m|^text/plain|) || die "Wrong Content-Type: " . $res->header ('Content-Type');
 	my $json = decode_json ($res->content ());

 	# Check this looks like a valid response.
 	(defined $json->{logged_in}) || die "Missing 'logged_in' in response: " . &Dumper ($json);

 	return $json;
}

################################################################################
# Perform a store, with specified args and content.  Assumes we are logged in already.
#
# Params:
#		$url_parts - Array of URL parts, dataset plus any restful args.  We will encode.
#		$query_args - Hash of CGI args.
#		$rows - Array of rows to modify.
#
# Returns:
#       Returned $json (die on error)
################################################################################
#
sub store {
	my ($url_parts, $query_args, $rows) = @_;

	# Query args are sent to a restful url.
	my $restful_url = join ('/', map { uri_encode ($_) } @$url_parts);
	my $urlencoded_args = join ('&', map { uri_encode ($_) . '=' . uri_encode ($query_args->{$_}) } (keys %$query_args));
	my $rows_json = encode_json ($rows);

	# Request is a POST with query args in the URL and a content.
 	my $req = HTTP::Request->new (POST => "$base_url/$restful_url?$urlencoded_args");
    $req->content_type ('application/json');
    $req->content ($rows_json); 	

  	# Check request succeeded, and result is interpretable as JSON.
	my $res = $ua->request ($req);
 	($res->is_success) || die "Failed: __status: " . $res->status_line;
 	($res->header ('Content-Type') =~ m|^text/plain|) || die "Wrong Content-Type: " . $res->header ('Content-Type');
 	my $json = decode_json ($res->content ());

 	# Check this looks like a valid response.
 	(defined $json->{success}) || die "Missing 'success' in response: " . &Dumper ($json);

 	return $json;
}

1;