Tried a test of keeping the chunks' slots sorted at all times
instead of sorting when needed.  Was a minor performance hit
for zbrodoff test, so probably not useful overall and it 
also requires reverifying a lot of test models since their
output differs.