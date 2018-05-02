module intervis.bijectiveb26;

import std.traits : isSomeString;

/** Represent a Bijective-Base26 number.

    Note that this is Locale-dependent and assumes UTF8.

    Bijective-base26 counts A,B,C..Z,AA,AB,AC...
*/
struct BijectiveB26 {
    this(const dchar[] val) in {
        foreach (ch; val) {
            assert(ch >= 'A' && ch <= 'Z');
        }
    } do {
        _value = val.dup;
    }

    this(const dchar val) in {
        assert(val >= 'A' && val <= 'Z');
    } do {
        _value ~= val;
    }

    auto opUnary(string op)() if (op == "++") {
        increment(value.length-1);
        return this;
    }

    @property
    auto value() { return cast(dstring)_value.dup; }

    private:

    dchar[] _value;

    void increment(int pos) {
        if (_value[pos] == 'Z') {
            _value[pos] = 'A';
            if (pos > 0) {
                increment(pos-1);
            } else {
                _value ~= 'A';
            }
        } else {
            ++_value[pos];
        }
    }
}
