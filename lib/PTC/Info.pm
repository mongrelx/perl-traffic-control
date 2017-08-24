package PTC::Info;

require 5.000;
use Exporter;
use Carp;
use strict;
use DBI;
use vars qw(@ISA @EXPORT $VERSION );
@ISA = qw(Exporter);
@EXPORT = qw(loaddir);


sub loaddir {
    # Returns a sort list of list, with each sublist being a file
    # and its attributes.
    #
    # Usage:  @entries = loaddir($dir);
    my $order = shift || 0;
    my $search = shift ;
    my $mikalie = shift;
    my $database= shift;
    
    my $use_clientSite=0;

    my @rv=();
    
    my ($nan,$auth,$redir)=(0,0,0);
    loadUsage();
    loadSFQUsage();
    my @temp;
    my $file_msg='';
    my $online_file="/opt/perl-traffic-control/tmp/currently_online";
    
    my %list=();;
    if ((defined $database ) && ($database eq 1))
    {
        if ($use_clientSite eq 1)
        {
            my $sth_ptc= $main::dbh_ptc->prepare("SELECT clientid FROM clientSite WHERE siteid=$search");
            $sth_ptc->execute;
            while ( my @row = $sth_ptc->fetchrow_array ) {
                my $clientid=$row[0];
                $clientid=~s/\.\d+//;
                $list{$clientid}=1;
            }
        }
        else
        {
            open (F,">/opt/perl-traffic-control/tmp/clientSite");
            my $str="/usr/java/j2sdk1.4.2_06/bin/java -classpath /opt/perl-traffic-control/lib/mysql.jar:/opt/perl-traffic-control/nms:/opt/perl-traffic-control/lib/sljc.jar getSiteClients $search";
            print F $str;
            my @clientList=`$str`;

            foreach (@clientList)
            {

                my $clientid=$_;
                $clientid=~s/\.\d+//;
                $clientid=~s/\s+//;
                $list{$clientid}=1;
                print F "clientid =>!$clientid!";
            }
            close(F);
        }
        $search=undef;
    }


    if ( -e $online_file )
    {
        my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$block) = stat($online_file);
        $file_msg=time-$mtime;
        if ((time-$mtime) > 300)
        {
            $file_msg="Check daemon\n";
        }
        else
        {
        }
        open(F,"<$online_file");
        my $ready=0;
        while (<F>)
        {
            chomp();
            if ($_ =~/^RUN ENDED/)
            {
                $ready=1;
            }
            elsif (/^PROGRAM/)
            {

            }
            else
            {
                if ((defined $search) && ($search ne ''))
                {
                    if ($_=~/$search/)
                    {
                        push (@rv,$_);
                    }
                }
                elsif ((defined $database) && ($database eq 1))
                {
                    foreach my $clientid (keys %list)
                    {
                        if ($_=~/$clientid/)
                        {
                            #push (@rv,$clientid);
                            push (@rv,$_);
                        }
                    }
                }
                else
                {
                    push (@rv,$_);
                }
            }

        }
        if (-e "/opt/perl-traffic-control/tmp/col.list")
        {
            open(F,"</opt/perl-traffic-control/tmp/col.list");
            my $ready=0;
            while (<F>)
            {
                chomp();
                if ($_ =~/^RUN ENDED/)
                {
                    $ready=1;
                }
                elsif (/^PROGRAM/)
                {

                }
                else
                {
                    if ((defined $search) && ($search ne ''))
                    {
                        if ($_=~/$search/)
                        {
                            push (@rv,$_);
                        }
                    }
                    elsif ((defined $database) && ($database eq 1))
                    {
                        foreach my $clientid (keys %list)
                        {
                            if ($_=~/$clientid/)
                            {
                                #push (@rv,$clientid);
                                push (@rv,$_);
                            }
                        }
                    }
                    else
                    {
                        push (@rv,$_);
                    }
                }
            }
        }

        
        if ($ready eq 0)
        {
            return -1;
        }

        @rv = map  {
            @temp=split(":",$_);
            $temp[0]=substr($temp[0],0,1);
            my $msg;
            for (my $i=0;$i<14;$i++)
            {
                $temp[$i]="N/A" if (! defined $temp[$i]);
            }


            if ($temp[8] eq '1')
            {
                $msg='REDIRECTED';
                $redir++;
            }
            elsif ($temp[9] eq 'N/A' || $temp[9] eq '' )
            {
                $msg='NOT Auth';
                $nan++;

            }
            else
            {
                $msg='Authenticated';
                $auth++;
            }

            my $str="$temp[2]:$temp[3]:$temp[4]:$temp[5]:$temp[6]:$temp[7]";
            $main::status{$str}{ip}=$temp[1];
            $main::status{$str}{redirect}=$temp[8];
            $main::status{$str}{speed}=$temp[10];
            $main::status{$str}{customer}=$temp[9];
            $main::status{$str}{inclass}=$temp[11];
            $main::status{$str}{outclass}=$temp[12];
            $main::status{$str}{port}=$temp[13];


            my $in_dropped=$main::class{$main::status{$str}{inclass}}{'dropped'};
            my $in_overlimit=$main::class{$main::status{$str}{inclass}}{'overlimit'};
            my $outload=$main::class{"1:".$main::status{$str}{outclass}}{'rate'};
            my $out_dropped=$main::class{$main::status{$str}{outclass}}{'dropped'};
            my $out_overlimit=$main::class{$main::status{$str}{outclass}}{'overlimit'};
            my $status_msg="FUCK";
            my $cbs_in=$main::class{"1:".$main::status{$str}{inclass}}{'cbps'};
            my $cbs_out=$main::class{"1:".$main::status{$str}{outclass}}{'cbps'};
            my $pps_in=$main::class{"1:".$main::status{$str}{inclass}}{'cpps'};
            my $pps_out=$main::class{"1:".$main::status{$str}{outclass}}{'cpps'};
            my $str2="0 Kbit";my $str3="0 Kbit";
            my $cbs_total=0;
            if (defined $cbs_in)
            {
                $str2="$cbs_in Kbit";
                $cbs_total=$cbs_total+$cbs_in;
            }

            if (defined $cbs_out)
            {
                $str3="$cbs_out Kbit";
                $cbs_total=$cbs_total+$cbs_out;
            }

            my $pps_total=0;
            if (defined $pps_in)
            {
                $str2=$str2."/$pps_in";
                $pps_total=$pps_total+$pps_in;
            }
            if (defined $pps_out)
            {
                $str3=$str3."/$pps_out";
                $pps_total=$pps_total+$pps_out;
            }
            
            
            my $total=$cbs_total."/".$pps_total;

            #Activity timer
            if (defined $temp[14])
            {
                $status_msg="$temp[0]/$temp[13]/$temp[14]";
            }
            else
            {
                $status_msg="$temp[0]/$temp[13]/";
            }
            [$status_msg,$temp[1],$str, $main::status{$str}{speed},$temp[9],$str3,$str2,$total]

        } sort @rv;
        close(F);

        #        @Current=`cat /opt/perl-traffic-control/tmp/currently_online`;
        
        if ($order eq 1)
        {
            @rv=sort {
                my $tempA =  @$a[$order];
                my $tempB =  @$b[$order];
                $tempA=~m#(\d+)\.(\d+)\.(\d+)\.(\d+)#;
                my $Aa=$1;my $Ab=$2;my $Ac=$3;my $Ad=$4;
                $tempB=~m#(\d+)\.(\d+)\.(\d+)\.(\d+)#;
                my $Ba=$1;my $Bb=$2;my $Bc=$3;my $Bd=$4;
                ($Aa <=> $Ba) ||
                    ($Ab <=> $Bb) ||
                    ($Ac <=> $Bc) ||
                    ($Ad <=> $Bd)
                    ;

            } @rv;
        }
        elsif (($order eq 3) || ($order eq 4) || ($order eq 7) )
        {
            @rv=sort {
                my $tempA =  @$a[$order];
                my $tempB =  @$b[$order];
                if ($tempA=~m#(\d+)\/(.*)#)
                {
                    $tempA=$1;
                }
                else
                {
                    $tempA=0;
                }
                if ($tempB=~m#(\d+)\/(.*)#)
                {
                    $tempB=$1;
                }
                else
                {
                    $tempB=0;
                }

                if ($order eq 7)
                {
                    $tempB <=> $tempA
                }
                else
                {
                    $tempA <=> $tempB
                }
                
                
                
            } @rv;
        }
        elsif ( ($order eq 5) || ($order eq 6) )
        {
            @rv=sort {
                my $tempA =  @$a[$order];
                my $tempB =  @$b[$order];
                $tempA=~s/Kbit.*//;
                $tempB=~s/Kbit.*//;
                $tempB <=> $tempA
            } @rv;
        }
        else
        {
            @rv=sort {
                            my $tempA =  @$a[$order];
                            my $tempB =  @$b[$order];
                            $tempB cmp $tempA
            } @rv;
        }
    }

    $main::users_string="(last update : $file_msg s) Not auth : $nan Authenticated : $auth Redirected : $redir";
    return \@rv;
}

sub loadUsage
{
    my $out_count=0;
    my $in_device=0;
    foreach my $device (keys %main::QoSDevice)
    {
        if (exists $main::QoSDevice{$device}{out})
        {
            print "Device $device is out_device\n" if ($main::debug > 2);
            $out_count++;
            $in_device=0;
            
        }
        else
        {
            print "Device $device is in_device\n" if ($main::debug > 2);;
            $in_device=1;
        }
        print "Reading $device stats\n" if ($main::debug > 4);
        my @usage=`tc -s class show dev $device`;

        my $str2="";
        my  $classnum=0;
        foreach (@usage)
        {

            if (m#class\s+htb\s+(\d+:\d+)#)
            {
                $classnum=$1;
                $main::class{$classnum}{$device} = {
                    rate => "0Kbit"
                };
            }
            elsif (m#rate\s+(.*)\s+backlog#)
            {
                $main::class{$classnum}{$device} = {
                    rate => "$1"
                };
                #print $_;
            }
            elsif (m#rate\s+(.*)#) # for fc <4
            {
                $main::class{$classnum}{$device} = {
                    rate => "$1"
                };
                #print $_;
            }
        }
        foreach $classnum (keys %main::class)
        {                                      
            if (defined $main::class{$classnum}{$device}{'rate'})
            {
                print "CLASSNUM $device $classnum ".$main::class{$classnum}{$device}{'rate'}."\n" if ($main::debug > 4);
                my $cbps=0;
                my $cpps=0;
                my $rate=$main::class{$classnum}{$device}{'rate'};
                if ($rate=~m#(\d+)bps#)
                {
                    $str2=int(($1*8)/1024);
                    if ($rate=~m#(\d+)pps#)
                    {
                        $cbps=$str2;
                        $cpps=$1;
                        $str2=$str2." Kbit/$1";
                    }
                    else
                    {
                    $cbps=$str2;
                    $str2=$str2." Kbit/0";
                    }

                }
                elsif ($rate=~m#(\d+)Kbit#)
                {
                    $str2=$1;
                    if ($rate=~m#(\d+)pps#)
                    {
                        $cbps=$str2;
                        $cpps=$1;
                        $str2=$str2." Kbit/$1";
                    }
                    else
                    {
                        $cbps=$str2;
                        $str2=$str2." Kbit/0";

                    }

                }
                elsif ($rate=~m#(\d+)bit#)
                {
                    if ($main::distribution eq "fc3")
                    {
                        $str2=int($1*8/1024);
                    }
                    else
                    {
                        $str2=int($1/1024);
                    }
                    if ($rate=~m#(\d+)pps#)
                    {
                        $cbps=$str2;
                        $cpps=$1;
                        $str2=$str2." Kbit/$1";
                    }
                    else
                    {
                        $cbps=$str2;
                        $str2=$str2." Kbit/0";
                    }

                }
                else
                {
                    $cbps=$str2;
                    $str2=$rate." Kbit";
                }
                if (($out_count eq 1) || ($in_device eq 1) )
                {
                    $main::class{$classnum}{'cbps'}=$cbps;
                    $main::class{$classnum}{'cpps'}=$cpps;
                }
                else
                {
                    $main::class{$classnum}{'cbps'}+=$cbps;
                    $main::class{$classnum}{'cpps'}+=$cpps;
                }
                print "RATE for $classnum  $out_count : ".$main::class{$classnum}{'cbps'}.":".$main::class{$classnum}{'cpps'}."  ".$rate."  ".$str2."\n" if ($main::debug > 4);
            }
        }
    }
}


sub loadSFQUsage
{
    my %QoSDeviceStats=();
    my $out_count=0;
    my $in_device=0;
    foreach my $device (keys %main::QoSDevice)
    {
        if (exists $main::QoSDevice{$device}{out})
        {
            print "Device $device is out_device\n" if ($main::debug > 2);
           
            $out_count++;
            $in_device=0;
        }
        else
        {
            print "Device $device is in_device\n" if ($main::debug > 2);;
            $in_device=1;
        }
        my @usage=`tc -d -s qdisc show dev $device`;
        my $classnum=0;
        foreach (@usage)
        {
            if (m#qdisc sfq\s+(\d+)\:#)
            {
                $classnum=$1;
                $main::class{$classnum}{'dropped'}="0";

            }
            elsif (m#Sent\s+(\d+)\s+bytes\s+(\d+)\s+pkt\s+\(dropped\s+(\d+),\soverlimits\s+(\d+)\s+requeues\s+(\d+)#)
            {
                if (($out_count eq 1) || ($in_device eq 1) || ($classnum eq "4096"))
                {
                    $main::class{$classnum}{'bytes'}=$1;
                    $main::class{$classnum}{'pkts'}=$2;
                    $main::class{$classnum}{'dropped'}=$3;
                    $main::class{$classnum}{'overlimit'}=$4;
                    $main::class{$classnum}{'requeues'}=$5;
                }
                else
                {
                    $main::class{$classnum}{'bytes'}+=$1;
                    $main::class{$classnum}{'pkts'}+=$2;
                    $main::class{$classnum}{'dropped'}+=$3;
                    $main::class{$classnum}{'overlimit'}+=$4;
                    $main::class{$classnum}{'requeues'}+=$5;
                }
                if ($classnum eq "4096")
                {
                    $QoSDeviceStats{"$device"}{"$classnum"}{'bytes'}=$main::class{$classnum}{'bytes'};
                    $QoSDeviceStats{"$device"}{"$classnum"}{'pkts'}=$main::class{$classnum}{'pkts'};
                    $QoSDeviceStats{"$device"}{"$classnum"}{'dropped'}=$main::class{$classnum}{'dropped'};
                    $QoSDeviceStats{"$device"}{"$classnum"}{'overlimit'}=$main::class{$classnum}{'overlimit'};
                }
            }
            elsif (m#Sent\s+(\d+)\s+bytes\s+(\d+)\s+pkts\s+\(dropped\s+(\d+),\soverlimits\s+(\d+)\s+requeues\s+(\d+)\)#) # for fc3
            {
                if (($out_count eq 1) || ($in_device eq 1) || ($classnum eq "4096"))
                {
                    $main::class{$classnum}{'bytes'}=$1;
                    $main::class{$classnum}{'pkts'}=$2;
                    $main::class{$classnum}{'dropped'}=$3;
                    $main::class{$classnum}{'overlimit'}=$4;
                    $main::class{$classnum}{'requeues'}=$5;
                }
                else
                {
                    $main::class{$classnum}{'bytes'}+=$1;
                    $main::class{$classnum}{'pkts'}+=$2;
                    $main::class{$classnum}{'dropped'}+=$3;
                    $main::class{$classnum}{'overlimit'}+=$4;
                    $main::class{$classnum}{'requeues'}+=$5;


                }

                if ($classnum eq "4096")
                {
                    $QoSDeviceStats{"$device"}{"$classnum"}{'bytes'}=$main::class{$classnum}{'bytes'};
                    $QoSDeviceStats{"$device"}{"$classnum"}{'pkts'}=$main::class{$classnum}{'pkts'};
                    $QoSDeviceStats{"$device"}{"$classnum"}{'dropped'}=$main::class{$classnum}{'dropped'};
                    $QoSDeviceStats{"$device"}{"$classnum"}{'overlimit'}=$main::class{$classnum}{'overlimit'};
                }
            }

            elsif (m#Sent\s+(\d+)\s+bytes\s+(\d+)\s+pkts\s+\(dropped\s+(\d+),\soverlimits\s+(\d+)\)#) # for fc2
            {
                if (($out_count eq 1) || ($in_device eq 1) || ($classnum eq "4096"))
                {
                    $main::class{$classnum}{'bytes'}=$1;
                    $main::class{$classnum}{'pkts'}=$2;
                    $main::class{$classnum}{'dropped'}=$3;
                    $main::class{$classnum}{'overlimit'}=$4;
                }
                else
                {
                    $main::class{$classnum}{'bytes'}+=$1;
                    $main::class{$classnum}{'pkts'}+=$2;
                    $main::class{$classnum}{'dropped'}+=$3;
                    $main::class{$classnum}{'overlimit'}+=$4;
                }

                if ($classnum eq "4096")
                {
                    $QoSDeviceStats{"$device"}{"$classnum"}{'bytes'}=$main::class{$classnum}{'bytes'};
                    $QoSDeviceStats{"$device"}{"$classnum"}{'pkts'}=$main::class{$classnum}{'pkts'};
                    $QoSDeviceStats{"$device"}{"$classnum"}{'dropped'}=$main::class{$classnum}{'dropped'};
                    $QoSDeviceStats{"$device"}{"$classnum"}{'overlimit'}=$main::class{$classnum}{'overlimit'};
                }
            }

            elsif (~m#backlog\s+(\d+)p#)
            {
                $main::class{$classnum}{'backlog'}=$1;
            }
            else
            {

                #      print "NOOO $_";
            }

        }
    }
    #    exit;
}



1;
