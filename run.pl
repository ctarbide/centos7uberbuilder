#!/usr/bin/env perl

# reference: docker-custom-run.pl

eval 'exec perl -wS $0 ${1+"$@"}'
    if 0;

use strict;
use warnings FATAL => 'uninitialized';
use 5.010; # perl v5.10 was released on December 18, 2007
use Carp ();
$SIG{__DIE__} = \&Carp::confess;

use File::Spec::Functions qw{rel2abs canonpath};
use Cwd qw{realpath getcwd};
use File::Path qw{make_path};

use List::Util qw{reduce};

use Data::Dumper qw(Dumper);

local $\ = "\n";

################

my $debug = $ENV{DEBUG} // 0;

# just to show how to specify additional groups
my $gid_wheel = $ENV{GID_WHEEL} // 10;
my $gid_users = $ENV{GID_USERS} // 100;

sub initial_shell_script {
    my @lines = ();
    push(@lines, 'set -- $0 "$@"');
    push(@lines, 'exec "$@"');
    return join("\n", @lines);
}

################

#my $thispath = canonpath(rel2abs($0));
my $thispath = realpath($0);  # resolve symbolic links
my $thisdir = do { die unless $thispath =~ m{^(.*)/.*}; $1 };
my $thisprog = do { die unless $thispath =~ m{^.*/(.*)}; $1 };

my $pwd = getcwd();
my $basename_pwd = do { die unless $pwd =~ m{^.*/(.*)}; $1 };

################

die "invalid pwd [${basename_pwd}]" if $basename_pwd !~ m{^\w[\w\-\.]{2,}$};

my $workdir = $pwd;

my $docker_network_arg = $ENV{DOCKER_NETWORK_ARG} // 'bridge';

(my $docker_config_name = slurp_subprocess_lines("${thisdir}/show-config.sh docker.run.configname")) =~ s,\s*$,,;

die unless $docker_config_name and $docker_config_name =~ m{\.cfg$};

$ENV{DOCKER_RUN_CONFIG} = "${thisdir}/${docker_config_name}";

my $docker_container_name = ($ENV{BASENAME} // "${basename_pwd}") . "$$";

my $host_home = $ENV{HOME};

my @volumes = ();

# TODO: add option to mount volumes or not

if ($ENV{HOME} and $ENV{HOME} != $pwd) {
    push(@volumes, '-v', "${host_home}:${host_home}:ro");
}

push(
    @volumes,
    '-v', "${pwd}:${workdir}",
    '-v', "/var/run/media/$ENV{USER}:/var/run/media/$ENV{USER}"
    );

my @initial_args = (
    "${thisdir}/docker-custom-run.pl",
    '--rm', '-i',
    @volumes,
    '-w', "${workdir}",
    '-e', "USER=$ENV{USER}",
    '-e', "BASENAME=${basename_pwd}",
    '--name', "${docker_container_name}",
    "--network=${docker_network_arg}",
    "--group-add=${gid_users}", "--group-add=${gid_wheel}",
    '--init'
    );

################

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

# before docker
my @bdargs = @initial_args;

# after docker
my @adargs = (qw{/bin/sh -eu -c}, initial_shell_script);

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
	push(@bdargs, @{ $a1 });
	push(@adargs, @{ $a2 });
    } else {
	push(@adargs, @{ $a1 });
    }
}

{
    my %cmdline_informed;

    # command line arguments have priority
    my @queue;
    @bdargs = map {
        if (@queue) {
            # remapping arguments from previous iteration
            get_many(shift(@queue));
        } else {
            # customize here the handling/remapping of arguments, see
            # docker-custom-run.pl for examples
            @queue ? get_many(shift(@queue)) : $_;
        }
    } @bdargs;
}

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
                print("DEBUG: ignoring [" , join(', ', @{$_}), "]") if $debug and not $res;
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
    } [], (@bdargs, '--', @adargs)
};

print("DEBUG: final_args\n", Dumper(\@final_args)) if $debug;

exec(@final_args);
