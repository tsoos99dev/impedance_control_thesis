d = 0.1;
a = 10;
g = tf(1, [1, -a]);
h = tf(1, [1, -a], 'InputDelay', d);
g=feedback(g, 1);
h = feedback(h, 1);
ha = pade(h, 1)
[A, B, C, D] = ssdata(ha);
[num, den] = ss2tf(A, B, C, D)

% step(h)

a = -500:0.1:20;
k =-3:2;
[k, a] = meshgrid(k, a);
r = -d*exp(-a*d);
sn = a - 1;
sl = 1/d*lambertw(k, r) + a;

ac = 1/d*(log(d)+1);

% sl = lambertw(-300:300, 1i);
scatter(real(sl), imag(sl), '.')
grid on;




