#!/usr/bin/perl -w
#
# see http://search.cpan.org/~atrak/NetPacket-0.04/

use strict;

BEGIN {
	push @INC,"perl";
	push @INC,"build/perl";
	push @INC,"NetPacket-0.04";
};

use nfqueue;

use NetPacket::IP qw(IP_PROTO_TCP);
use NetPacket::TCP;
use Socket qw(AF_INET AF_INET6);

my $q;

sub cleanup()
{
	print "unbind\n";
	$q->unbind(AF_INET);
	print "close\n";
	$q->close();
}

sub cb()
{
	my ($dummy,$payload) = @_;
	print "Perl callback called!\n";
	print "dummy is $dummy\n" if $dummy;
	if ($payload) {
		print "len: " . $payload->get_length() . "\n";

		my $ip_obj = NetPacket::IP->decode($payload->get_data());
		print $ip_obj, "\n";
		print("$ip_obj->{src_ip} => $ip_obj->{dest_ip} $ip_obj->{proto}\n");
		print "Id: " . $payload->swig_id_get() . "\n";

		if($ip_obj->{proto} == IP_PROTO_TCP) {
			# decode the TCP header
			my $tcp_obj = NetPacket::TCP->decode($ip_obj->{data});

			print "TCP src_port: $tcp_obj->{src_port}\n";
			print "TCP dst_port: $tcp_obj->{dest_port}\n";
		}

		$payload->set_verdict($nfqueue::NF_DROP);
	}
}


$q = new nfqueue::queue();

print "open\n";
$q->open();
print "bind\n";
$q->bind(AF_INET);

$SIG{INT} = "cleanup";

#print "set callback, wrong argument type (should fail)\n";
#$q->set_callback("blah");

print "setting callback\n";
$q->set_callback(\&cb);

print "creating queue\n";
$q->create_queue(0);

$q->set_queue_maxlen(5000);

print "trying to run\n";
$q->try_run();


