/** Formula parsing module. */
module intervis.formula;

struct Token {
    this(TokenType type, string symbol) {
        this.type = type;
        this.symbol = symbol;
    }

    TokenType type;
    string symbol;
}

enum TokenType {
    Unknown, // Default init value.
    Equal,
    Integer,
    Real,
    Plus,
    Minus,
    Times,
    DivideBy,
    LParen,
    RParen,
    LBrace,
    RBrace,
    Variable,
    At,
    EOF
}

/* Parser **/

struct Parser {
    import intervis.trace;

    this(Lexer lexer) { this.lexer = lexer; }

    auto parse() {
        while (! lexer.empty()) {
            currentNode = parseExpression();
        }
        return currentNode;
    }

    /* op-expression | integer | double | variable | cell-range */
    FormulaExpr parseExpression() {
        import std.conv : to;
        FormulaExpr node;

        final switch (lexer.front().type) {
            case TokenType.Unknown:
                throw new Exception("TODO: Unknown token type");
            case TokenType.Equal:
                assert(0, "Implement parse(Equal)");
            case TokenType.Integer:
                node = new Integer(lexer.front().symbol.to!long);
                break;
            case TokenType.Real:
                node = new Real(lexer.front().symbol.to!double);
                break;
            case TokenType.Plus:
                node = parseSumExpression();
                break;
            case TokenType.Minus:
                // TODO: Could also be a negative value.
                node = parseSubExpression();
                break;
            case TokenType.Times:
                node = parseMultiplyExpression();
                break;
            case TokenType.DivideBy:
                node = parseDivideExpression();
                break;
            case TokenType.LParen:
                lexer.popFront();
                FormulaExpr inner;

                auto outerCurrentNode = currentNode;
                while (! lexer.empty && lexer.front().type != TokenType.RParen) {
                    trace("lexer front: ", lexer.front().symbol);
                    currentNode = parseExpression();
                }
                node = currentNode;
                currentNode = outerCurrentNode;
                break;
            case TokenType.RParen:
                assert(0, "Unexpected ')' symbol.");
            case TokenType.LBrace:
                assert(0, "Implement parse(LBrace)");
            case TokenType.RBrace:
                assert(0, "Implement parse(RBrace)");
            case TokenType.Variable:
                assert(0, "Implement parse(Variable)");
            case TokenType.At:
                assert(0, "Implement parse(At)");
            case TokenType.EOF:
                assert(0, "Should never actually parse EOF token");
        }
        lexer.popFront();
        return node;
    }

    /* [expression] + [expression] */
    SumExpr parseSumExpression() {
        lexer.popFront();
        auto left = currentNode;
        auto right = parseExpression();
        return new SumExpr(left, right);
    }

    /* [expression] - [expression] */
    SubExpr parseSubExpression() {
        lexer.popFront();
        auto left = currentNode;
        auto right = parseExpression();
        return new SubExpr(left, right);
    }

    /* [expression] * [expression] */
    MultiplyExpr parseMultiplyExpression() {
        lexer.popFront();
        auto left = currentNode;
        auto right = parseExpression();
        return new MultiplyExpr(left, right);
    }

    /* [expression] / [expression] */
    DivideExpr parseDivideExpression() {
        lexer.popFront();
        auto left = currentNode;
        auto right = parseExpression();
        return new DivideExpr(left, right);
    }

    private:

    Lexer lexer;
    FormulaExpr currentNode;
}

class FormulaExpr {}

class Integer : FormulaExpr {
    this(long value) { this.value = value; }
    long value;
}

class Real : FormulaExpr {
    this(double value) { this.value = value; }
    double value;
}

class BinOp : FormulaExpr {
    this(FormulaExpr left, FormulaExpr right) {
        this.left = left;
        this.right = right;
    }

    FormulaExpr left;
    FormulaExpr right;
}

class SumExpr : BinOp {
    this(FormulaExpr left, FormulaExpr right) {
        super(left, right);
    }
}

class SubExpr : BinOp {
    this(FormulaExpr left, FormulaExpr right) {
        super(left, right);
    }
}

class MultiplyExpr : BinOp {
    this(FormulaExpr left, FormulaExpr right) {
        super(left, right);
    }
}

class DivideExpr : BinOp {
    this(FormulaExpr left, FormulaExpr right) {
        super(left, right);
    }
}

/* END Parser **/
/* Lexer **/

TokenType[string] tokenSymbols() {
    return [
        "=": TokenType.Equal,
        "+": TokenType.Plus,
        "-": TokenType.Minus,
        "*": TokenType.Times,
        "/": TokenType.DivideBy,
        "(": TokenType.LParen,
        ")": TokenType.RParen,
        "{": TokenType.LBrace,
        "}": TokenType.RBrace
    ];
}

/** Read a text one character at a time. */
class TextReader {
    import std.stdio : File;

    this(File file) {
        this.file = file;
        this.file.readln(buf);
    }

    this(string text) {
        buf = cast(char[])text.dup;
        text ~= cast(char)-1;
    }

    @disable this();

    @property
    char front() const { return buf[pos]; } // TODO: Assumes ASCII-compatible.

     // TODO: Assumes ASCII-compatible.
    void popFront() {
        if (pos < buf.length) ++pos;
        else {
            file.readln(buf);
            pos = 0;
        }
    }

    char moveFront() {
        char tmp = front;
        this.popFront();
        return tmp;
    }

    @property
    bool empty() {
        return buf == null || (! file.isOpen() && pos == buf.length);
    }

    // TODO: Potential range error.
    char peek(uint pos) { return buf[pos]; }

    private:
        File file;
        char[] buf;
        uint pos;
}

struct Lexer {
    this(TextReader reader, TokenType[string] tokenMap = tokenSymbols()) {
        this.reader = reader;
        this.tokenMap = tokenMap;
        this.popFront();
    }

    @disable this();

    @property
    Token front() const { return currentToken; }

    @property
    bool empty() { return currentToken.type == TokenType.EOF; }

    void popFront() {
        import std.conv : text;
        import std.uni : isAlpha, isAlphaNum, toLower, isNumber;

        skipWhitespace();
        if (reader.empty()) {
            currentToken = Token(TokenType.EOF, "");
            return;
        }

        auto frontAsString = reader.front().text;
        if (frontAsString in tokenMap) {
            // Operator/sign/other symbol.
            currentToken = Token(tokenMap[frontAsString], frontAsString);
            reader.popFront();
            return;
        } else if (reader.front().isAlpha) {
            // Keywords and identifiers (variables).
            char[] ident;
            while (! reader.empty && reader.front().isAlpha) {
                ident ~= reader.moveFront();
            }
            return;
        } else if (reader.front().isNumber) {
            char[] number;
            number ~= reader.moveFront();

            while (! reader.empty()
                    && (reader.front().isNumber
                        || reader.front() == '.'
                        || reader.front() == ',')) {
                if (reader.front() == ',') reader.popFront();
                else number ~= reader.moveFront();
            }

            bool haveSeenDecimal = false;
            for (int i = 0; i < number.length; ++i) {
                if (number[i] == '.') {
                    if (haveSeenDecimal)
                        throw new Exception("TODO: Two decimal points found");
                    haveSeenDecimal = true;
                }
            }
            currentToken =
                haveSeenDecimal ? Token(TokenType.Real, number.text)
                : Token(TokenType.Integer, number.text);
            return;
        }
    }

    Token moveFront() {
        auto tmp = front();
        popFront();
        return tmp;
    }

    private:

    TextReader reader;
    TokenType[string] tokenMap;
    Token currentToken;

    void skipWhitespace() {
        import std.uni : isWhite;
        while (! reader.empty && reader.front().isWhite) {
            reader.popFront();
        }
    }
}

/* END Lexer **/
