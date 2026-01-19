#!/usr/bin/perl/

use strict;
use warnings;
use Text::CSV;
use Getopt::Long;
use Time::Piece;
use Time::Seconds;
use Data::Dumper;

# Define the fields to extract from sacct
my @fields = qw(
    Account AllocCPUS AllocNodes AllocTRES AveRSS AveVMSize Cluster Constraints Container
    CPUTimeRAW DBIndex ElapsedRaw Eligible End ExitCode FailedNode Flags Group
    JobID JobIDRaw MaxRSS MaxVMSize NCPUS NNodes NTasks Partition QOS QOSRAW ReqMem ReqTRES Start State 
    Submit TimelimitRaw User 
);

	Account AllocCPUS AllocNodes AllocTRES AveRSS AveVMSize Cluster 
    CPUTimeRAW         ElapsedRaw Eligible End ExitCode                  Group
    JobID JobIDRaw MaxRSS MaxVMSize NCPUS NNodes NTasks Partition QOS QOSRAW ReqMem ReqTRES Start State 
    Submit TimelimitRaw User 

my @tresfields = qw(
    ReqTRES_billing ReqTRES_cpu ReqTRES_gpu ReqTRES_mem ReqTRES_node
	AllocTRES_billing AllocTRES_cpu AllocTRES_gpu AllocTRES_mem AllocTRES_node
);

# Command-line options for starttime, duration, cluster name, and debug
my ($starttime_str, $duration, $cluster_name, $debug, $jobid);
GetOptions(
    'starttime=s' => \$starttime_str,
    'duration=s'  => \$duration,
    'cluster=s'   => \$cluster_name,
    'debug'       => \$debug,
    'jobid=s'     => \$jobid,
) or die "Usage: $0 --starttime=YYYY-MM-DDTHH:MM:SS --duration=day|week|month --cluster=CLUSTER_NAME [--debug]\n";

die "--starttime, --duration, and --cluster are mandatory\n" unless $starttime_str && $duration && $cluster_name;

# Parse start time
my $start_time = Time::Piece->strptime($starttime_str, "%Y-%m-%dT%H:%M:%S");

# Calculate end time based on duration
my $end_time;
if ($duration eq 'day') {
    $end_time = $start_time + ONE_DAY;
} elsif ($duration eq 'week') {
    $end_time = $start_time + ONE_WEEK;
} elsif ($duration eq 'month') {
    my $yd = $start_time->strftime("%Y");
    my $md = $start_time->strftime("%m");
    my $dd = 1;

    $start_time = Time::Piece->strptime("$yd-$md-$dd","%Y-%m-%d"); # start at the first of the month

    $md = $md + 1;
    if ($md > 12) {
        $md = 1;
        $yd += 1;
    }

    $end_time = Time::Piece->strptime("$yd-$md-$dd","%Y-%m-%d");  # 1 month added to start time
} else {
    die "Invalid duration specified. Use: day, week, or month\n";
}
$end_time = Time::Piece->strptime($end_time->strftime("%s") -1,"%s"); # Adjust end time to be inclusive of the last second;

# Format start and end times for sacct
my $starttime = $start_time->strftime("%Y-%m-%d %H:%M:%S");
my $endtime = $end_time->strftime("%Y-%m-%d %H:%M:%S");

# Debug output
if ($debug) {
    print "[DEBUG] Start Time: $starttime\n";
    print "[DEBUG] End Time:   $endtime\n";
    print "[DEBUG] Cluster:    $cluster_name\n";
    print "[DEBUG] JobID:      $jobid\n";
}

# Period identifier for the CSV row
my $period_id = $start_time->strftime("%Y-%m-%d");
my $period_duration = $duration;

# Set output file name
my $output_filename = "sacct-$cluster_name-$duration-" . $start_time->strftime("%Y-%m-%d") . ".csv";

# Join fields for sacct argument
my $field_string = join(",", @fields);

# Format start and end time for sacct command (must use T format)
my $sacct_start = $start_time->strftime("%Y-%m-%dT%H:%M:%S");
my $sacct_end   = $end_time->strftime("%Y-%m-%dT%H:%M:%S");

# Command to run
my $cmd = "sacct --allocations --array --allusers --parsable2 --noheader --truncate --duplicates --noconvert -o $field_string --starttime=$sacct_start --endtime=$sacct_end";
if (defined $jobid) {$cmd .= " --job=$jobid"};


# Open a pipe to the sacct command
open(my $sacct_fh, '-|', $cmd) or die "Cannot run sacct: $!";

# Set up CSV writer
my $csv = Text::CSV->new({ binary => 1, eol => "\n" });
open(my $out_fh, '>', $output_filename) or die "Cannot open output file: $!";

# Parse and write each line of output
my $header_written = 0;
my @extended_headers;
while (my $line = <$sacct_fh>) {
    chomp $line;
    my @values = split(/\|/, $line, -1);  # -1 preserves trailing empty fields

    # Build a hash for easier field lookup
    my %record;
    @record{@fields} = @values;

    # Reformat selected timestamp fields
    for my $ts_field (qw(Start End Submit Eligible)) {
        if (defined $record{$ts_field} && $record{$ts_field} ne '') {
            eval {
                my $t = Time::Piece->strptime($record{$ts_field}, "%Y-%m-%dT%H:%M:%S");
                $record{$ts_field} = $t->strftime("%Y-%m-%d %H:%M:%S");
            };
        }
    }


    my $timestamp = localtime;

    my %tres_details;
    foreach (@tresfields) {
	$tres_details{$_} = 0;
    }

    # Extract AllocTRES and ReqTRES key-value pairs
    foreach my $tres_field (qw(AllocTRES ReqTRES)) {
        if (defined $record{$tres_field}) {

	    if ($debug) {print Dumper $record{$tres_field};};

            foreach my $kv (split(/,/, $record{$tres_field})) {
                my ($k, $v) = split(/=/, $kv, 2);
                $v //= '';
                if ($k eq 'mem') {
                    if ($v =~ /^(\d+(?:\.\d+)?)([KMGTP])?$/i) {
                        my ($num, $unit) = ($1, uc($2 // 'M'));
                        my %mult = (K => 1/1024, M => 1, G => 1024, T => 1024*1024, P => 1024*1024*1024);
                        $v = sprintf("%.0f", $num * ($mult{$unit} // 1));
                    }
                }
                $tres_details{"${tres_field}_$k"} = $v;
		if ($debug) {print "${tres_field}_$k = $v\n";};

	    }
        }
    }


    unless ($header_written) {
        @extended_headers = ('PeriodID', 'PeriodDuration', 'ClusterName', 'timestamp', @fields, @tresfields);
        $csv->print($out_fh, \@extended_headers);
        $header_written = 1;
    }

    my @row_values = map { $record{$_} // '' } @fields;
    my @tres_values = map { $tres_details{$_} // '' } @tresfields;
    my @extended_values = ($period_id, $period_duration, $cluster_name, $timestamp->strftime("%Y-%m-%dT%H:%M:%S"), @row_values, @tres_values);
    $csv->print($out_fh, \@extended_values);
}

close($sacct_fh);
close($out_fh);

print "sacct data written to $output_filename\n";
