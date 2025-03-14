function optimize_RC(R0_init, R1_init, C1_init, R2_init, C2_init)
    % Load the pulse data
    load('readonly/pulseData.mat'); % Ensure this file exists in the 'readonly' directory

    % Load the battery model
    model = pulseModel();

    % Extract data from pulseData
    time = pulseData.time;
    current = pulseData.current;
    voltage = pulseData.voltage;

    % Set initial parameter values
    initialParams = [R0_init, R1_init, C1_init, R2_init, C2_init];

    % Define optimization options
    options = optimset('Display', 'iter', 'TolFun', 1e-6, 'TolX', 1e-6);

    % Define the objective function for optimization
    objectiveFunction = @(params) objective_RC(params, time, current, voltage, model);

    % Perform the optimization
    [optimizedParams, errorValue] = fminsearch(objectiveFunction, initialParams, options);

    % Print the optimized parameters
    fprintf('Optimized Parameters:\n');
    fprintf('R0: %.6f\n', optimizedParams(1));
    fprintf('R1: %.6f\n', optimizedParams(2));
    fprintf('C1: %.6f\n', optimizedParams(3));
    fprintf('R2: %.6f\n', optimizedParams(4));
    fprintf('C2: %.6f\n', optimizedParams(5));
    fprintf('Final Error Value: %.6f\n', errorValue);

    % Write output to a JSON file for TypeScript to process
    outputFile = fopen('readonly/optimized_params.json', 'w');
    fprintf(outputFile, '{"R0": %.6f, "R1": %.6f, "C1": %.6f, "R2": %.6f, "C2": %.6f, "error": %.6f}', ...
        optimizedParams(1), optimizedParams(2), optimizedParams(3), optimizedParams(4), optimizedParams(5), errorValue);
    fclose(outputFile);
end

function error = objective_RC(params, time, current, voltage, model)
    % Unpack parameters
    R0 = params(1);
    R1 = params(2);
    C1 = params(3);
    R2 = params(4);
    C2 = params(5);

    % Update model parameters
    model.R0 = R0;
    model.R1 = R1;
    model.C1 = C1;
    model.R2 = R2;
    model.C2 = C2;

    % Simulate the cell voltage using the updated parameters
    deltaT = time(2) - time(1); % Assuming uniform time steps
    T = 25; % Assuming a constant temperature of 25°C
    z0 = 0.5; % Initial state of charge (50%)
    iR0 = 0; % Initial resistor currents
    h0 = 0; % Initial hysteresis state

    [simulatedVoltage, ~, ~, ~, ~, ~] = simCell(current, T, deltaT, model, z0, iR0, h0);

    % Calculate the error between the simulated and measured voltage
    error = sum((voltage - simulatedVoltage).^2);
end
