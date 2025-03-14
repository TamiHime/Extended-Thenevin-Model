function [model, getParamESC, OCVfromSOCtemp, simCell] = pulseModel()
    % 📌 Define the ESC Model Parameters
    model.R0 = 0.015;
    model.R1 = 0.020;
    model.C1 = 2000;
    model.R2 = 0.005;
    model.C2 = 5000;
    model.Q = 3600;

    % Open Circuit Voltage (OCV) parameters
    model.OCV0 = [3.0, 0.5, -0.2, 0.1];
    model.OCVrel = [0.1, -0.05, 0.02, 0.01];
    model.SOC = linspace(0, 1, 100);
    
    % Temperature-dependent parameters
    model.temps = [-10, 0, 25, 45];
    model.RCParam = [2000, 2200, 2500, 2700];
    model.QParam = [3600, 3650, 3700, 3750];

end
