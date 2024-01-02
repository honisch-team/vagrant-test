#!/usr/bin/perl
use warnings;
use strict;
use feature qw(say);
use Getopt::Long 'HelpMessage';

# Log error
sub logErr {
  my ($msg) = @_;
  say "Error: $msg";
}


# Log message
sub logMsg {
  my ($msg) = @_;
  say $msg;
}


# Build line for VMX from key and value
sub buildVmxLine {
  my ($key, $value) = @_;
  $_ = $value;
  s/\|/\|7C/g;
  s/\"/\|22/g;
  return "$key = \"$_\"";
}


# Read VMX file
sub readVmxFile {
  my $filename = $_[0];
  my $eol = \$_[1];

  logMsg("Reading from $filename");

  my $fh;
  unless (open $fh, '<', $filename) {
    logErr("Error reading from $filename");
    exit 1;
  }
  my @lines = <$fh>;
  close $fh;

  # Look at first line to determine line ending type
  $$eol = "\n";
  if ($lines[0] =~ /\r\n$/) {
    $$eol = "\r\n";
  }

  # Remove line endings
  for (@lines) {
    s/\R//;
  }

  return @lines;
}


# Write VMX file
sub writeVmxFile {
  my ($filename, $eol, @lines) = @_;
  logMsg("Writing to $filename");
  my $fh;
  unless (open $fh, '>', $filename) {
    logErr("Error writing to $filename");
    exit 1;
  }
  print $fh "$_$eol" for @lines;
  close $fh;
}


# Convert glob patter to regex string
sub glob2pat {
  my $globstr = shift;
  my %patmap = (
    '*' => '.*',
    '?' => '.'
    );
  $globstr =~ s{(.)} { $patmap{$1} || "\Q$1" }ge;
  return $globstr;
}


# Process command "set"
sub cmdSet {
  my ($vmxFile, $outputFile, @entries) = @_;

  logMsg("Setting VMX entries");
  # Read file content
  my $eol;
  my @lines = readVmxFile($vmxFile, $eol);


  # Modify file content
  for my $entry (@entries) {
    # Split key/value
    my ($key, $value);
    if ($entry =~ /^(.+?)=(.*)$/) {
      $key = $1;
      $value = $2;
    } else {
      logErr "Invalid argument: $entry";
      exit 1;
    }

    # Look for existing entry and replace it
    my $done = 0;
    for my $line (@lines) {
      # Ignore comment lines
      if ($line =~ /^\s*#/) {
        next;
      }
      # Look for given key
      if ($line =~ /^\s*\Q$key\E\s*=/) {
        $line = buildVmxLine($key, $value);
        logMsg("Updating: $line");
        $done = 1;
        last;
      }
    }

    # If entry not found, append it
    if (not $done) {
      my $line = buildVmxLine($key, $value);
      logMsg("Appending: $line");
      push @lines, buildVmxLine($key, $value);
    }
  }

  # Write file content
  writeVmxFile($outputFile, $eol, @lines);
  logMsg("Done setting VMX entries")
}


# Process command "remove"
sub cmdRemove {
  my ($vmxFile, $outputFile, @entries) = @_;

  logMsg("Removing VMX entries");
  # Read file content
  my $eol;
  my @lines = readVmxFile($vmxFile, $eol);

  # Modify file content
  for my $entry (@entries) {
    my $regexPattern = glob2pat($entry);
    my $regex = qr/^\s*$regexPattern\s*=/;

    # Look for existing entries and remove them
    for (my $i = $#lines; $i >= 0; $i--) {
      # Ignore comment lines
      if ($lines[$i] =~ /^\s*#/) {
        next;
      }

      # Look for given key
      if ($lines[$i] =~ $regex) {
        logMsg("removing: $lines[$i]");
        splice @lines, $i, 1;
      }
    }
  }

  # Write file content
  writeVmxFile($outputFile, $eol, @lines);
  logMsg("Done removing VMX entries")
}


# Main function
sub main {

  # Default vars
  my $outputFile = '';

  # Parse options
  GetOptions(
    'output|o=s'     =>   \$outputFile,
    'help'     =>   sub { HelpMessage(0) }
  ) or HelpMessage(1);

  # die unless we got the mandatory argument
  HelpMessage(1) if @ARGV < 2;

  # set values
  my $vmxFile = $ARGV[0];
  my $command =  $ARGV[1];

  # Parse command
  if ($command eq "set") {

    # Perform "set"
    if ($#ARGV < 2) {
      logErr("set: iinvalid number of arguments");
      exit(1);
    }
    # If output file not set, update source vmx file
    if ($outputFile eq "") {
      $outputFile = $vmxFile;
    }
    cmdSet($vmxFile, $outputFile, @ARGV[2..$#ARGV]);

  } elsif ($command eq "remove") {

    # Perform "remove"
    if ($#ARGV < 2) {
      logErr("remove: invalid number of arguments");
      exit(1);
    }
    # If output file not set, update source vmx file
    if ($outputFile eq "") {
      $outputFile = $vmxFile;
    }
    if ($outputFile eq "") {
      $outputFile = $vmxFile;
    }
    cmdRemove($vmxFile, $outputFile, @ARGV[2..$#ARGV]);

  } else {
    logErr("Unknown command: $command");
    HelpMessage(1);
  }
}

main();

=head1 NAME

vmx_cmd.pl - Command line tool to modify vmx files

=head1 SYNOPSIS

=head2 Set entries in vmx file

vmx_cmd.pl [OPTION] VMX_FILE set KEY_1=VALUE_1 [KEY_2=VALUE_2 ...]

=head3 Options

  -o, --output=FILENAME     Save modifed VMX_FILE as FILENAME

=head2 Remove entries from vmx file

  vmx_cmd.pl VMX_FILE remove KEY_1 [KEY_2 ...]

=head3 Options

  -o, --output=FILENAME     Save modifed VMX_FILE as FILENAME

=cut