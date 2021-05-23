#!/usr/bin/env perl

eval 'exec perl -wS $0 ${1+"$@"}'
    if 0;

use strict;
use warnings FATAL => 'uninitialized';
use 5.010; # perl v5.10 was released on December 18, 2007
use Carp ();
$SIG{__DIE__} = \&Carp::confess;

use List::Util qw{reduce};

use Data::Dumper qw(Dumper);

local $\ = "\n";

# this is NOT the same as the '//' (Logical Defined-Or, see 'perldoc
# perlop') operator
sub assign_ifdef { $_[0] = $_[1] if defined($_[1]) }

sub set_many (\%@) {
    my ($h, $k, $v) = @_;
    if (defined($h->{$k})) {
	if (ref($h->{$k}) eq 'ARRAY') {
	    push(@{ $h->{$k} }, $v);
	} else {
	    $h->{$k} = [$h->{$k}, $v];
	}
    } else {
	$h->{$k} = $v;
    }
}

sub get_many {
    # () yield undef in scalar context
    return () unless defined($_[0]);              # return () instead of (undef)
    return @{ $_[0] } if ref($_[0]) eq 'ARRAY';   # return @{arg}
    @_;                                           # return (arg)
}

sub get_first {
    (&get_many)[0];
}

sub get_last {
    (&get_many)[-1];
}

sub slurp_subprocess_lines {
    open(my $fh, '-|', @_) or die $!;
    if (wantarray) {
	my @res = map {chomp($_); $_} <$fh>;
	close($fh); # or Carp::carp "Cannot close $fh: $!";
	return @res;
    } elsif (defined(wantarray)) {
        # 'wantarray' defined but false, want scalar, see 'perldoc perlfunc'
	my $res = do {local $/; <$fh>};
	close($fh); # or Carp::carp "Cannot close $fh: $!";
	return $res;
    }
    Carp::confess 'exhaustion';
}

sub read_configuration {
    my ($config, $regex) = @_;
    my @args = (qw{git config -f}, $config, '--get-regexp', $regex);
    my %res;
    set_many(%res, split(' ', $_, 2)) for slurp_subprocess_lines(@args);
    %res;
}

my $docker_config = $ENV{'DOCKER_RUN_CONFIG'} // 'docker-run.cfg';
delete($ENV{'DOCKER_RUN_CONFIG'});

Carp::croak "Configuration file \"${docker_config}\" not found." unless -f "${docker_config}";

my %conf = read_configuration($docker_config, '^docker\.');

my $trace = get_first($conf{'docker.run.trace'});
my $debug = get_first($conf{'docker.run.debug'});

print("**************** conf\n", Dumper(\%conf)) if $trace;

my @docker_args = qw(docker run);

for my $exp (get_many($conf{'docker.run.exports'})) {
    push(@docker_args, '-v', "$conf{'docker.run.root-dir'}${exp}:${exp}");
}

for my $vol (get_many($conf{'docker.run.volumes'})) {
    push(@docker_args, '-v', "${vol}");
}

for my $env_var (get_many($conf{'docker.run.env-vars'})) {
    push(@docker_args, '-e', "${env_var}");
}

for my $dev (get_many($conf{'docker.run.devices'})) {
    push(@docker_args, '--device', "${dev}");
}

print("**************** docker args (step 1)\n", Dumper(\@docker_args)) if $trace;

my @container_args;

{
    my $a = reduce {
	if ($a->[0]) {
	    push(@{ $a->[2] }, $b);
	} elsif ($b eq '--') {
	    $a->[0] = 1; # found double slash --
	} else {
	    push(@{ $a->[1] }, $b);
	}
	$a;
    } [0,[],[]], @ARGV;
    my ($found, $a1, $a2) = @{ $a };
    #print(Dumper($found, $a1, $a2));
    if ($found) {
	push(@docker_args, @{ $a1 });
	push(@container_args, @{ $a2 });
    } else {
	push(@container_args, @{ $a1 });
    }
}

print("**************** docker args (step 2)\n", Dumper(\@docker_args)) if $trace;

{
    my %cmdline_informed;

    # command line arguments have priority
    my @queue;
    @docker_args = map {
        if (@queue) {
            # remapping arguments from previous iteration
            get_many(shift(@queue));
        } else {
            if (m{^--entrypoint}) {
                if ($_ eq '--entrypoint') {
                    print("**************** --entrypoint") if $trace;
                    # just showing how to remap arguments
                    #push(@queue, $_, '/bin/echo');
                } elsif (m{^(--entrypoint)=(.*)}) {
                    print("**************** --entrypoint= ([$1] [$2])") if $trace;
                    # just showing how to split arguments
                    push(@queue, [$1, $2]);
                } else {
                    Carp::croak "exhaustion";
                }
                $cmdline_informed{entrypoint} = 1;
            }
            if (m{^(?:--workdir|-w)}) {
                if ($_ eq '--workdir' or $_ eq '-w') {
                    print("**************** --workdir") if $trace;
                    push(@queue, '--workdir');
                } elsif (m{^(?: (--workdir)=(.*) | (-w)=(.*) )}x) {
                    print("**************** --workdir= ([" . ($1 // $3) . "] [" . ($2 // $4) . "])") if $trace;
                    push(@queue, ['--workdir', $2 // $4]);
                } else {
                    Carp::croak "exhaustion";
                }
                $cmdline_informed{workdir} = 1;
            }
            @queue ? get_many(shift(@queue)) : $_;
        }
    } @docker_args;

    unless ($ENV{'RUN_AS_ROOT'} // 0) {
	push(@docker_args, '--user', "$conf{'docker.run.uid'}:$conf{'docker.run.gid'}");
    }

    if (!defined($cmdline_informed{entrypoint})) {
	my $value = get_first($conf{'docker.run.entrypoint'});
	push(@docker_args, '--entrypoint', $value) if defined($value);
    }

    if (!defined($cmdline_informed{workdir})) {
	my $value = get_first($conf{'docker.run.workdir'});
	push(@docker_args, '--workdir', $value) if defined($value);
    }
}

print("**************** docker args (step 3-last)\n", Dumper(\@docker_args)) if $trace;

print("**************** container args\n", Dumper(\@container_args)) if $trace;
print("**************** ARGV\n", Dumper(\@ARGV)) if $trace;

my @final_args = map {
    my @res = ();
    if (ref($_) eq 'ARRAY') {
        @res = @{$_};
    } else {
        @res = ($_);
    }
    @res;
} grep {
    my $res = 1;
    if (ref($_) eq 'ARRAY') {
        my ($a0, $a1) = @{$_};
        if ($a0 eq '-e') {
            if ($a1 =~ m{[\w\-.]+=(.*)}) {
                $res = $1 ne '';
                print("ignoring [" , join(', ', @{$_}), "]") if $debug and not $res;
            }
        }
    }
    $res;
} @{
    reduce {
        my $done = 0;
        if (@{$a} and ref($a->[-1]) eq 'ARRAY') {
            my $a0 = $a->[-1][0];
            if ($a0 =~ m{^(?:-e|-v)$} && scalar(@{$a->[-1]}) == 1) {
                push(@{$a->[-1]}, $b);
                $done = 1;
            }
        }
        unless ($done) {
            if ($b =~ m{^(?:-e|-v)$}) {
                push(@{$a}, [$b]);
            } else {
                push(@{$a}, $b);
            }
        }
        $a;
    } [], (@docker_args, $conf{'docker.run.imagename'}, @container_args)
};

print("**************** final_args\n", Dumper(\@final_args)) if $debug;

exec(@final_args);
