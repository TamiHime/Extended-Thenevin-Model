% Define the ESC model parameters
model.R0 = 0.015;  % Ohmic resistance in ohms
model.R1 = 0.020;  % First RC pair resistance
model.C1 = 2000;   % First RC pair capacitance
model.R2 = 0.005;  % Second RC pair resistance
model.C2 = 5000;   % Second RC pair capacitance

% Battery capacity (Q), assumed 3600 As (1Ah)
model.Q = 3600;

% Open Circuit Voltage (Voc) as a function of SoC
% Using a polynomial approximation: Voc = a0 + a1*SoC + a2*SoC^2 + a3*SoC^3
model.VocCoeff = [3.0, 0.5, -0.2, 0.1];  % Example polynomial coefficients

% Discrete-time state-space matrices for ESC model
A = [exp(-1/(model.R1*model.C1)), 0;
     0, exp(-1/(model.R2*model.C2))];
B = [1/model.C1; 1/model.C2];
C = [-model.R1, -model.R2];
D = [-1];

model.A = A;
model.B = B;
model.C = C;
model.D = D;

% Save the model to pulseModel.mat
save('readonly/pulseModel.mat', 'model');

