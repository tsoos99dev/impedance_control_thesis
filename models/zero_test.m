s1 = tf(1, [1 2 4]);
s2 = tf([1 -2 4], [1 2 4])/4;

step(s1)
hold on;
step(s2)
