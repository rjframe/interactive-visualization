module unit.bijectiveb26;

import unit_threaded;

import intervis.bijectiveb26;

@("Incrementing a BijectiveB26 object yields the next single-digit value")
unittest {
    import std.conv : to;
    auto vals = "BCDEFGHIJKLMNOPQRSTUVWXYZ";
    auto b = BijectiveB26("A");

    for (auto i = 0; i < vals.length - 1; ++i) {
        ++b;
        assert(b.value == vals[i].to!dstring,
                "expected " ~ vals[i] ~ ", received " ~ b.value.to!string);
    }
}

@("Incrementing a BijectiveB2 object adds to multiple positions")
unittest {
    import std.conv : to;
    import std.range : enumerate;
    auto tests =    ["Z",  "ABZ", "AZ", "AZZ"];
    auto expected = ["AA", "ACA", "BA", "BAA"];

    foreach (num, test; tests.enumerate) {
        auto b = BijectiveB26(test.to!dstring);
        ++b;
        assert(b.value == expected[num].to!dstring,
                "expected " ~ expected[num] ~ ", received " ~ b.value.to!string);
    }
}
