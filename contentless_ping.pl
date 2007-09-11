use Irssi;
use strict;
use vars qw($VERSION %IRSSI);

my $VERSION = "0.4";
%IRSSI = (
	authors => 'Tollef Fog Heen, modified by Chris Lamb',
	contact => 'tfheen@err.no, chris@chris-lamb.co.uk',
	name => 'contentless_ping',
	description => 'notifies people that contentless pings are annoying."',
	license => 'GPLv2',
	url => 'http://git.chris-lamb.co.uk/?p=contentless-ping.git',
	changed => 'Mon, 27 Aug 2007 16:49:38 +0100'
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

	my $num = Irssi::settings_get_int('contentless_ping_num');
	my $timeout = Irssi::settings_get_int('contentless_ping_timeout');

	while ($num > 0) {
		my $regexp = Irssi::settings_get_str('contentless_ping_regexp_' . $num);
		$regexp =~ s/$keys/$replacements{substr($1,1)}/ge;
		if ($msg =~ m/$regexp/) {
			if (! exists $rate{$nick} or $rate{$nick} < (time() - $timeout)) {
				# Sleep a bit
				my $sleep_min = Irssi::settings_get_int('contentless_ping_sleep_min');
				my $sleep_max = Irssi::settings_get_int('contentless_ping_sleep_max');
				my $sleep_time = int(rand($sleep_max - $sleep_min) + $sleep_min);
				Irssi::print "Sleeping for $sleep_time seconds before pinging $nick back";

				# Ping them back
				my $action = Irssi::settings_get_str('contentless_ping_action_' . $num);
				$action =~ s/$keys/$replacements{substr($1,1)}/ge;
				Irssi::timeout_add_once($sleep_time * 1000, sub { $server->command($action); }, undef);
				$rate{$nick} = time();
			} else {
				Irssi::print "Not responding to $nick to avoid flood";
			}
			foreach my $key (keys %rate) {
				delete $rate{$key} if $rate{$key} < time() - $timeout;
			}
		}
		$num--;
	 }
}

# You sent me a contentless ping. This is a contentless pong. Please provide a
# bit of information about what you want and I will respond when I am around.
Irssi::settings_add_int($IRSSI{'name'}, 'contentless_ping_timeout', 300);
Irssi::settings_add_int($IRSSI{'name'}, 'contentless_ping_sleep_min', 4);
Irssi::settings_add_int($IRSSI{'name'}, 'contentless_ping_sleep_max', 10);

Irssi::settings_add_int($IRSSI{'name'}, 'contentless_ping_num', 2);

Irssi::settings_add_str($IRSSI{'name'}, 'contentless_ping_regexp_1', '$own_nick[,:]\s+ping[\s!?.]*$');
Irssi::settings_add_str($IRSSI{'name'}, 'contentless_ping_action_1', 'msg $channel $nick: pong');

Irssi::settings_add_str($IRSSI{'name'}, 'contentless_ping_regexp_2', '$own_nick[,:]\s+(around|ayt|(are\s+)?you\s+there)[\s?.]*$');
Irssi::settings_add_str($IRSSI{'name'}, 'contentless_ping_action_2', 'msg $channel $nick: What\'s up?');
