/*
Copyright (c) 2011-2017 Timur Gafarov

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

module dlib.image.filters.boxblur;

private
{
    import dlib.image.color;
    import dlib.image.image;
}

SuperImage boxBlur(SuperImage img, int radius)
{
    return boxBlur(img, null, radius);
}

SuperImage boxBlur(SuperImage img, SuperImage outp, int radius)
{
    SuperImage res;
    if (outp)
        res = outp;
    else
        res = img.dup;

    immutable int boxSide = radius * 2 + 1;
    immutable int boxSide2 = boxSide * boxSide;

    foreach(y; 0..img.height)
    foreach(x; 0..img.width)
    {
        float alpha = Color4f(img[x, y]).a;

        Color4f total = Color4f(0, 0, 0);

        foreach(ky; 0..boxSide)
        foreach(kx; 0..boxSide)
        {
            int iy = y + (ky - radius);
            int ix = x + (kx - radius);

            total += img[ix, iy];
        }

        total /= boxSide2;
        total.a = alpha;

        res[x,y] = total;
        img.updateProgress();
    }

    img.resetProgress();
    return res;
}
