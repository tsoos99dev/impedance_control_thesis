% Motor parameters
J = 0.01;
Km = 0.01;
Bm = 0.1;
L = 0.5;
R = 1;

Te = L/R;
Tm = R*J/Km^2;

% Motor model
A = [0 1 0; 0 -Bm/J Km/J; 0 -Km/L -R/L];
B = [0; 0; R/L/Km];
C = [0 1 0];
D = 0;

motor1 = ss(A, B, C, D, 'InputName', {'V'}, 'OutputName', 'a', 'StateName', {'a', 'w', 'i'});
% [num, den] = ss2tf(A, B, C, D)

% Motor model
A = [0 1 0; 0 -Bm/J Km/J; 0 -Km/L -R/L];
B = [0; 1/J; 0];
C = [0 1 0];
D = 0;

motor2 = ss(A, B, C, D, 'InputName', {'t'}, 'OutputName', 'a', 'StateName', {'a', 'w', 'i'});
% [num, den] = ss2tf(A, B, C, D)


subplot(2, 1, 1);
step(motor1)
hold on;
step(motor2)
subplot(2, 1, 2);
pzmap(motor1)
hold on;
pzmap(motor2)



% Compensating an external torque requires that mechanical subsystem 
% responds to voltage input almost as fast as it reacts to the
% external torque.