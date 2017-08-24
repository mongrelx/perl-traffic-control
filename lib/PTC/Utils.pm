package PTC::Utils;


require 5.000;
use Exporter;
use Carp;
use strict;
use DBI;
my $dbhost_default="localhost";
my $db_table="ptc";
my $db_user="ptc_user";
my $db_pass="ptc_pass";
use vars qw(@ISA @EXPORT $VERSION );
@ISA = qw(Exporter);
@EXPORT = qw(checkDHCPD checkConntrack loadInterfaces sortHashValue  isInSubnet round printDebug getCurrentLoad loadList loadServerList Tpassword Tvalue error loadConfig getVersion setQoSDevice loadCoreSwitchList loadRegionInfo);


sub loadRegionInfo($$)
{
    my $regionValue=shift;
    my $dbhost=shift || $dbhost_default;
    my $dbh_ptc= DBI->connect("DBI:mysql:$db_table:$dbhost", $db_user, $db_pass);
    my $sth_ptc= $dbh_ptc->prepare("SELECT Attribute,Value FROM routerConfig WHERE router='".$regionValue."'");
    $sth_ptc->execute;
    while ( my @row = $sth_ptc->fetchrow_array ) {
        my $name=$row[0];
        #$$name=$row[1];
        #print "!$row[0]=$row[1]!\n";
        if ($row[0] eq "DSLAM")
        {
            my @dcfg=split(/:/,$row[1]);
            $main::dslam{$dcfg[0]}{ip}=$dcfg[0];
            $main::dslam{$dcfg[0]}{cs}=$dcfg[1];
            $main::dslam{$dcfg[0]}{user}=$dcfg[2];
            $main::dslam{$dcfg[0]}{pass}=$dcfg[3];
            $main::dslam{$dcfg[0]}{type}=$dcfg[4];
        }
        if ($row[0] eq "SWITCH")
        {
            my @dcfg=split(/:/,$row[1]);
            $main::switch{$dcfg[0]}{ip}=$dcfg[0];
            $main::switch{$dcfg[0]}{cs}=$dcfg[1];
            $main::switch{$dcfg[0]}{user}=$dcfg[2];
            $main::switch{$dcfg[0]}{pass}=$dcfg[3];
            $main::switch{$dcfg[0]}{type}=$dcfg[4];
        }

        if ($row[0] eq "CORESWITCH")
        {
            #            print "!$row[0]=$row[1]!\n" if ($debug > 0);;
            my @dcfg=split(/:/,$row[1]);
            $main::cs{$dcfg[0]}{ip}=$dcfg[1];
            $main::cs{$dcfg[0]}{cs}=$dcfg[0];
            $main::cs{$dcfg[0]}{user}=$dcfg[2];
            $main::cs{$dcfg[0]}{pass}=$dcfg[3];
            $main::cs{$dcfg[0]}{type}=$dcfg[4];
        }
    }
    $dbh_ptc->disconnect();
}

sub checkDHCPD
{
    print "Checking DHCP server status \n" if ($main::debug > 0 );

    print "Checking leases " if ($main::debug > 0 );

    my @noleases=`tail -n 1000 /var/log/messages | grep "no free"`;
    if (scalar(@noleases) > 0)
    {
        print "\tNO FREE LEASES MESSAGES : ".$noleases[0]."\n";
    }
    else
    {
        print "\tOK\n" if ($main::debug > 0 );
    }
}

sub checkConntrack
{
    my $printSummary=shift;
    print "Checking connection tracking $main::version \n" if ($main::debug > 0 );
    my @messages=`tail -n 1000 /var/log/messages | grep conntrack`;
    my $i=0;
    foreach (@messages)
    {
        if (/buckets/)
        {
            if ($i eq 0)
            {
            }
            else
            {
                print "count was ".$i." before reloading\n";
                $i=0;
            }
        }
        elsif (/dropping/)
        {
            $i++;
        }
    }
    my @tmp=();
    my @count=();
    if ( ($main::version eq "fc3") || ($main::version eq "fc4") || ($main::version eq "fc5"))
    {
        @tmp=split(' = ',`sysctl net.ipv4.netfilter.ip_conntrack_max`);
        @count=split(' = ',`sysctl net.ipv4.netfilter.ip_conntrack_count`);
    }
    elsif (($main::version eq "fc6") || ($main::version =~/^centos/))
    {
        @tmp=split(' = ',`sysctl net.ipv4.netfilter.ip_conntrack_max`);
        @count=split(' = ',`sysctl net.ipv4.netfilter.ip_conntrack_count`);
        #@tmp=split(' = ',`sysctl net.netfilter.nf_conntrack_max`);
    }
    else
    {
        @tmp=split(' = ',`sysctl net.ipv4.ip_conntrack_max`);
        @count=split(' = ',`sysctl net.ipv4.ip_conntrack_count`);
    }
    
    my $max_conntrack=$tmp[1];
    my $count_conntrack=$count[1];

    if ($main::version eq "fc6")
    {
        #@tmp=split(' = ',`sysctl net.netfilter.nf_conntrack_tcp_timeout_established`);
        @tmp=split(' = ',`sysctl net.ipv4.netfilter.ip_conntrack_tcp_timeout_established`);
    }
    else
    {
        @tmp=split(' = ',`sysctl net.ipv4.netfilter.ip_conntrack_tcp_timeout_established`);
    }


    my $established_timeout=$tmp[1];


    if ($i ne 0)
    {
        if ($max_conntrack >= 2097156)
        {
            print "Clearing ip_conntrack table \n";
            `cp /etc/sysconfig/iptables /root/iptables.backup`;
            `/etc/init.d/iptables save`;
            `/etc/init.d/iptables stop`;
            `rmmod ipt_state`;
            `rmmod iptable_nat`;
            `rmmod ip_conntrack`;

            `/etc/init.d/iptables start`;
            print `iptables -L -v -n`;
        } 
        else
        {
            $max_conntrack=$max_conntrack+65536;
            if ($established_timeout > 80000)
            {
                $established_timeout=$established_timeout-50000;
            }
            if ($main::version eq "fc5")
            {
                `sysctl -w net.ipv4.netfilter.ip_conntrack_max=$max_conntrack`;
                `sysctl -w net.ipv4.netfilter.ip_conntrack_tcp_timeout_established=$established_timeout`;
            }
            elsif ($main::version eq "fc6")
            {
                `sysctl -w net.ipv4.netfilter.ip_conntrack_max=$max_conntrack`;
                #`sysctl -w net.netfilter.nf_conntrack_max=$max_conntrack`;
                #`sysctl -w net.netfilter.nf_conntrack_tcp_timeout_established=$established_timeout`;
                `sysctl -w net.ipv4.netfilter.ip_conntrack_tcp_timeout_established=$established_timeout`;
            }
            else
            {
                `sysctl -w net.ipv4.ip_conntrack_max=$max_conntrack`;
                `sysctl -w net.ipv4.netfilter.ip_conntrack_tcp_timeout_established=$established_timeout`;
            }

            print "Adding more connections to connection trackking " => $max_conntrack."\n";
            print "Removing time from established  " => $established_timeout."\n";
        }
    }
    else
    {
        print "<TD>$count_conntrack / $max_conntrack</TD>" if ($printSummary);
        print "\tOK\n" if ($main::debug > 0);
    }
}

sub setQoSDevice
{
    foreach my $network (keys %Options::network)
    {
        $main::QoSDevice{$Options::network{$network}}{in}=1;
        print "$Options::network{$network} is networks $network in_device\n" if ($main::debug > 4);
        if ($main::nat)
            {
                    $main::QoSDevice{$main::nat_device}{'out'}='1';
                    #print "Setting ". $main::nat_device." as output\n";
            }
            else
            {
        if ($Options::out_device{$network} =~m/\[(.*),(.*)/)
        {
            
            my $deviceList=$Options::out_device{$network};
            $deviceList=~s#^\[##;
            $deviceList=~s#\]##;
            my @devices = split (/,/,$deviceList);
            foreach (@devices)
            {
                print "$_ is networks $network out_device\n" if ($main::debug > 4);
                $main::QoSDevice{$_}{'out'}='1';
            }
            
        }
        else
        {
            print "$Options::out_device{$network} is networks $network out_device\n" if ($main::debug > 4);
            #        $main::QoSDevice{$Options::out_device{$network}}++;
            $main::QoSDevice{$Options::out_device{$network}}{'out'}='1';
        }}
    }
}


sub convert_ip {
    my $ip1=shift;
    my $long;
    # take an ip in form x.x.x.x and convert to a hex value
    my @woo=split(/\./,$ip1);
    $long=$woo[3] | ($woo[2] << 8 ) | ($woo[1] << 16 ) | ($woo[0]<<24);
    return $long;
}


sub isInSubnet {
    my($net,$ip)=@_;
    if ($net=~m#(\d+.\.\d+\.\d+\.\d+)/(\d+)#)
    {
        my $bits=$2;
        my $subnetAddr=convert_ip($1);
        $ip=convert_ip($ip);
        
        #print $bits."\n";
        #print $subnetAddr."\n";
        my $subnet = $subnetAddr & (0xffffffff ) ;#<< (32 - $bits) );
        #print $subnet."\n";
        my $address = $ip & (0xffffffff << (32- $bits) );
        #print $address."\n";
        if ($subnet  == $address )
        {
            return 1;
        }
        else
        {
            return 0;
        }
    }
    else
    {
        print "not valid subnet $net\n";
    }
}

sub printDebug
{
    my ($level,$type,$msg) =@_;
    {
        if (defined $main::debug)
        {
            if ($main::debug >= $level)
            {
                print time.":".$level.":".$type.":".$msg."\n";
            }
        }
    }
        
}

sub printDebugOld
{
    my ($msg,$level) =@_;
    {
        if ($main::debug >= $level)
        {
            print time.":".$level.":".$msg."\n";
        }
    }
        
}


sub getCurrentLoad
{
    ## Get the load average
    open(FILE, "/proc/loadavg");
    my $input = <FILE>;
    close FILE;

    ## Extract the value we need (take the average of all 3 system load values)
    my $load = sprintf("%.02f", (( (split(/\s+/, $input))[0] + (split(/\s+/, $input))[1] + (split(/\s+/, $input))[2]) / 3));
    return $load;
}


sub loadInterfaces
{
    my $node=shift;
    my $dbhost=$dbhost_default;
    my $dbh = DBI->connect("dbi:Pg:dbname=opennms;host=$dbhost", "opennms", "opennms");
    my $sth;
    if (defined $node)
    {
        $sth= $dbh->prepare("SELECT n.nodeid,n.nodelabel,a.rack,a.slot,a.port,a.category,n.nodesysdescription,i.ipaddr,n.nodeparentid,a.circuitid FROM node AS n, assets AS a, ifservices AS i WHERE n.nodeid=i.nodeid AND i.serviceid=1 AND n.nodeid=a.nodeid AND n.nodeid='".$node."'AND ipaddr != '192.168.11.1' ORDER BY nodeid");
    }
    else
    {
        $sth= $dbh->prepare("SELECT n.nodeid,n.nodelabel,a.rack,a.slot,a.port,a.category,n.nodesysdescription,i.ipaddr,n.nodeparentid,a.circuitid FROM node AS n, assets AS a, ifservices AS i WHERE n.nodeid=i.nodeid AND i.serviceid=1 AND n.nodeid=a.nodeid AND ipaddr != '192.168.11.1' ORDER BY nodeid");
    }
    $sth->execute;
    my %node_info;

    my $i=0;
    my @row;
    while ( @row = $sth->fetchrow_array ) {
        
        
        
        if (! exists $node_info{$row[0]})
        {
            $node_info{$row[0]}{'interface'}=0;
            
            $node_info{$row[0]}{'nodelabel'}=$row[1];
            $node_info{$row[0]}{'rack'}=$row[2];
            $node_info{$row[0]}{'card'}=$row[3];
            $node_info{$row[0]}{'port'}=$row[4];
            $node_info{$row[0]}{'category'}=$row[5];            
            $node_info{$row[0]}{'sysdescr'}=$row[6];
            $node_info{$row[0]}{0}{ipaddr}=$row[7];
            $node_info{$row[0]}{'parent'}=$row[8];
            $node_info{$row[0]}{'circuitid'}=$row[9];
        }
        else
        {
            my $interface=$node_info{$row[0]}{'interface'}++;
            $node_info{$row[0]}{$interface}{ipaddr}=$row[7];
            #print $node_info{$row[0]}{nodelabel}." ... ".$interface."\n";
            #print $node_info{$row[0]}{$interface}{ipaddr}." ... ".$interface."\n";

        }
    }
    return \%node_info;
    $dbh->close();
}



sub sortHashValue  {

    my $a=shift;
    my $b=shift;
    my $ref_hash=shift;
    my $order=shift| "asc";
    my $key=shift | undef;
    
    my %tmp_hash=%$ref_hash;
    if ($order eq "asc")
    {
        if (defined $key)
        {
            $tmp_hash{$a}{$key} cmp $tmp_hash{$b}{$key};
        }
        else
        {
            $tmp_hash{$a} cmp $tmp_hash{$b};
        }
    }
    else
    {
        if (defined $key)
        {
            $tmp_hash{$b}{$key} cmp $tmp_hash{$a}{$key};
        }
        else
        {
            $tmp_hash{$b} cmp $tmp_hash{$a};
        }
    }
}



sub loadServerList
{
    my $db_host=shift || $dbhost_default;
    my $dbh = DBI->connect("dbi:mysql:dbname=".$db_table.";host=".$db_host, $db_user, $db_pass);
    my $server;my $sth1;
    #   chomp($server);
    $sth1= $dbh->prepare("SELECT id,Value,Router FROM routerConfig WHERE Attribute='serviceip' ");
    $sth1->execute;
    
    my %servers;
    while ( my @row = $sth1->fetchrow_array ) {
        
        $servers{$row[0]}{'ip'}=$row[1];
        $servers{$row[0]}{'name'}=$row[2];
        $servers{$row[0]}{'region'}=$row[2];
    }
    return \%servers;
    $dbh->close();
}

sub loadCoreSwitchList
{
    my $db_host=shift | $dbhost_default;
    my $dbh = DBI->connect("dbi:mysql:dbname=".$db_table.";host=".$db_host, $db_user, $db_pass);
    my $server;my $sth1;
    #   chomp($server);
    $sth1= $dbh->prepare("SELECT id,Value,Router FROM routerConfig WHERE Attribute='CORESWITCH' ");
    $sth1->execute;
    
    my %servers;
    while ( my @row = $sth1->fetchrow_array ) {
        
        $servers{$row[0]}{'ip'}=$row[1];
        $servers{$row[0]}{'name'}=$row[2];
        $servers{$row[0]}{'region'}=$row[2];
    }
    return \%servers;
    $dbh->close();
}

sub loadList
{
    my ($circuitid,$server) = @_;
    my $dbhost=$dbhost_default;
    my $dbh = DBI->connect("dbi:Pg:dbname=opennms;host=$dbhost", "opennms", "opennms");

    my $sth1;
    #   chomp($server);
    if (!$server)
    {
        if ($circuitid eq "REGIONS")
        {
            $sth1= $dbh->prepare(" select distinct a.region,count(n.nodeid) from assets as a,node as n where a.nodeid=n.nodeid GROUP by a.region");
        }
        else
        {
            $sth1= $dbh->prepare("SELECT ii.nodeid,ii.ipaddr,n.nodelabel,a.city,a.region,a.division FROM node AS n,assets AS a , ifservices AS i , ipinterface AS ii WHERE n.nodeid=i.nodeid AND i.ipaddr=ii.ipaddr AND a.circuitid='".$circuitid."' AND a.nodeid=i.nodeid  AND ii.nodeid=a.nodeid AND serviceid=1 ORDER BY i.ifindex ");
        }
    }
    else
    {
        $sth1= $dbh->prepare("SELECT ii.nodeid,ii.ipaddr,n.nodelabel,a.city,a.region,a.division FROM node AS n,assets AS a , ifservices AS i , ipinterface AS ii WHERE n.nodeid=i.nodeid AND i.ipaddr=ii.ipaddr AND a.circuitid='".$circuitid."' AND a.nodeid=i.nodeid  AND ii.nodeid=a.nodeid  AND i.nodeid='".$server."' AND serviceid=1");
    }
    
    $sth1->execute;
    my %servers;
    while ( my @row = $sth1->fetchrow_array ) {
        
        if ($circuitid eq "REGIONS")
        {
            $servers{$row[0]}=$row[1];
        }
        else
        {
            $servers{$row[0]}{'ip'}=$row[1];
            $servers{$row[0]}{'name'}=$row[2];
            $servers{$row[0]}{'city'}=$row[3];
            $servers{$row[0]}{'region'}=$row[4];
            $servers{$row[0]}{'division'}=$row[5];
        }
    }
    return \%servers;
    $dbh->close();
}



sub getVersion
{
my $version;
if (-e "/etc/fedora-release")
{
    $version=`cat /etc/fedora-release`;
}
elsif (-e "/etc/redhat-release")
{
    $version=`cat /etc/redhat-release`;
}

if ($version =~/Fedora Core release 2/)
{
    $version="fc2"
}
elsif ($version =~/Fedora Core release 3/)
{
    $version="fc3";
}
elsif ($version=~/Fedora Core release 4/)
{
    $version="fc4";
}
elsif ($version=~/Fedora Core release 5/)
{
    $version="fc5";
}
elsif ($version=~/Fedora Core release 6/)
{
    $version="fc6";
}
elsif ($version=~/CentOS release 5/)
{
    $version="centos5";
}
else
{
    print "Unknown version".$version."\n";
    return "unknown";
}
return $version;
}


sub loadConfig
{
    my $config_file=shift || '';
    my $donotloadAAA=shift || 0;
    my $debug=shift || 0;
my $main_config_file="/opt/perl-traffic-control/etc/www.conf";   
 
    my @configs;
    if ((!defined $config_file) || ($config_file eq ''))
    {
	    if ( -e  "/opt/perl-traffic-control/etc/www.conf")
        {
            my $purpose=lc(`cat /opt/perl-traffic-control/etc/www.conf | grep main::purpose`);
            $purpose=~s/main::purpose=//;
            chomp($purpose);
            $purpose=uc($purpose);
            $main::purpose=$purpose;
            push(@configs,"/opt/perl-traffic-control/etc/www.conf");
            if (
                (
                 ($purpose ne "NMS") &&  ($purpose ne "MAIL")
                )
                &&
                (
                 (defined $donotloadAAA) && ($donotloadAAA ne 1)
                )
                
               )
            {
                open(F,$main_config_file);
                while(<F>)
                {
                    $config_file=lc($_);
                    if ($config_file=~/main::regions=/)
                    {
                        $config_file=~s/main::regions=//;
                        $main::regions=$config_file;

                    }
                    elsif ($config_file=~/main::region=/)
                    {
                        $config_file=~s/main::region=//;
                        chomp($config_file);
                        $main::region=$config_file;
                        if ($config_file eq '')
                    {
                        print "Please give config file\n";
                    }
                        $config_file="/opt/perl-traffic-control/etc/AAA/$main::region.AAA.conf";
                        push(@configs,$config_file);
                    }
                }
                close(F);
            }
                else
            {
                $main::region=$main::purpose;
                if ((defined $debug) && ($debug > 1))
                {
                    print "Setting region as purpose $main::region\n";
                }
            }
        }
        else
        {
            print "/opt/perl-traffic-control/etc/www.conf not found !!\n";
        }
    }
    else
    {
        if (!defined $donotloadAAA)
        {
            $config_file="/opt/perl-traffic-control/etc/AAA/$config_file.AAA.conf";
            print "Config file is $config_file \n";
            push(@configs,$config_file);
        }
        else
        {
            print "Config file is $config_file \n";
            push(@configs,$config_file);
        }
        
    }


    push(@configs,"/opt/perl-traffic-control/etc/default.conf");
    for $config_file (@configs)
    {
        #    print "Parsing $config_file\n" if ($main::debug > 0);
        if ( -e  $config_file)
        {
            open CONF, "<$config_file";
            while(<CONF>){
                chomp;
                if (($_ ne "") || (/^#/))
                {
                    my ($var,$key,$val,$name);
                    no strict 'refs';
                    if (m#(.*)\{(.*)\}=(.*)#)
                    {
                        $var=$1;
                        $key=$2;
                        $val=$3;
                        chomp($val);
                        $name="Options::$var";
                        ${$name}{$key}=$val;
                    }
                    else
                    {
                        ($key,$val)=m#(.*)=(.*)#;
                        $name="Options::$key";
                        $$name=$val;

                    }

                    ($key,$val)=m#(.*)=(.*)#;
                    $name="Options::$key";
                    if ((defined $debug) && ($debug > 1))
                    {
                        print "$config_file sets !$name! => $val \n";
                    }
                }

            }
            close CONF;
        }
    else
    {
        print "CONFIG_FILE $config_file NOT FOUND";
        exit;
    }
        #print keys %Options::network;
    }
}

sub error
{
    my $msg=shift;
    open(LOG,">>/var/log/AAA.html");
    print LOG "$msg\n";
    close(LOG);
    print "<TR><td colspan=100%><font color=red>$msg</font></TD></TR>";
}


sub Tpassword
{
    my $password=shift;
    my $str;
    $str= "<TABLE BORDER=2>";
    $str=$str."<FORM METHOD=POST NAME=PASSWORD><TR>";
    $str=$str."<TD><INPUT TYPE=password name=pw1 value=$password></td>";
    $str=$str."<td><INPUT TYPE=password name=pw2 value=$password></td>";
    $str=$str."<td><INPUT TYPE=HIDDEN NAME=PWSAVE VALUE=1>";
    $str=$str."<INPUT TYPE=SUBMIT VALUE=Tallenna></td>";
    $str=$str."</TR></FORM></TABLE></TD>";
    
    return $str;
}


sub round
{
    my $number=shift;
    return sprintf "%1.1f",$number;
}

sub Tvalue
{
	my ($name,$value,$link)=@_;
	print "<tr><td><font color=yellow>";
	print "$name : </td>";
        print "<td><font color=white>".$value;
        print "</td>";
        if ($link ne 0)
        {
            #print "<td> $link</td>";
        } 
        else
        {
            print "<td><A HREF=index.html?add=1> REKISTER&OumlIDY</A></td>";
        }
        #print $link;
        print "</tr>";
        
}


return 1;
