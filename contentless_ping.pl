use Irssi;
use strict;
use vars qw($VERSION %IRSSI);

my $VERSION = "0.3";
%IRSSI = (
    authors => 'Tollef Fog Heen',
    contact => 'tfheen@err.no',
    name => 'contentless_ping',
    description => 'notifies people that contentless pings are annoying."',
    license => 'GPLv2',
    url => 'http://err.no/src/contentless_ping.pl',
    changed => 'Sun, 07 Jan 2007 11:39:46 +0100',
          );

Irssi::signal_add_last('message public', 'contentless_ping');

Irssi::print "contentless_ping $VERSION loaded";

my %rate = ();

sub contentless_ping {
     my ($server, $msg, $nick, $address, $channel) = @_;
     my %replacements = (nick => $nick,
                         channel => $channel,
                         server => $server,
                         address => $address,
                         msg => $msg,
                         own_nick => $server->{nick});
     my $keys = '(\$' . join('|\$', map quotemeta, keys %replacements) . ')';
     my $regexp = Irssi::settings_get_str('contentless_ping_regexp');
     $regexp =~ s/$keys/$replacements{substr($1,1)}/ge;
     if ($msg =~ m/$regexp/) {
	  if (! exists $rate{$nick} or $rate{$nick} < (time() - 300)) {
	       my $action = Irssi::settings_get_str('contentless_ping_action');
	       $action =~ s/$keys/$replacements{substr($1,1)}/ge;
	       $server->command($action);
	       $rate{$nick} = time();
	  } else {
	       Irssi::print "Not responding to $nick to avoid flood";
	  }
	  foreach my $key (keys %rate) {
	       delete $rate{$key} if $rate{$key} < time() - 300;
	  }
     }
}

Irssi::settings_add_str($IRSSI{'name'}, 'contentless_ping_regexp', 
     '$own_nick[,:] (ping|around|ayt|((are )?you )?there)[!?.]?$');
Irssi::settings_add_str($IRSSI{'name'}, 'contentless_ping_action', 
     'msg $channel $nick: You sent me a contentless ping.  This is a contentless pong.  Please provide a bit of information about what you want and I will respond when I am around.');
