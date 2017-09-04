#!/usr/local/bin/perl
use strict;
use warnings;
use Log::Mini;
 
# Use all default parameters
#my $log = File::Log->new();

my $log = Log::Mini->new({
  level           => 4,                   # Set the debug level
  logFileName     => 'logFile.log',       # Define the log filename
  logmethod       => '>>',                # '>>' Append or '>' overwrite
  msgtimestamp    => 1,                   # Timestamp log data entries
  appName         => 'testApp',           # Name of the application
  msgprepend      => '',                  # Text to prepend to each message
  dateFormat      => '%Y-%m-%d-%H-%M-%S'  # POSIX strftime formatting
});

$log->msg(6, "Add this to the log file if level <= 6\n");     # Trace level
$log->msg(4, "Add this to the log file if level <= 4\n");     # Info level
$log->msg(3, "Add this to the log file if level <= 3\n");     # Warn level
