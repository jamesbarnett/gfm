module gfm.math.box;

import std.math,
       std.traits;

import gfm.math.vector, 
       gfm.math.funcs;

static if( __VERSION__ < 2066 ) private enum nogc = 1;

/// N-dimensional half-open interval [a, b[.
align(1) struct Box(T, int N)
{
    align(1):
    static assert(N > 0);

    public
    {
        alias Vector!(T, N) bound_t;

        bound_t min; // not enforced, the box can have negative volume
        bound_t max;

        /// Construct a box which extends between 2 points.
        /// Boundaries: min is inside the box, max is just outside.
        @nogc this(bound_t min_, bound_t max_) pure nothrow
        {
            min = min_;
            max = max_;
        }

        static if (N == 1)
        {
            @nogc this(T min_, T max_) pure nothrow
            {
                min.x = min_;
                max.x = max_;
            }
        }

        static if (N == 2)
        {
            @nogc this(T min_x, T min_y, T max_x, T max_y) pure nothrow
            {
                min = bound_t(min_x, min_y);
                max = bound_t(max_x, max_y);
            }
        }

        static if (N == 3)
        {
            @nogc this(T min_x, T min_y, T min_z, T max_x, T max_y, T max_z) pure nothrow
            {
                min = bound_t(min_x, min_y, min_z);
                max = bound_t(max_x, max_y, max_z);
            }
        }


        @property
        {
            /// Returns: Dimensions of the box.
            @nogc bound_t size() pure const nothrow
            {
                return max - min;
            }

            /// Returns: Center of the box.
            @nogc bound_t center() pure const nothrow
            {
                return (min + max) / 2;
            }

            /// Returns: Width of the box, always applicable.
            static if (N >= 1)
            @nogc T width() pure const nothrow @property
            {
                return max.x - min.x;
            }

            /// Returns: Height of the box, if applicable.
            static if (N >= 2)
            @nogc T height() pure const nothrow @property
            {
                return max.y - min.y;
            }

            /// Returns: Depth of the box, if applicable.
            static if (N >= 3)
            @nogc T depth() pure const nothrow @property
            {
                return max.z - min.z;
            }

            /// Returns: Signed volume of the box.
            @nogc T volume() pure const nothrow
            {
                T res = 1;
                bound_t size = size();
                for(int i = 0; i < N; ++i)
                    res *= size[i];
                return res;
            }
        }

        /// Returns: true if it contains point.
        @nogc bool contains(bound_t point) pure const nothrow
        {
            assert(isSorted());
            for(int i = 0; i < N; ++i)
                if ( !(point[i] >= min[i] && point[i] < max[i]) )
                    return false;

            return true;
        }

        /// Returns: true if it contains box other.
        @nogc bool contains(Box other) pure const nothrow
        {
            assert(isSorted());
            assert(other.isSorted());

            for(int i = 0; i < N; ++i)
                if (other.min[i] >= max[i] || other.max[i] < min[i])
                    return false;
            return true;
        }

        /// Euclidean squared distance from a point.
        /// See_also: Numerical Recipes Third Edition (2007)
        @nogc double squaredDistance(bound_t point) pure const nothrow
        {
            assert(isSorted());
            double distanceSquared = 0;
            for (int i = 0; i < N; ++i)
            {
                if (point[i] < min[i])
                    distanceSquared += (point[i] - min[i]) ^^ 2;

                if (point[i] > max[i])
                    distanceSquared += (point[i] - max[i]) ^^ 2;
            }
            return distanceSquared;
        }

        /// Euclidean distance from a point.
        /// See_also: squaredDistance.
        @nogc double distance(bound_t point) pure const nothrow
        {
            return sqrt(squaredDistance(point));
        }

        /// Euclidean squared distance from another box.
        /// See_also: Numerical Recipes Third Edition (2007)
        @nogc double squaredDistance(Box o) pure const nothrow
        {
            assert(isSorted());
            assert(o.isSorted());
            double distanceSquared = 0;
            for (int i = 0; i < N; ++i)
            {
                if (o.max[i] < min[i])
                    distanceSquared += (o.max[i] - min[i]) ^^ 2;

                if (o.min[i] > max[i])
                    distanceSquared += (o.min[i] - max[i]) ^^ 2;
            }
            return distanceSquared;
        }

        /// Euclidean distance from another box.
        /// See_also: squaredDistance.
        @nogc double distance(Box o) pure const nothrow
        {
            return sqrt(squaredDistance(o));
        }

        /// Assumes sorted boxes.
        /// Returns: Intersection of two boxes.
        @nogc Box intersection(Box o) pure const nothrow
        {
            assert(isSorted());
            assert(o.isSorted());
            Box result;
            for (int i = 0; i < N; ++i)
            {
                T maxOfMins = (min.v[i] > o.min.v[i]) ? min.v[i] : o.min.v[i];
                T minOfMaxs = (max.v[i] < o.max.v[i]) ? max.v[i] : o.max.v[i];
                result.min.v[i] = maxOfMins;
                result.max.v[i] = minOfMaxs;
            }
            return result;
        }

        /// Assumes sorted boxes.
        /// Returns: true if boxes overlap.
        bool intersects(Box other)
        {
            Box inter = this.intersection(other);
            return inter.isSorted() && inter.volume() != 0;
        }

        /// Extends the area of this Box.
        @nogc Box grow(bound_t space) pure const nothrow
        {
            Box res = this;
            res.min -= space;
            res.max += space;
            return res;
        }

        /// Shrink the area of this Box. The box might became unsorted.
        @nogc Box shrink(bound_t space) pure const nothrow
        {
            return grow(-space);
        }

        /// Extends the area of this Box.
        @nogc Box grow(T space) pure const nothrow
        {
            return grow(bound_t(space));
        }

        /// Shrink the area of this Box.
        @nogc Box shrink(T space) pure const nothrow
        {
            return shrink(bound_t(space));
        }

        /// Expand the box to include point.
        @nogc Box expand(bound_t point) pure const nothrow
        {
          import vector = gfm.math.vector;
          return Box(vector.min(min, point), vector.max(max, point));
        }

        /// Returns: true if each dimension of the box is >= 0.
        @nogc bool isSorted() pure const nothrow
        {
            for(int i = 0; i < N; ++i)
            {
                if (min[i] > max[i])
                    return false;
            }
            return true;
        }

        /// Assign with another box.
        @nogc ref Box opAssign(U)(U x) nothrow if (is(typeof(x.isBox)))
        {
            static if(is(U.element_t : T))
            {
                static if(U._size == _size)
                {
                    min = x.min;
                    max = x.max;
                }
                else
                {
                    static assert(false, "no conversion between boxes with different dimensions");
                }
            }
            else
            {
                static assert(false, Format!("no conversion from %s to %s", U.element_t.stringof, element_t.stringof));
            }
            return this;
        }

        /// Returns: true if comparing equal boxes.
        @nogc bool opEquals(U)(U other) pure const nothrow if (is(U : Box))
        {
            return (min == other.min) && (max == other.max);
        }
    }

    private
    {
        enum isBox = true;
        enum _size = N;
        alias T element_t;
    }
}

/// Instanciate to use a 2D box.
template box2(T)
{
    alias Box!(T, 2) box2;
}

/// Instanciate to use a 3D box.
template box3(T)
{
    alias Box!(T, 3) box3;
}


alias box2!int box2i; /// 2D box with integer coordinates.
alias box3!int box3i; /// 3D box with integer coordinates.
alias box2!float box2f; /// 2D box with float coordinates.
alias box3!float box3f; /// 3D box with float coordinates.
alias box2!double box2d; /// 2D box with double coordinates.
alias box3!double box3d; /// 3D box with double coordinates.

unittest
{
    box2i a = box2i(1, 2, 3, 4);
    assert(a.width == 2);
    assert(a.height == 2);
    assert(a.volume == 4);
    box2i b = box2i(vec2i(1, 2), vec2i(3, 4));
    assert(a == b);
    box2i c = box2i(0, 0, 1,1);
    assert(c.contains(vec2i(0, 0)));
    assert(!c.contains(vec2i(1, 1)));
    assert(b.contains(b));
    box2i d = c.expand(vec2i(3, 3));
    assert(d.contains(vec2i(2, 2)));
}
