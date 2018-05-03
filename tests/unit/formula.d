/** Tests for intervis.formula - Formula grammar and parsing module. */
module unit.formula;

import std.conv : text, to;
import unit_threaded;

import intervis.formula;

@("Parse values")
unittest {
    auto Lexer = Lexer(new TextReader("1 1.23"));
    auto parser = Parser(Lexer);

    auto node = parser.parse();
    assert(is(Integer : typeof(node)));
    assert((cast(Integer)node).value == 1);

    node = parser.parse();
    assert(is(Real : typeof(node)));
    assert((cast(Real)node).value == 1.23);
}

@("The TextReader reads one character at a time")
unittest {
    auto text = "some\ntext here.\n";
    auto reader = new TextReader(text);

    for (int i = 0; i < text.length; ++i) {
        assert(reader.moveFront == text[i]);
    }
}

@("Lex keywords and reserved symbols")
unittest {
    foreach (tokenStr, tokenType; tokenSymbols()) {
        auto reader = new TextReader(tokenStr);
        auto tokens = Lexer(reader);

        auto expected = Token(tokenType, tokenStr);
        assert(tokens.front == expected,
                "expected: " ~ tokenStr ~ ", actual: " ~ tokens.front.symbol);
    }
}

@("Lex integral numbers")
unittest {
    auto text = "32 6540";
    auto reader = new TextReader(text);
    auto tokens = Lexer(reader);

    assert(tokens.moveFront() == Token(TokenType.Integer, "32"),
            tokens.front().symbol);
    assert(tokens.front() == Token(TokenType.Integer, "6540"),
            tokens.front.symbol);
}

@("Lex real numbers")
unittest {
    auto text = "32.0 6540.9";
    auto reader = new TextReader(text);
    auto tokens = Lexer(reader);

    assert(tokens.moveFront() == Token(TokenType.Real, "32.0"),
            tokens.front.symbol);
    assert(tokens.front() == Token(TokenType.Real, "6540.9"),
            tokens.front.symbol);
}

@("Multiple decimal points in a number is a lexing error")
unittest {
    import std.exception : assertThrown;
    auto text = "1.2.3";
    auto reader = new TextReader(text);

    assertThrown(Lexer(reader));
}

@("Lexing numbers ignores commas")
unittest {
    auto text = "32,000 6,5,4,0";
    auto reader = new TextReader(text);
    auto tokens = Lexer(reader);

    assert(tokens.moveFront() == Token(TokenType.Integer, "32000"),
            tokens.front().symbol);
    assert(tokens.moveFront() == Token(TokenType.Integer, "6540"),
            tokens.front.symbol);
}
