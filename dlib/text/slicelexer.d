/*
Copyright (c) 2016-2017 Timur Gafarov, Roman Chistokhodov

Boost Software License - Version 1.0 - August 17th, 2003

Permission is hereby granted, free of charge, to any person or organization
obtaining a copy of the software and accompanying documentation covered by
this license (the "Software") to use, reproduce, display, distribute,
execute, and transmit the Software, and to prepare derivative works of the
Software, and to permit third-parties to whom the Software is furnished to
do so, all subject to the following:

The copyright notices in the Software and this entire statement, including
the above license grant, this restriction and the following disclaimer,
must be included in all copies of the Software, in whole or in part, and
all derivative works of the Software, unless such copies or derivative
works are solely in the form of machine-executable object code generated by
a source language processor.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE, TITLE AND NON-INFRINGEMENT. IN NO EVENT
SHALL THE COPYRIGHT HOLDERS OR ANYONE DISTRIBUTING THE SOFTWARE BE LIABLE
FOR ANY DAMAGES OR OTHER LIABILITY, WHETHER IN CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
*/

module dlib.text.slicelexer;

import std.stdio;
import std.algorithm;
import std.ascii;
import std.range.interfaces;

import dlib.text.utf8;

struct LexerDecoder
{
    UTF8Decoder dec;
    dchar current;
    size_t index;
    size_t currentSize;

    this(string s)
    {
        dec = UTF8Decoder(s);
    }

    void advance()
    {
        index = dec.index;
        current = dec.decodeNext();
        currentSize = dec.index - index;
    }

    size_t forwardLookup(size_t numChars)
    {
        size_t oldIndex = dec.index;
        for(size_t i = 0; i < numChars; i++)
        {
            dec.decodeNext();
        }
        size_t res = dec.index;
        dec.index = oldIndex;
        return res;
    }

    void forwardJump(size_t numChars)
    {
        for(size_t i = 0; i < numChars; i++)
        {
            advance();
        }
    }
}

/**
 * General-purpose non-allocating lexical analyzer.
 * Breaks the input string to a stream of lexemes according to a given delimiter dictionary.
 * Delimiters are symbols that separate sequences of characters (e.g. operators).
 * Lexemes are slices of the input string.
 * Assumes UTF-8 input.
 * Treats \r\n as a single \n.
 */
class SliceLexer: InputRange!string
{
    public:
    bool ignoreWhitespaces = false;
    bool ignoreNewlines = false;

    private:
    string input;
    string[] delims;
    size_t maxDelimSize = 0;
    LexerDecoder dec;

    public:
    this(string input, string[] delims)
    {
        this.input = input;
        this.delims = delims;

        if (this.delims.length)
        {
            sort!("count(a) < count(b)")(this.delims);
            maxDelimSize = this.delims[$-1].length;
        }

        this.dec = LexerDecoder(this.input);
        dec.advance();
    }

    string getLexeme()
    {
        size_t startPos, endPos;

        startPos = dec.index;

        if (startPos == input.length)
            return "";

        dchar c = dec.current;

        if (isNewline(c)) // read newlines
        {
            if (ignoreNewlines)
            {
                while (isNewline(c))
                {
                    dec.advance();
                    c = dec.current;
                    if (c == UTF8_END || c == UTF8_ERROR)
                        return "";
                }

                startPos = dec.index;

                // Don't return, continue lexing
            }
            else
            {
                if (c == '\r')
                {
                    dec.advance();
                    c = dec.current;
                    if (c == '\n')
                        dec.advance();
                }
                else
                {
                    dec.advance();
                }

                return "\n";
            }
        }

        if (isWhitespace(c)) // read spaces and tabs
        {
            if (ignoreWhitespaces)
            {
                while (isWhitespace(c))
                {
                    dec.advance();
                    c = dec.current;
                    if (c == UTF8_END || c == UTF8_ERROR)
                        return "";
                }

                startPos = dec.index;

                // Don't return, continue lexing
            }
            else
            {
                dec.advance();
                return " ";
            }
        }

        if (isText(c)) // read non-delimiter
        {
            while (isText(c))
            {
                dec.advance();
                c = dec.current;
                if (c == UTF8_END || c == UTF8_ERROR)
                    break;
            }

            return input[startPos..dec.index];
        }
        else // read delimiter
        {
            string bestStr = "";
            LexerDecoder decCopy = dec;
            while(true)
            {
                dec.advance();
                c = dec.current;

                string str = input[startPos..dec.index];

                if (isDelim(str))
                {
                    if (str.length > bestStr.length)
                    {
                        bestStr = str;
                    }
                }

                if (c == UTF8_END || c == UTF8_ERROR)
                    break;

                if (str.length == maxDelimSize)
                    break;
            }

            dec = decCopy;
            dec.forwardJump(count(bestStr));

            return bestStr;
        }
    }

    private:

    bool isText(dchar c)
    {
        return (!isDelimPrefix(c) && !isWhitespace(c) && !isNewline(c));
    }

    bool isDelimPrefix(dchar c)
    {
        foreach(d; delims)
        {
            auto dec = UTF8Decoder(d);
            if (dec.decodeNext == c)
                return true;
        }
        return false;
    }

    bool isDelim(string delim)
    {
        foreach(d; delims)
        {
            if (d[] == delim[])
                return true;
        }
        return false;
    }

    bool isWhitespace(dchar c)
    {
        foreach(w; std.ascii.whitespace)
        {
            if (c == w)
            {
                return true;
            }
        }
        return false;
    }

    bool isNewline(dchar c)
    {
        return (c == '\n' || c == '\r');
    }

    // Range interface

    private:

    string _front;

    public:

    bool empty()
    {
        return _front.length == 0;
    }

    string front()
    {
        return _front;
    }

    void popFront()
    {
        _front = getLexeme();
    }

    string moveFront()
    {
        _front = getLexeme();
        return _front;
    }

    int opApply(scope int delegate(string) dg)
    {
        int result = 0;

        while(true)
        {
            string lexeme = getLexeme();

            if (!lexeme.length)
                break;

            result = dg(lexeme);
            if (result)
                break;
        }

        return result;
    }

    int opApply(scope int delegate(size_t, string) dg)
    {
        int result = 0;
        size_t i = 0;

        while(true)
        {
            string lexeme = getLexeme();

            if (!lexeme.length)
                break;

            result = dg(i, lexeme);
            if (result)
                break;

            i++;
        }

        return result;
    }
}

unittest
{
    string[] delims = ["(", ")", ";", " ", "{", "}", ".", "\n", "\r", "=", "++", "<"];
    auto input = "for (int i=0; i<arr.length; ++i)\r\n{doThing();}\n";
    auto lexer = new SliceLexer(input, delims);

    string[] arr;
    while(true) {
        auto lexeme = lexer.getLexeme();
        if(lexeme.length == 0) {
            break;
        }
        arr ~= lexeme;
    }
    assert(arr == [
        "for", " ", "(", "int", " ", "i", "=", "0", ";", " ", "i", "<",
        "arr", ".", "length", ";", " ", "++", "i", ")", "\n", "{", "doThing",
        "(", ")", ";", "}", "\n" ]);

    input = "";
    lexer = new SliceLexer(input, delims);
    assert(lexer.getLexeme().length == 0);
}
