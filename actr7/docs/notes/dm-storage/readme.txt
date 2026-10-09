This was a performance based improvement attempt that replaced the list based storage of chunks in DM
with a tree where the nodes were slots and the branches were whether a chunk had the slot or not which
resulted in the leaves being the sets of similarly "typed" chunks.  The idea was that it should be
faster to search than the flat list if there were enough different types, but models like those in
the tutorial don't have enough types to make that helpful.  Also attempted to use it as a replacement
for the fast-merge hashtable figuring a short tree lookup may be faster than a hashtable lookup
which was faster in a few cases, but not generally.

Keeping it around just incase some of those ideas may become useful at some point for a specific
model or in conjunction with some other changes.