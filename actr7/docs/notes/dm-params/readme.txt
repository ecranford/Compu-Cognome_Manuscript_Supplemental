This was a performance based improvement that replaced separate declarative parameters in chunks with a single
parameter that held a structure with the parameters to facilitate faster access to the params.  It had a small
effect on the memory footprint because non-dm chunks didn't need the extra storage.  Testing with the tutorial
models, the unit 5 models showed some noticable improvements: ~9% faster for onehit blackjack task, ~6% faster
for the siegler task, and a little better than 2% faster for fan and grouped models, and the past-tense model
also had about a 2% improvement.  However, for all other tasks there was basically no difference.

Since using a struct for a parameter prevents it from being usable remotely and the improvement was of
limited benefit I'm just storing this here for now.