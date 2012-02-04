#!/usr/bin/perl

use warnings;
use strict;
use DBI;
use CGI qw(:standard);
use CGI::Session qw/-ip-match/;
use File::Spec;

my $my_cnf = '/secret/my_cnf.cnf';

my $dbh = DBI->connect("DBI:mysql:"
    . ";mysql_read_default_file=$my_cnf"
    .';mysql_read_default_group=inventory',
    undef, 
    undef
   ) or die "something went wrong ($DBI::errstr)";

my $sth = $dbh->prepare('select hostname,owner,backup,support_notes,os from rwc');

$sth->execute();

my @categories = qw/hostname owner backup support_notes os/;
my %data;

while(my @results = $sth->fetchrow_array()){
		$data{$results[0]}{'owner'}=$results[1];
		$data{$results[0]}{'backup'}=$results[2];
		$data{$results[0]}{'support_notes'}=$results[3];
		$data{$results[0]}{'os'}=$results[4];
}



my $cgi = new CGI;

my $sid = $cgi->cookie("CGISESSID") || undef;
my $session = new CGI::Session(undef, $sid, {Directory=>File::Spec->tmpdir});
	
if($sid ne $session->id()){
	$session->delete();
	print $cgi->redirect(-location=>'index.pl?status=timeout');
	exit;
}

my $owner = $session->param('username');
chomp($owner);

print $cgi->header,$cgi->start_html;
print $cgi->h1("the server orphanage");

print "<form action='modifytable.pl' method=post>\n";
print "<input type=submit value='Submit changes'> as checked below\n";


print $cgi->h3("these are systems I own");
print "<table>\n";
print "check to release ownership\n";
print "<tr><th></th><th>hostname</th><th>backup</th><th>support_notes</th><td>os</td></tr>\n";
foreach my $key (keys %data){
	if($data{$key}{'owner'} eq $owner){
		print "<tr><td><input type='checkbox' name='unclaim' value=$key></td><td>$key</td><td>$data{$key}{'backup'}</td><td>$data{$key}{'support_notes'}</td><td>$data{$key}{'os'}</td></tr>\n";
	}
}
print "</table>\n";

print "<hr>\n";

print $cgi->h3("these are systems with no owner");
print "check to claim ownership\n";
print "<table>\n";
print "<tr><th></th><th>hostname</th></tr>\n";
foreach my $key (sort keys %data){
	if($data{$key}{'owner'} eq ''){
		print "<tr><td><input type='checkbox' name='claim' value=$key></td><td>$key</td></tr>\n";
	}
}
print "</table>\n";


print "<hr>\n";

print $cgi->h3("these are systems with at least one owner");
print "check to add yourself as co-owner\n";
print "<table>\n";
print "<tr><th></th><th>hostname</th><th>owner(s)</th></tr>\n";
foreach my $key (sort keys %data){
	if($data{$key}{'owner'} ne '' && $data{$key}{'owner'} ne $owner){
		print "<tr><td><input type='checkbox' name='other' value=$key></td><td>$key</td><td>$data{$key}{'owner'}</td></tr>\n";
	}
}
print "</table>\n";


print "</form>\n";


print $cgi->end_html;
