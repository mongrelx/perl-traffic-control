#!/usr/bin/perl

$warn = -15.0;
$crit = -5.0;

$output = `/usr/bin/digitemp_DS9097 -q -c /etc/digitemp.conf -t 0 -o 2`;
print $output;
if($output =~ /^\d+\t([-]?[\d\.]+)/) {
  $temp0 = $1 + 0;
  if($temp0 >= $crit) {
    print "CRIT Fridge temperature is ${temp0}C (>= ${crit}C)|temp0=${temp0}\n";
    exit 2;
  } elsif($temp0 >= $warn) {
    print "WARN Fridge temperature is ${temp0}C (>= ${warn}C)|temp0=${temp0}\n";
    exit 1;
  } else {
    print "OK Fridge temperature is ${temp0}C|temp0=${temp0}\n";
    exit 0;
  }
} else {
  print "Cannot find probe!\n";
  exit 3;
}
