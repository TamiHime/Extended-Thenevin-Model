function model = pulseModel()
    % Define the ESC model parameters
    model.R0 = 0.015;
    model.R1 = 0.020;
    model.C1 = 2000;
    model.R2 = 0.005;
    model.C2 = 5000;
    model.Q = 3600;

    % Open Circuit Voltage (Voc) as a function of SoC
    model.VocCoeff = [3.0, 0.5, -0.2, 0.1];

    % Discrete-time state-space matrices for ESC model
    model.A = [exp(-1/(0.020 * 2000)), 0;
               0, exp(-1/(0.005 * 5000))];

    model.B = [1/2000; 1/5000];
    model.C = [-0.020, -0.005];
    model.D = -1;
end

