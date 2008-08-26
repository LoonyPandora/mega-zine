#!/usr/bin/perl -wT

###############################################################################
# cron.pl
# =============================================================================
#
# Version:    1.0
# Released:   22nd August 2008
#
# Copyright (C) 2008 James Aitken <http://www.loonypandora.com>
#
# This is designed to be run by cron, to check the RSS feed during the day
# It will produce no output to a browser.
###############################################################################

#use CGI::Carp qw(fatalsToBrowser);
#print "Content-Type: text/html\n\n";

use Time::Local;
use LWP::Simple qw(get $ua);
use XML::Simple;

$ua->agent("Vegetable Revolution RSS Reader/1.0 (+http://www.vegetablerevolution.com)");

my $yMessages = "/home/u3437100/public_html/yabb/Messages";
my $yBoards		= "/home/u3437100/public_html/yabb/Boards";
my $yVars			= "/home/u3437100/public_html/yabb/Variables";
my $feedDir		= "/home/u3437100/public_html/mega-zine/feeds";

my @months 				= ('January','February','March','April','May','June','July','August','September','October','November','December');
my @short_months	= ('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec');
my @days					= ('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday');
my @page_numbers		= ('Page One','Page Two','Page Three','Page Four','Page Five');

my $remote_feed = "http://feeds.teletext.co.uk/entertainment/mega-zine?format=xml";


#---- End of Settings ---------------------------------------------------------


&processFeed;


#------------------------------------------------------------------------------
# Gets the feed using LWP::Simple, and parses it using XML::Simple
#------------------------------------------------------------------------------
sub processFeed {
	my $raw_feed = get("$remote_feed");	

	my $xs = XML::Simple->new();
	my $feed = $xs->XMLin($raw_feed);

	our $lastBuildDate = &stringtotime($feed->{channel}->{lastBuildDate});

	our (undef, undef, undef, $buildDay, $buildMonth, $buildYear, $buildWDay, undef, undef) = gmtime($lastBuildDate);
	$buildDay				= sprintf("%.2d", $buildDay);
	$buildMonthIdx	= sprintf("%.2d", $buildMonth);
	$buildMonth			= sprintf("%.2d", $buildMonth +1);
	$buildYear			= $buildYear + 1900;
	our $ordinalDay = &ordinal($buildDay);
		
	our @yabb_post 		= ();
	our @feed_store		= ();
	our $yabb_board 	= "$lastBuildDate|$days[$buildWDay], the $ordinalDay of $months[$buildMonthIdx], $buildYear|Megazine Letters|megazinestats\@yahoo.com|$lastBuildDate|4|megazineletters|xx|0\n";
	our $yabb_ctb			= qq~### ThreadID: $lastBuildDate, LastModified: $feed->{channel}->{lastBuildDate} ###\n\n'board',"megazine-letters"\n'replies',"4"\n'views',"0"\n'lastposter',"megazineletters"\n'lastpostdate',"$lastBuildDate"\n'threadstatus',"0"\n~;
	our $yabb_recent	= qq~$lastBuildDate	$lastBuildDate|$days[$buildWDay], the $ordinalDay of $months[$buildMonthIdx], $buildYear\n~;
	
	$z = 0; # Counter is for the forum post page numbering
	foreach my $entry (@{$feed->{channel}->{item}}) {
		if ($entry->{'t:full_article'} =~ /07624 809881/i) { next; } # Skip if is the advert
		
		$entry->{'t:full_article'} =~ /<i>(.+?)<\/i>/sig;		my $zine_name = $1;
		$entry->{'t:full_article'} =~ /<b>(.+?)<\/b>/sig;		my $wlw_reply = $1;

		# Wrap and change to BBCode, clean up br tags, and remove all newlines.
		my $yTitle = qq~\[color=#0000ff\]$entry->{'title'}\[/color\]<br /><br />~;
		my $yPageNum = qq~\[color=#993366\]$page_numbers[$z]\[/color\]<br /><br />~;
		
		$entry->{'t:full_article'} =~ s/<b>/\[color=#0000ff\]\[b\]/sig;
		$entry->{'t:full_article'} =~ s/<i>/\[color=#ff0000\]\[i\]/sig;
		$entry->{'t:full_article'} =~ s/<\/i>/\[\/i\]\[\/color\]/sig;
		$entry->{'t:full_article'} =~ s/<\/b>/\[\/b\]\[\/color\]/sig;
		$entry->{'t:full_article'} =~ s/<br\/>/<br \/>/sig;
		$entry->{'t:full_article'} =~ s/\n|\r|\r\n//sig;

		# Change any HTML Entities back to their real values. Only pipes are escaped.
		$entry->{'t:full_article'} =~ s/&#39;/'/sig;
		$entry->{'t:full_article'} =~ s/\|/\\\|/sig;

		push(@feed_store, "$buildYear-$buildMonth-$buildDay|$lastBuildDate|$entry->{'uid'}|$entry->{'title'}|$zine_name|$wlw_reply|$entry->{'t:full_article'}\n");
		push(@yabb_post,  "$days[$buildWDay], the $ordinalDay of $months[$buildMonthIdx], $buildYear|Megazine Letters|megazinestats\@yahoo.com|$lastBuildDate|megazineletters|xx|0|127.0.0.3|$yPageNum$yTitle$entry->{'t:full_article'}||||\n");

		$z++;
	}
	
	if (!-e "$feedDir/$buildYear-$buildMonth-$buildDay.zine") {
		&writeFiles;
	}
}


#------------------------------------------------------------------------------
# Writes the cache files, AND the forum posts for VR
#------------------------------------------------------------------------------
sub writeFiles {
	open(FEED, ">$feedDir/$buildYear-$buildMonth-$buildDay.zine") or die "Cannot open file, $!";
		print FEED @feed_store;
	close(FEED);

	open(MESSAGE, ">$yMessages/$lastBuildDate.txt") or die "Cannot open file, $!";
		print MESSAGE @yabb_post;
	close(MESSAGE);

	open(CTB, ">$yMessages/$lastBuildDate.ctb") or die "Cannot open file, $!";
		print CTB $yabb_ctb;
	close(CTB);

	open(BOARD, "+<$yBoards/megazine-letters.txt") or die "Cannot open file, $!";
		seek BOARD, 0, 0;
		my @threadlist = <BOARD>;
		truncate BOARD, 0;
		seek BOARD, 0, 0;
		print BOARD $yabb_board;
		print BOARD @threadlist;
	close(BOARD);
	
	open(RECENT, "+<$yVars/recent.cache") or die "Cannot open file, $!";
		seek RECENT, 0, 0;
		my @recentlist = <RECENT>;
		truncate RECENT, 0;
		seek RECENT, 0, 0;
		print RECENT $yabb_recent;
		print RECENT @recentlist;
	close(RECENT);

	open(TOTAL, "+<$yBoards/forum.totals") or die "Cannot open file, $!";
		seek TOTAL, 0, 0;
		my @totals = <TOTAL>;

		for ($i = 0; $i < @totals; $i++) {
			@line_items = split(/\|/, $totals[$i]);
			if ($line_items[0] eq "megazine-letters") {
				my $topics 	= $line_items[1] +1;
				my $threads	= $line_items[2] +4;
				$totals[$i] = "megazine-letters|$topics|$threads|$lastBuildDate|megazineletters|$lastBuildDate|4|$days[$buildWDay], the $ordinalDay of $months[$buildMonthIdx], $buildYear|xx|0|\n";
				last;
			}
		}

		truncate TOTAL, 0;
		seek TOTAL, 0, 0;
		print TOTAL @totals;
	close(TOTAL);
}


#------------------------------------------------------------------------------
# Converts RSS formatted time to a unix timestamp
#------------------------------------------------------------------------------
sub stringtotime {
	my ($word_day, $mantissa) = split(m~,\ ~, $_[0]);
	my ($num_mday, $word_month, $num_year, $word_time, undef) = split(m~\ ~, $mantissa);
	my ($num_hour, $num_min, $num_sec) = split(m~:~, $word_time);

	my $i = 0;
	foreach my $month (@short_months) {
		if ($short_months[$i] eq "$word_month") {
			my $num_month = $i;
			return (timegm($num_sec, $num_min, $num_hour, $num_mday, $num_month, $num_year));
    }
		$i++;
	}

}


#------------------------------------------------------------------------------
# Gives you the correct ordinal ('1st' '4th' etc) for any number
#------------------------------------------------------------------------------
sub ordinal {
		$_[0] =~ /^(?:\d+|\d[,\d]+\d+)$/ or return $_[0];
		return "$_[0]nd" if $_[0] =~ /(?<!1)2$/;
		return "$_[0]rd" if $_[0] =~ /(?<!1)3$/;
		return "$_[0]st" if $_[0] =~ /(?<!1)1$/;
		return "$_[0]th";
}


1;