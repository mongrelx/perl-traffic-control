package PTC::NetUtils;


require 5.000;
use Exporter;
use Carp;


@ISA = qw(Exporter);
@EXPORT = qw(addBlackListItem addBlackListDB loadBlackList loadBlackListDB closeBlackListItem closeBlackListDB REASONS setBlackListDBReadTime RemoveIPTablesRedirectFromApache);

@REASONS=qw(SPAM WORM ABUSE COPYRIGHT MESSAGE LOCKED);




sub loadBlackListDB
{
    my $mac=shift;;
    chomp($mac);
    $mac=lc($mac);
    my %BlackList;

    my $sth;
    if ($mac=~/^all/)
    {
        print "Loading whole blacklist\n";
        $sth = $main::dbh_hpna->prepare("SELECT Username,Groupname FROM usergroup;");
    }
    else
    {
        $sth = $main::dbh_hpna->prepare("SELECT Username,Groupname FROM usergroup WHERE UserName = '$mac';");
    }
    $sth->execute();
    my @row;
    while ( @row = $sth->fetchrow_array ) {
        $BlackList{$row[0]}{'usergroup'}=$row[1];
        my $sth2 = $main::dbh_ptc->prepare("SELECT * FROM blacklist WHERE username = '$row[0]' AND StopTime='0000-00-00 00:00:00';");
        $sth2->execute();
        while ( @row2 = $sth2->fetchrow_array ) {
            $BlackList{$row[0]}{'reason'}=$row2[2];
            $BlackList{$row[0]}{'notes'}=$row2[3];
            $BlackList{$row[0]}{'point'}=$row2[4];
            $BlackList{$row[0]}{'starttime'}=$row2[5];
            $BlackList{$row[0]}{'stoptime'}=$row2[6];
            $BlackList{$row[0]}{'created'}=$row2[7];
            $BlackList{$row[0]}{'region'}=$row2[8];
            $BlackList{$row[0]}{'readtime'}=$row2[9];
        }
    }
    return \%BlackList;
}


sub closeBlackListDB
{
    my ($mac,$reason,$starttime,$point)=@_;
    $mac=lc($mac);
    chomp($mac);
    my $sth = $main::dbh_hpna->do("DELETE FROM usergroup WHERE UserName = '$mac' AND GroupName='BLACKLIST_$reason';");
    my $sth2 = $main::dbh_ptc->do("UPDATE blacklist SET point='$point',ReadTime=NOW(),StopTime=NOW() WHERE username = '$mac' AND reason='$reason' AND StartTime='$starttime';");
    
}

sub setBlackListDBReadTime
{
    my ($mac,$reason,$starttime,$point)=@_;
    $mac=lc($mac);
    chomp($mac);
    my $sth2 = $main::dbh_ptc->do("UPDATE blacklist SET point='$point',ReadTime=NOW() WHERE username = '$mac' AND StopTime='0000-00-00 00:00:00';");
    
}

sub checkDB
{
    my $mac=shift;
    my $found=0;
    my $sth = $main::dbh_hpna->prepare("SELECT UserName,GroupName FROM usergroup WHERE UserName = '$mac';");
    $sth->execute();
    my @row;

    while ( @row = $sth->fetchrow_array ) {
        $found++;
    }

    return $found;
}




sub addBlackListDB
{
    my ($mac,$reason,$notes,$region,$clientid)=@_;
    $mac=lc($mac);
    if ($mac !~m#(..\:..\:..\:..\:..\:..)#)
    {
        my $error_str="Laitteisto-osoite ei kelpaa : $mac";
        return \$error_str;
    }
    else
    {
        
        if (&checkDB($mac))
        {
            my $error_str="On jo sulkulistalla : $mac";
            return \$error_str;
        }
        else
        {
            $main::dbh_ptc->do("INSERT INTO blacklist VALUES (NULL,'$mac','$reason','$notes',NULL,NOW(),'0000-00-00 00:00:00','InfoScreen','$region','$clientid','0000-00-00 00:00:00')");
            $reason="BLACKLIST_".uc($reason);
            $main::dbh_hpna->do("INSERT INTO usergroup VALUES (NULL,'$mac','$reason')");
            return 1;
        }
        #        $main::dbh_hpna->do("INSERT INTO radreply VALUES (NULL,'$mac','Reply-Message','$clientid/$username/$main::region','$clientid','==')");
    }
}


sub addBlackListItem
{
    my $mac=shift;
    my $reason=shift;
    my $toHost=shift;
    my $notes=shift;
    chomp($reason);
    my $ref=loadBlackList();
    my %BlackList=%$ref;

    if (exists $BlackList{uc($mac)})
    {
        return -1;
    }
    if ($mac!~m#..:..:..:..:..:..#)
    {
        return -1;
    }
    if ($reason!~m#(SPAM|WORM|ABUSE|COPYRIGHT|MESSAGE|LOCKED)#)
    {
        return -1;
    }
    
    `iptables -t nat -A BLACKLIST -j DNAT -m mac --mac-source $mac -p tcp --dport 80 --to $toHost `;
    `iptables -t nat -A BLACKLIST -j DNAT -m mac --mac-source $mac -p tcp --dport 3128 --to $toHost `;
    `iptables -I VIRUS -m mac --mac-source $mac -j $reason`;

    return 1;
}



sub closeBlackListItem
{
    my $ref=loadBlackList();
    my %BlackList=%$ref;
    my $mac=shift;

    if (!exists $BlackList{uc($mac)})
    {
        DELETE_END:
            print "MAC $mac ei ole suljettu\n";
            exit;
    }
    else
    {
        my %mail;
        goto DELETE_END if ($mac!~m#..:..:..:..:..:..#);

        my $line=$BlackList{uc($mac)}{'nat'};
        `iptables -t nat -D BLACKLIST $line`;
        $ref=loadBlackList();
        %BlackList=%$ref;
        print $BlackList{uc($mac)}{'squid'};
        if ($BlackList{uc($mac)}{'squid'})
        {
            $line=$BlackList{uc($mac)}{'squid'};
            `iptables -t nat -D BLACKLIST $line`;
        }
        $line=$BlackList{uc($mac)}{'VIRUS'};
        `iptables -D VIRUS $line`;
        print "MAC $mac poistettu\n";
    }
}


sub loadBlackList
{
    my $action=shift;
    my %BlackList=();
    my @row=`iptables -L BLACKLIST -t nat --line-numbers -n -v`;
    @history=();
    foreach (@row) {
        if ($_=~m#^(\d+)\s+.*MAC\s+(.*)\s+tcp\s+dpt:80#)
        {
            print "nat-$1-$2\n";
            $BlackList{$2}{'nat'}=$1;
        }
        if ($_=~m#^(\d+)\s+.*MAC\s+(.*)\s+tcp\s+dpt:3128#)
        {
            print "squid-$1-$2\n";
            $BlackList{$2}{'squid'}=$1;
        }

    }

    foreach (sort {$BlackList{$a}{'nat'} <=> $BlackList{$b}{'nat'} } keys %BlackList)
    {
        my @row2=`iptables -L VIRUS --line-numbers -n -v`;
        foreach (@row2) {
            chomp();
            if ($_=~m#^(\d+).*(COPYRIGHT|SPAM|ABUSE|WORM|MESSAGE|LOCKED)\s+all.*MAC\s+(.*)\s+#)
            {
                # print "-$1-$2-$3-\n";
                $BlackList{$3}{'VIRUS'}=$1;
                $BlackList{$3}{'REASON'}=$2;
            }
        }
    }


    return \%BlackList;
}



return 1;
