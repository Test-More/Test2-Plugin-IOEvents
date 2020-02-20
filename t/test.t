use Test2::V0;

my $events = intercept {
    require Test2::Plugin::IOEvents;
    Test2::Plugin::IOEvents->import;

    print "Hello\n";
    print STDOUT "Hello STDOUT\n";
    print STDERR "Hello STDERR\n";
    warn "Hello WARN\n";

    subtest foo => sub {
        ok(1, "assert");
        print "Hello\n";
        print STDOUT "Hello STDOUT\n";
        print STDERR "Hello STDERR\n";
        warn "Hello WARN\n";
    };
};

like(
    $events,
    [
        {info => [{tag => 'STDOUT', details => "Hello\n"}]},
        {info => [{tag => 'STDOUT', details => "Hello STDOUT\n"}]},
        {info => [{tag => 'STDERR', details => "Hello STDERR\n"}]},
        {info => [{tag => 'STDERR', details => "Hello WARN\n"}]},
        {
            subevents => [
                {}, # The assert
                {info => [{tag => 'STDOUT', details => "Hello\n"}]},
                {info => [{tag => 'STDOUT', details => "Hello STDOUT\n"}]},
                {info => [{tag => 'STDERR', details => "Hello STDERR\n"}]},
                {info => [{tag => 'STDERR', details => "Hello WARN\n"}]},
            ],
        }
    ],
    "Got the output in the right places, output from subtests is in subtests"
);

done_testing;
