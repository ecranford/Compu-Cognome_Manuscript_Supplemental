Profiling showed that bignums were the plurality of the space used, and one
of the most frequent places bignums show up is in chunks and chunk-types to
test slot usage, existance, etc. and the operators on those all generate a
new bignum everytime.

This was an attempt to replace those bignums with bit-vectors because they
can be destructively operated upon.  The result was bignums no longer being
the top space usage (new_other ranked ahead of newbignum).  In ACL that
also seemed to provide a minor speed improvement, but in CCL it was a huge
speed decrement, ~15% slower, for the zbrodoff test.
