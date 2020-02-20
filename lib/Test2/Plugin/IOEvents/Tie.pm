package Test2::Plugin::IOEvents::Tie;
use strict;
use warnings;

our $VERSION = '0.000001';

use Test2::API qw/context/;
use Carp qw/croak/;

my $IS_END;
END { $IS_END = 1 };

sub TIEHANDLE {
    my $class = shift;
    my ($name) = @_;

    my ($fh, $fn);
    if ($name eq 'STDOUT') {
        ($fn, $fh) = _move_io_fd(\*STDOUT);
    }
    elsif ($name eq 'STDERR') {
        ($fn, $fh) = _move_io_fd(\*STDERR);
    }
    else {
        croak "Invalid name: $name\n";
    }

    return bless([$name, $fh, $fn], $class);
}

sub DESTROY {
    my $self = shift;
    my ($name, $fh, $fn) = @$self;

    return if $IS_END;

    if ($name eq 'STDOUT') {
        _move_io_fd($fh, \*STDOUT);
    }
    else {
        _move_io_fd($fh, \*STDERR);
    }
}

sub _move_io_fd {
    my ($from, $to) = @_;

    my $fn = fileno($from);
    open(my $tempfh, '>&', $from) or die "$!";
    close($from) or die "$!";
    open($to, '>&', $tempfh) or die "$!";
    die "fileno mismatch!" unless $fn == fileno($to);

    return ($fn, $to);
}

sub PRINT {
    my $self = shift;
    my ($name, $fh) = @$self;

    my $output = defined($,) ? join( $,, @_) : join('', @_);

    return unless length($output);

    my $ctx = context();
    $ctx->send_ev2_and_release(
        info => [
            {tag => $name, details => $output, $name eq 'STDERR' ? (debug => 1) : ()},
        ]
    );
}

sub FILENO {
    my $self = shift;
    return $self->[2];
}

sub PRINTF {
    my $self = shift;
    my ($format, @list) = @_;
    my ($name, $fh) = @$self;

    my $output = sprintf($format, @list);
    return unless length($output);

    my $ctx = context();
    $ctx->send_ev2_and_release(
        info => [
            {tag => $name, details => $output, $name eq 'STDERR' ? (debug => 1) : ()},
        ]
    );
}

sub CLOSE {
    return 1;
    close($_[0]->[1]) if $_[0]->[1];
    $_[0]->[2] = undef;
}

sub WRITE {
    my $self = shift;
    my ($buf, $len, $offset) = @_;
    return syswrite($self->[1], $buf) if @_ == 1;
    return syswrite($self->[1], $buf, $len) if @_ == 2;
    return syswrite($self->[1], $buf, $len, $offset);
}

sub BINMODE {
    my $self = shift;
    return binmode($self->[1]) unless @_;
    return binmode($self->[1], $_[0]);
}

sub autoflush { $_->[1]->autoflush(@_ ? @_ : ()) }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test2::Plugin::IOEvents::Tie - Tie handler for Test2::Plugin::IOEvents

=head1 SOURCE

The source code repository for Test2-Harness can be found at
F<http://github.com/Test-More/Test2-Harness/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2020 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
