% Time delay [s]
t_d = 0.005;

% Gear ratio [-]
N = 4.4;
% Rotor inertia ratio [kg⋅m^2]
Jm = 6.34e-7;   
% Load inertia [kg⋅m^2]
Jload = 1.3e-4;
% Motor side combined inertia [kg⋅m^2]
J = Jm + Jload / N^2;
% Viscous damping coefficient [Nm⋅s]
Bm = 1.0e-6;
% Torque constant [Nm/A]
Km = 15.4e-3;
% Rotor resistance [Ω]
R = 9.5;
% Operating voltage [V]
V = 11.835;
