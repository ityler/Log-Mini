#  Mini.pm
package Log::Mini;
#
# Ability to open multiple instances of the log
#   -> 1 for debug
#   -> 1 for errors
#   -> 1 for totality
#  Different categories (levels) of errors: 
#    TRACE/DEBUG/INFO/WARN/ERROR/FATAL
#  LEVELS:
#     6 => trace
#     5 => debug
#     4 => info
#     3 => warn
#     2 => error
#     1 => fatal
#
# Ability to trigger all msgs with certain level to go to another file or to stdout
# Ability to define a config file to use rather than create anonymous hash of 
# attributes for each log instance
# -----------------------------------------------------
# Use log4perl->easy_init method of defining layout '%F{1}-%L-%M: %m%n'
#
# message_timestamp -> Need ability to determine date/timestamp used in most recent write to log
#  -> This allows an additional write to occur at the same time somewhere else or to be returned in order to match action to logfile 
#
# Config value to enable level string included with output (WARN,INFO,FATAL,etc...) Message tag
#
# -

use strict;
use warnings;
use vars qw($ERRSTR);
use Carp qw(confess);
use FileHandle;

$ERRSTR = "";

# Constructor
sub new {
  my ($class,$args) = @_;
  my $self = {};
  my $object = bless($self,$class);   # Create $object of type $class
  $object->_init($args);              # Initialize logger instance
  return $object;
}

# -
# Internal initialization
# -
sub _init {
  my $self = shift;
  # Set initial default values in case no config is used
  $self->{'logmethod'        } = '>';             # Write method (overwrite)
  $self->{'level'            } = 4;               # Log level (info)
  $self->{'msgtimestamp'     } = 0;               # Timestamp with log msg write
  $self->{'logfiletimestamp' } = 0;               # Timestamp on log filename
  $self->{'msgprepend'       } = '';              # Prepend log msg write
  $self->{'dateFormat'       } = '';              # Format of msgtimestamp
  $self->{'_logFileOpen'     } = 0;               # (Internal) open status
  $self->{'_fileHandle'      } = FileHandle->new; # (Internal) file pointer
  # $self->{'logFileName'}
  # $self->{'appName'}

  # Parameters passed during creation
  if(@_){                  
    print "Passed data\n";
    # Config should be an anonymous hash
    if (ref $_[0] eq 'HASH'){
      print "Anonymous hash passed\n";
      my $config = $_[0];
      foreach my $key (keys %$config){
        print "key: $key\n";
        $self->{lc($key)} = $config->{$key};
      }
    }
  }

  # Do we have a log filename defined
  if(defined($self->{'logfilename'}) && 
             $self->{'logfilename'} ne ''){
    # Log filename was set
    print "logfilename set\n";
  }
  # Do we have an appname defined
  if(defined($self->{'appname'}) && 
             $self->{'appname'} ne ''){
    print "appname set\n";
    # Appname was set
  } else {        
    print "no appname set\n";                                
    use FindBin qw($RealBin $RealScript);
    # Get the location and name of the calling script
    (my $appName = "$RealBin/$RealScript") =~ s/\.pl//i;
    $self->{'appname'} = $appName;                                      # Set appname as calling script
  }
  if(!defined($self->{'logfilename'}) || $self->{'logfilename'} eq ''){ # No logfilename set or empty
    $self->{'logfilename'} = $self->{'appname'}.'.log';                 # Use appname.log' as logfilename
  }
  return $self->_open;                                                  # Create opened log file
}

# -
# Internal open method
# -
sub _open {
  my $self = shift;  
  if($self->{'_logFileOpen'}){ close($self->{'_fileHandle'}); }   # Log file is already open, close it
  # Determine log filename
  my $logFileName = $self->{'logfilename'};                       # Current filename
  if($self->{'logfiletimestamp'}){                                # Filename should include timestamp per config
    my ($sec, $min, $hr, $day, $month, $year, $wday, $yday, $isdst) = localtime();    # Split out time
    my $filedt = sprintf "%d%02d%02d-%02d%02d%02d", ($year + 1900), ($month + 1), $day, $hr, $min, $sec; # Set filename
    $logFileName =~ s/(\.[^.]*?$)/"_$filedt$1"/e;                 # Format filename part
  }
  
  # Set real log filename
  $self->{'logfilename'} = $logFileName;

  # Open the log file
  my $openStatus;
  my $mode = $self->{'logmethod'};                                  # Write mode
  $openStatus = open($self->{'_fileHandle'}, $mode, $logFileName);  # Try to open log
  if(! $openStatus){                                                # Unable to open log
    print "Could not open '$logFileName' with mode '$mode': $! ";
    $self->{'_logFileOpen'} = 0;                                    # Clear open status flag
    return undef;
  }
  $self->{'_logFileOpen'} = 1;                                      # Set open status flag
  return $self;
}

# -
# Write out message to log
# -
sub msg {
  my $self = shift;
  my $now         = '';       # Timestamp for msg write
  my $msg_prepend = '';       # Prepend string for msg write
  my $msg_level = '';         # Message level numeric
  # Do we have enough parameters (level, msg)
  @_ > 1 or confess 'Usage: log->msg(debugLevel, "message string"|@messageStrings)';

  # If the supplied msg level is greater than the debug level, do nothing
  $msg_level = shift;         # Passed message level
  if ($msg_level > $self->{'level'}){ return; };

  my $str = join('', @_);

  # Add timestamp to msg write if requested
  if ($self->{'msgtimestamp'}){
    # Specific timestamp format is set
    if ($self->{'dateformat'}){
      require POSIX;
      $now = POSIX::strftime($self->{'dateformat'}, localtime) . ' ';
    } else {
      # Default timestamp format
      $now = scalar(localtime()) . ' ';
    }
  }

  # Prepend text if necessary
  $msg_prepend = $self->{'msgprepend'} if $self->{'msgprepend'};

  # Format the string and print it to the logfile
  $str =~ s/\n(?=.)/\n$now$msg_prepend/gs;

  print {$self->{'_fileHandle'}} $now, $msg_prepend, $str;
}

# -
# Close log file
# -
sub close {
  my $self = shift;
  close *{$self->{'_fileHandle'}} if (ref($self->{'_fileHandle'}) eq 'GLOB' && $self->{'_logFileOpen'});
  $self->{'_logFileOpen'} = 0;
}

# -
# Enable/disable timestamp recorded with each msg to log
#  The C<dateTimeStamp> method can be used to set or get the value of the I<dateTimeStamp> instance variable.
#  If called without parameters, the current value of the I<dateTimeStamp> instance variable is returned.
#  If called with a parameter, the parameter is used to set the I<dateTimeStamp> instance variable and the
#  previous value is returned.
# -
sub msg_timestamp {
  my $self = shift;
  my $prev = $self->{'msgtimestamp'};
  if (@_){
    $self->{'msgtimestamp'} = ($_[0] ? 1: 0);
  }
  return $prev;
}

# -
# Get log path+filename
# -
sub get_log_filename { 
  my $self = shift;
  return $self->{'logfilename'}; 
}

# -
# Get logger instance configuration values
# -
sub get_log_config {

}

1;