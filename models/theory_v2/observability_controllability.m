clearvars;

syms J Bm Km R s

A = [0 1; 0 -(Bm/J+Km^2/(J*R))];
B = [0 0; Km/(J*R) 1/J];
C = [1 0];
D = 0;

Ob = [C; C*A];
display(rref(Ob));
rank(Ob)
unobs = length(A) - rank(Ob);

Co = [B A*B];
display(rref(Co));
rank(Co)
unco = length(A) - rank(Co);
