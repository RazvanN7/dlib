/*
Copyright (c) 2013-2014 Timur Gafarov, Martin Cejp

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

module dlib.math.matrix;

import std.math;
import std.range;
import std.format;
import std.conv;

import dlib.math.vector;
import dlib.math.utils;

/*
 * Square (NxN) matrix.
 *
 * Implementation notes:
 * - The storage order is column-major (as of 30/01/2014);
 * - Affine vector of 4x4 matrix is in the 4th column (as in OpenGL);
 * - Elements are stored in a fixed manner, so it is impossible to change
 *   matrix size once it's created;
 * - Actual data is allocated as a static array, so no references, no GC touching. 
 *   When you pass a Matrix by value, it will be safely copied;
 * - This implementation is not perfect (as for now) for dealing with really 
 *   big matrices, but ideal for smaller ones, e.g. those which are meant to be 
 *   manipulated in real-time (in game engines, rendering pipelines etc). 
 *   This limitation may (but doesn't have to) be addressed in future.
 */
struct Matrix(T, size_t N)
{
   /*
    * Return zero matrix
    */
/*
    static opCall()
    body
    {
        Matrix!(T,N) res;
        foreach (ref v; res.arrayof)
            v = 0;
        return res;
    }
*/

    static zero()
    body
    {
        Matrix!(T,N) res;
        foreach (ref v; res.arrayof)
            v = 0;
        return res;
    }

   /*
    * Return identity matrix
    */
    static identity()
    body
    {
        Matrix!(T,N) res;
        res.setIdentity();
        return res;
    }

   /*
    * Set to identity
    */
    void setIdentity()
    body
    {
        foreach(y; 0..N)
        foreach(x; 0..N)
        {
            if (y == x)
                arrayof[y * N + x] = 1;
            else
                arrayof[y * N + x] = 0;
        }
    }

   /*
    * Create matrix from array.
    * This is a convenient way to deal with arrays of "classic" layout:
    * the storage order in an array should be row-major
    */
    this(F)(F[] arr)
    in
    {
        assert (arr.length == N * N, 
            "Matrix!(T,N): wrong array length in constructor");
    }
    body
    {
        foreach (i, ref v; arrayof)
        {
            auto i2 = i / N + N * (i - N * (i / N));
            v = arr[i2];
        }
    }
    
   /* 
    * T = Matrix[i, j]
    */
    T opIndex(in size_t i, in size_t j) const
    body
    {
        return arrayof[j * N + i];
    }
    
   /* 
    * Matrix[i, j] = T
    */
    T opIndexAssign(in T t, in size_t i, in size_t j)
    body
    {
        return (arrayof[j * N + i] = t);
    }
    
   /* 
    * T = Matrix[index]
    * Indices start with 0
    */
    T opIndex(in size_t index) const
    in
    {
        assert ((0 <= index) && (index < N * N), 
            "Matrix.opIndex(int index): array index out of bounds");
    }
    body
    {
        return arrayof[index];
    }
    
   /*
    * Matrix[index] = T
    * Indices start with 0
    */
    T opIndexAssign(in T t, in size_t index)
    in
    {
        assert ((0 <= index) && (index < N * N), 
            "Matrix.opIndexAssign(T t, int index): array index out of bounds");
    }
    body
    {
        return (arrayof[index] = t);
    }

   /*
    * Matrix4x4!(T)[index1..index2] = T
    */
    T[] opSliceAssign(in T t, in size_t index1, in size_t index2)
    in
    {
        assert ((0 <= index1) && (index1 < N) && (0 <= index2) && (index2 < N), 
            "Matrix.opSliceAssign(T t, int index1, int index2): array index out of bounds");
    }
    body
    {
        return (arrayof[index1..index2] = t);
    }

   /* 
    * Matrix[] = T
    */
    T[] opSliceAssign(in T t)
    body
    {
        return (arrayof[] = t);
    }

   /*
    * Matrix + Matrix
    */
    Matrix!(T,N) opAdd (Matrix!(T,N) mat)
    body
    {
        auto res = Matrix!(T,N)();
        foreach (i; 0..N)
        foreach (j; 0..N)
        {
            res[i, j] = this[i, j] + mat[i, j];
        }
        return res;
    }

   /*
    * Matrix - Matrix
    */
    Matrix!(T,N) opSub (Matrix!(T,N) mat)
    body
    {
        auto res = Matrix!(T,N)();
        foreach (i; 0..N)
        foreach (j; 0..N)
        {
            res[i, j] = this[i, j] + mat[i, j];
        }
        return res;
    }

   /*
    * Matrix * Matrix
    */
    Matrix!(T,N) opMul (Matrix!(T,N) mat)
    body
    {
        static if (N == 2)
        {
            Matrix!(T,N) res;
            res.a11 = (a11 * mat.a11) + (a12 * mat.a21);
            res.a12 = (a11 * mat.a12) + (a12 * mat.a22);
            res.a21 = (a21 * mat.a11) + (a22 * mat.a21);
            res.a22 = (a21 * mat.a12) + (a22 * mat.a22);
            return res;
        }
        else
        {
            auto res = Matrix!(T,N)();

            foreach (i; 0..N)
            foreach (j; 0..N)
            {
                T sumProduct = 0;
                foreach (k; 0..N)
                    sumProduct += this[i, k] * mat[k, j];
                res[i, j] = sumProduct;
            }

            return res;
        }
    }

   /*
    * Matrix += Matrix
    */
    Matrix!(T,N) opAddAssign (Matrix!(T,N) mat)
    body
    {
        this = this + mat;
        return this;
    }

   /*
    * Matrix -= Matrix
    */
    Matrix!(T,N) opSubAssign (Matrix!(T,N) mat)
    body
    {
        this = this - mat;
        return this;
    }

   /*
    * Matrix *= Matrix
    */
    Matrix!(T,N) opMulAssign (Matrix!(T,N) mat)
    body
    {
        this = this * mat;
        return this;
    }

   /*
    * Matrix * T
    */
    Matrix!(T,N) opMul (T k)
    body
    {
        auto res = Matrix!(T,N)();
        foreach(i, v; arrayof)
            res.arrayof[i] = v * k;
        return res;
    }

   /*
    * Matrix *= T
    */
    Matrix!(T,N) opMulAssign (T k)
    body
    {
        foreach(ref v; arrayof)
            v *= k;
        return this;
    }

   /*
    * Multiply column vector by the matrix
    */
    static if (N == 2)
    {
        Vector!(T,2) opBinaryRight(string op) (Vector!(T,2) v) if (op == "*")
        body
        {
            return Vector!(T,2) 
            (
                (v.x * a11) + (v.y * a12),
                (v.x * a21) + (v.y * a22)
            );
        }
    }
    else
    static if (N == 3)
    {
        Vector!(T,3) opBinaryRight(string op) (Vector!(T,3) v) if (op == "*")
        body
        {
            return Vector!(T,3) 
            (
                (v.x * a11) + (v.y * a12) + (v.z * a13),
                (v.x * a21) + (v.y * a22) + (v.z * a23),
                (v.x * a31) + (v.y * a32) + (v.z * a33)
            );
        }
    }
    else
    {
        Vector!(T,N) opBinaryRight(string op) (Vector!(T,N) v) if (op == "*")
        body
        {
            Vector!(T,N) res;
            foreach(x; 0..N)
            {
                T n = 0;
                foreach(y; 0..N)
                    n += v.arrayof[y] * arrayof[y * N + x];
                res.arrayof[x] = n;
            }
            return res;
        }
    }

   /*
    * Multiply column 3D vector by the affine 4x4 matrix
    */
    static if (N == 4)
    {
        Vector!(T,3) opBinaryRight(string op) (Vector!(T,3) v) if (op == "*")
        body
        {
            if (isAffine)
            {
                return Vector!(T,3) 
                (
                    (v.x * a11) + (v.y * a12) + (v.z * a13) + a14,
                    (v.x * a21) + (v.y * a22) + (v.z * a23) + a24,
                    (v.x * a31) + (v.y * a32) + (v.z * a33) + a34
                );
            }
            else
                assert(0, "Cannot multiply Vector!(T,3) by non-affine Matrix!(T,4)");
        }
    }

    static if (N == 3 || N == 4)
    {
       /*
        * Rotate a vector by the 3x3 upper-left portion of the matrix
        */
        Vector!(T,3) rotate(Vector!(T,3) v) 
        body
        {
            return Vector!(T,3) 
            (
                (v.x * a11) + (v.y * a12) + (v.z * a13),
                (v.x * a21) + (v.y * a22) + (v.z * a23),
                (v.x * a31) + (v.y * a32) + (v.z * a33)
            );
        }
        
       /*
        * Rotate a vector by the inverse 3x3 upper-left portion of the matrix
        */
        Vector!(T,3) invRotate(Vector!(T,3) v)
        body
        {
            return Vector!(T,3) 
            (
                (v.x * a11) + (v.y * a21) + (v.z * a31),
                (v.x * a12) + (v.y * a22) + (v.z * a32),
                (v.x * a13) + (v.y * a23) + (v.z * a33)
            );
        }
    }

   /* 
    * Determinant of an upper-left 3x3 portion
    */
    static if (N == 4 || N == 3)
    {
        T determinant3x3()
        body
        {
            return a11 * (a33 * a22 - a32 * a23)
                 - a21 * (a33 * a12 - a32 * a13)
                 + a31 * (a23 * a12 - a22 * a13);
        }
    }

   /* 
    * Determinant
    */
    static if (N == 1)
    {
        T determinant()
        body
        {
            return a11;
        }
    }
    else
    static if (N == 2)
    {
        T determinant()
        body
        {
            return a11 * a22 - a12 * a21;
        }
    }
    else 
    static if (N == 3)
    {
        alias determinant3x3 determinant;
    }
    else
    {
       /* 
        * Determinant of a given upper-left portion
        */
        T determinant(size_t n = N)
        body
        {
            T d = 0;

            if (n == 1)
                d = this[0,0];
            else if (n == 2)
                d = this[0,0] * this[1,1] - this[1,0] * this[0,1];
            else
            {
                auto submat = Matrix!(T,N)();

                for (uint c = 0; c < n; c++)
                {
                    uint subi = 0;
                    for (uint i = 1; i < n; i++)
                    {
                        uint subj = 0;
                        for (uint j = 0; j < n; j++)
                        {
                            if (j == c)
                                continue;
                            submat[subi, subj] = this[i, j];
                            subj++;
                        }
                        subi++;
                    }

                    d += pow(-1, c + 2.0) * this[0, c] * submat.determinant(n-1);
                }
            }

            return d;
        }
    }

    alias determinant det;

   /*
    * Return true if matrix is singular
    */
    bool isSingular() @property
    body
    {
        return (determinant == 0);
    }

    alias isSingular singular;

   /* 
    * Check if matrix represents affine transformation
    */
    static if (N == 4)
    {
        bool isAffine() @property
        body
        {
            return (a41 == 0.0  
                 && a42 == 0.0
                 && a43 == 0.0
                 && a44 == 1.0);
        }

        alias isAffine affine;
    }

   /*
    * Transpose
    */
    void transpose()
    body
    {
        this = transposed;
    }

   /*
    * Return the transposed matrix
    */
    Matrix!(T,N) transposed() @property
    body
    {
        Matrix!(T,N) res;

        foreach(y; 0..N)
        foreach(x; 0..N)
            res.arrayof[y * N + x] = arrayof[x * N + y];

        return res;
    }

   /*
    * Invert
    */
    void invert()
    body
    {
        this = inverse;
    }

   /* 
    * Inverse of a matrix
    */
    static if (N == 1)
    {
        Matrix!(T,N) inverse() @property
        body
        {
            Matrix!(T,N) res;
            res.a11 = 1.0 / a11;
            return res;
        }
    }
    else
    static if (N == 2)
    {
        Matrix!(T,N) inverse() @property
        body
        {
            Matrix!(T,N) res;

            T invd = 1.0 / (a11 * a22 - a12 * a21);
            
            res.a11 =  a22 * invd;
            res.a12 = -a12 * invd;
            res.a22 =  a11 * invd;
            res.a21 = -a21 * invd;

            return res;
        }
    }
    else
    static if (N == 3)
    {
        Matrix!(T,N) inverse() @property
        body
        {
            T d = determinant;
        
            T oneOverDet = 1.0 / d;
        
            Matrix!(T,N) res;
        
            res.a11 =  (a33 * a22 - a32 * a23) * oneOverDet;
            res.a12 = -(a33 * a12 - a32 * a13) * oneOverDet;
            res.a13 =  (a23 * a12 - a22 * a13) * oneOverDet;
        
            res.a21 = -(a33 * a21 - a31 * a23) * oneOverDet;
            res.a22 =  (a33 * a11 - a31 * a13) * oneOverDet;
            res.a23 = -(a23 * a11 - a21 * a13) * oneOverDet;
        
            res.a31 =  (a32 * a21 - a31 * a22) * oneOverDet;
            res.a32 = -(a32 * a11 - a31 * a12) * oneOverDet;
            res.a33 =  (a22 * a11 - a21 * a12) * oneOverDet;
        
            return res;
        }
    }
    else
    {
/+
        // This is broken
        static if (N == 4)
        {
           /* 
            * Inverse of a 4x4 affine matrix is a special case
            */
            Matrix!(T,N) inverseAffine() @property
            body
            {
                T d = determinant3x3;
                //assert (fabs(det) > 0.000001);

                T oneOverDet = 1.0 / d;

                auto res = Matrix!(T,N).identity;

                res.a11 = ((a22 * a33) - (a32 * a23)) * oneOverDet;
                res.a21 = ((a31 * a23) - (a21 * a33)) * oneOverDet;
                res.a31 = ((a21 * a32) - (a31 * a22)) * oneOverDet;

                res.a12 = ((a32 * a13) - (a21 * a33)) * oneOverDet;
                res.a22 = ((a11 * a33) - (a31 * a13)) * oneOverDet;
                res.a32 = ((a31 * a12) - (a11 * a32)) * oneOverDet;

                res.a13 = ((a12 * a23) - (a22 * a13)) * oneOverDet;
                res.a23 = ((a21 * a13) - (a11 * a23)) * oneOverDet;
                res.a33 = ((a11 * a22) - (a21 * a12)) * oneOverDet;
      
                res.a14 = -((a14 * res.a11) + (a24 * res.a12) + (a34 * res.a13));
                res.a24 = -((a14 * res.a21) + (a24 * res.a22) + (a34 * res.a23));
                res.a34 = -((a14 * res.a31) + (a24 * res.a32) + (a34 * res.a33));

                res.a44 = 1;

                return res;
            }
        }
+/

        Matrix!(T,N) inverse() @property
        body
        {
            Matrix!(T,N) res;

            // Analytical inversion
            enum inv = q{{
                res = adjugate;
                T oneOverDet = 1.0 / determinant;
                foreach(ref v; res.arrayof)
                    v *= oneOverDet;
            }};

            mixin(inv);

            static if (N == 4)
            {
                if (affine)
                {
                    res.a41 = res.a42 = res.a43 = 0.0;
                    res.a44 = 1.0;
                }
            }

/*
            // Affine version is broken
            static if (N == 4)
            {
                if (affine)
                    return inverseAffine;
                else
                    mixin(inv);
            }
            else
                mixin(inv);
*/

            return res;
        }
    }

   /*
    * Adjugate and cofactor matrices
    */
    static if (N == 1)
    {
        Matrix!(T,N) adjugate() @property
        body
        {
            Matrix!(T,N) res;
            res.arrayof[0] = 1;
            return res;
        }

        Matrix!(T,N) cofactor() @property
        {
            Matrix!(T,N) res;
            res.arrayof[0] = 1;
            return res;
        }
    }
    else
    static if (N == 2)
    {
        Matrix!(T,N) adjugate() @property
        body
        {
            Matrix!(T,N) res;
            res.arrayof[0] =  arrayof[3];
            res.arrayof[1] = -arrayof[1];
            res.arrayof[2] = -arrayof[2];
            res.arrayof[3] =  arrayof[0];
            return res;
        }

        Matrix!(T,N) cofactor() @property
        {
            Matrix!(T,N) res;
            res.arrayof[0] =  arrayof[3];
            res.arrayof[1] = -arrayof[2];
            res.arrayof[2] = -arrayof[1];
            res.arrayof[3] =  arrayof[0];
            return res;
        }
    }
    else
    {
        Matrix!(T,N) adjugate() @property
        body
        {
            return cofactor.transposed;
        }

        Matrix!(T,N) cofactor() @property
        body
        {
            Matrix!(T,N) res;

            foreach(y; 0..N)
            foreach(x; 0..N)
            {
                auto submat = Matrix!(T,N-1)();

                uint suby = 0;
                foreach(yy; 0..N) 
                if (yy != y)
                {
                    uint subx = 0;
                    foreach(xx; 0..N)
                    if (xx != x)
                    {
                        submat[subx, suby] = this[xx, yy];
                        subx++;
                    }
                    suby++;
                }

                res[x, y] = submat.determinant * (((x + y) % 2)? -1:1);
            }

            return res;
        }
    }

   /*
    * Negative matrix
    */
    Matrix!(T,N) negative() @property
    body
    {
        return this * -1;
    }
    
   /*
    * Convert to string
    * TODO: proper indentation/alignment?
    */
    string toString() @property
    body
    {
        auto writer = appender!string();
        foreach (x; 0..N)
        {
            formattedWrite(writer, "[");
            foreach (y; 0..N)
            {
                formattedWrite(writer, "%s", arrayof[y * N + x]);
                if (y < N-1)
                    formattedWrite(writer, ", ");
            }
            formattedWrite(writer, "]");
            if (x < N-1)
                formattedWrite(writer, "\n");
        }
        return writer.data;
    }
    
   /*
    * Symbolic element access
    */
    private static string elements(string letter) @property
    body
    {
        string res;
        foreach (x; 0..N)
        foreach (y; 0..N)
        {
            res ~= "T " ~ letter ~ to!string(y+1) ~ to!string(x+1) ~ ";";
        }
        return res;
    }

   /*
    * Row/column manipulations 
    */
    Vector!(T,N) getRow(size_t i)
    {
        Vector!(T,N) res;
        for (size_t j = 0; j < N; j++)
            res.arrayof[j] = this[i, j];
        return res;
    }

    void setRow(size_t i, Vector!(T,N) v)
    {
        for (size_t j = 0; j < N; j++)
            this[i, j] = v.arrayof[j];
    }

    Vector!(T,N) getColumn(size_t j)
    {
        Vector!(T,N) res;
        for (size_t i = 0; i < N; i++)
            res.arrayof[i] = this[i, j];
        return res;
    }

    void setColumn(size_t j, Vector!(T,N) v)
    {
        for (size_t i = 0; i < N; i++)
            this[i, j] = v.arrayof[i];
    }

    void swapRows(size_t r1, size_t r2)
    {
        for (size_t j = 0; j < N; j++)
        {
            T t = this[r1, j];
            this[r1, j] = this[r2, j];
            this[r2, j] = t;
        }
    }

    void swapColumns(size_t c1, size_t c2)
    {
        for (size_t i = 0; i < N; i++)
        {
            T t = this[i, c1];
            this[i, c1] = this[i, c2];
            this[i, c2] = t;
        }
    }

   /* 
    * Matrix elements
    */
    union 
    {
       /*
        * This auto-generated structure provides symbolic access
        * to matrix elements, nearly like as in standard mathematic
        * notation:
        *
        *  a11 a12 a13 a14 .. a1N
        *  a21 a22 a23 a24 .. a2N
        *  a31 a32 a33 a34 .. a3N
        *  a41 a42 a43 a44 .. a4N
        *   :   :   :   :  .
        *  aN1 aN2 aN3 aN4  ' aNN
        */
        struct { mixin(elements("a")); }

       /* 
        * Linear array representing elements column by column
        */
        T[N * N] arrayof;
    }
}

/*
 * Predefined matrix type aliases
 */
alias Matrix!(float, 2) Matrix2x2f, Matrix2f;
alias Matrix!(float, 3) Matrix3x3f, Matrix3f;
alias Matrix!(float, 4) Matrix4x4f, Matrix4f;
alias Matrix!(double, 2) Matrix2x2d, Matrix2d;
alias Matrix!(double, 3) Matrix3x3d, Matrix3d;
alias Matrix!(double, 4) Matrix4x4d, Matrix4d;

/*
 * Return identity matrix
 * (deprecated, use Matrix!(T,N).identity instead)
 */
deprecated("identityMatrix* functions are deprecated, use Matrix!(T,N).identity instead")
{
    Matrix!(T,2) identityMatrix2(T) ()
    body
    {
        return Matrix!(T,2).identity;
    }

    Matrix!(T,3) identityMatrix3(T) ()
    body
    {
        return Matrix!(T,3).identity;
    }

    Matrix!(T,4) identityMatrix4(T) ()
    body
    {
        return Matrix!(T,4).identity;
    }

    alias identityMatrix2!(float) identityMatrix2f;
    alias identityMatrix2!(double) identityMatrix2d;

    alias identityMatrix3!(float) identityMatrix3f;
    alias identityMatrix3!(double) identityMatrix3d;

    alias identityMatrix4!(float) identityMatrix4f;
    alias identityMatrix4!(double) identityMatrix4d;

    alias identityMatrix2x2f = identityMatrix2f;
    alias identityMatrix2x2d = identityMatrix2d;

    alias identityMatrix3x3f = identityMatrix3f;
    alias identityMatrix3x3d = identityMatrix3d;

    alias identityMatrix4x4f = identityMatrix4f;
    alias identityMatrix4x4d = identityMatrix4d;
}

/*
 * Matrix factory function
 */
auto matrixf(A...)(A arr)
{
    static assert(isPerfectSquare(arr.length),
        "matrixf(A): input array length is not perfect square integer");
    return Matrix!(float, cast(size_t)sqrt(cast(float)arr.length))([arr]);
}

/*
 * Conversions between 3x3 and 4x4 matrices.
 * 4x4 matrix defaults to identity
 */
Matrix!(T,4) matrix3x3to4x4(T) (Matrix!(T,3) m)
{
    auto res = Matrix!(T,4).identity;
    res.a11 = m.a11; res.a12 = m.a12; res.a13 = m.a13;
    res.a21 = m.a21; res.a22 = m.a22; res.a23 = m.a23;
    res.a31 = m.a31; res.a32 = m.a32; res.a33 = m.a33;
    return res;
}

Matrix!(T,3) matrix4x4to3x3(T) (Matrix!(T,4) m)
{
    auto res = Matrix!(T,3).identity;
    res.a11 = m.a11; res.a12 = m.a12; res.a13 = m.a13;
    res.a21 = m.a21; res.a22 = m.a22; res.a23 = m.a23;
    res.a31 = m.a31; res.a32 = m.a32; res.a33 = m.a33;
    return res;
}

unittest
{
    auto m1 = matrixf(
        1, 2, 0, 6,
        4, 6, 3, 1,
        2, 7, 8, 2,
        0, 5, 2, 1
    );
    auto m2 = matrixf(
        0, 3, 7, 1,
        1, 0, 2, 5,
        1, 9, 2, 6,
        5, 2, 0, 0
    );
    assert(m1 * m2 == matrixf(
        32, 15, 11, 11,
        14, 41, 46, 52,
        25, 82, 44, 85,
        12, 20, 14, 37)
    );
    
    auto m3 = Matrix4f.identity;
    assert(m3 == matrixf(
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1)
    );
    
    m3.a14 = 1;
    m3.a24 = 2;
    m3.a34 = 3;
    
    /*
    // This will compile, but fail to link for some wierd reason
    auto v = Vector3f(2.0f, 4.0f, 6.0f);
    assert(Vector3f(1.0f, 2.0f, 3.0f) * m3 == v);
    */
    
    assert(m1.determinant3x3 == -25);
    assert(m1.determinant == 567);

    assert(m1.singular == false);

    assert(m1.affine == false);
    assert(m3.affine == true);
    
    assert(m1.transposed == matrixf(
        1, 4, 2, 0,
        2, 6, 7, 5,
        0, 3, 8, 2,
        6, 1, 2, 1)
    );
    
    auto m4 = matrixf(
        0, 3, 2,
        1, 0, 8,
        0, 1, 0
    );

    assert(m4.inverse == matrixf(
        -4,   1, 12,
        -0,   0,  1,
         0.5, 0, -1.5)
    );

    assert(m1.cofactor == matrixf(
        7, -14, -14,  98,
      148,  28, -53, -34,
      -16, -49, 113,  19,
     -158, 154, -89, -25)
    );
}
