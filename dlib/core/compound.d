/*
Copyright (c) 2011-2021 Timur Gafarov

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

/**
 * Tuple + struct hybrid
 *
 * Description:
 * This template can be used to construct data types on-the-fly 
 * and return them from functions, which cannot be done with pure tuples.
 * One possible use case for such types is returning result and error message 
 * from function instead of throwing an exception.
 *
 * Copyright: Timur Gafarov 2011-2021.
 * License: $(LINK2 htpps://boost.org/LICENSE_1_0.txt, Boost License 1.0).
 * Authors: Timur Gafarov
 */
module dlib.core.compound;

/**
 * A struct that consists of a tuple T. Allows square bracket access to the members of a tuple
 */
struct Compound(T...)
{
    T tuple;
    alias tuple this;
}

/**
 * Returns a Compound consisting of args
 */
Compound!(T) compound(T...)(T args)
{
    return Compound!(T)(args);
}

///
unittest
{
    auto c = compound(true, 0.5f, "hello");
    assert(c[0] == true);
    assert(c[1] == 0.5f);
    assert(c[2] == "hello");
}
