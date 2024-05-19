clearvars;

% Motor parameters
motor_params

% Impedance parameters
Me = 1*J;
be = 40;
w0 = 73;
Be = be*Me;
Ke = w0^2*Me;

% Controller
controller_calc

format longG
writematrix(Adtilde, "model_params.csv")
writematrix(Bdtilde,"model_params.csv",'WriteMode','append')
writematrix(Cdtilde,"model_params.csv",'WriteMode','append')
writematrix(Ddtilde,"model_params.csv",'WriteMode','append')
