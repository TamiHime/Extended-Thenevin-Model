function optimize_RC(R0_init, R1_init, C1_init, R2_init, C2_init)
    % 🔹 Debug: Print working directory & available files
    disp("📂 Checking working directory...");
    disp(pwd); % Prints the current directory
    disp("🔍 Available files in readonly:");
    disp(ls('readonly/')); % Lists files in readonly folder

    % 🔹 Load Data Files
    disp("🔍 Loading pulseData.mat...");
    pulseDataVars = pulseModel();

    disp("🔍 Loading pulseModel.mat...");
    pulseModelVars = load('readonly/pulseModel.mat');
    
    % 🔹 Debug: Check available variables in pulseModel.mat
    disp("📂 Variables in pulseModel.mat:");
    disp(fieldnames(pulseModelVars));

    % 🔹 Ensure model exists in pulseModel.mat
    if isfield(pulseModelVars, 'model')
        model = pulseModelVars.model;
        disp("✅ Loaded 'model' from pulseModel.mat");
    else
        error("❌ 'model' is missing from pulseModel.mat!");
    end

    % 🔹 Set Constants
    deltaT = 1;  
    T = 25;  

    % 🔹 Debug: Check if model works with getParamESC
    try
        Q = getParamESC('QParam', T, model);  
    catch err
        disp("❌ Error in getParamESC:");
        disp(err.message);
        error("⚠️ 'model' is incorrectly defined or missing required fields.");
    end

    % Extract Data
    tk = pulseDataVars.pulseData.time;    
    ik = pulseDataVars.pulseData.current;  
    vk = pulseDataVars.pulseData.voltage;  

    % Initialize parameters
    R = [R0_init, R1_init, R2_init] / 1000;
    C = [C1_init, C2_init] * 1000;

    % Optimization (Gradient Descent)
    alpha = 0.005;
    max_iter = 500;
    tolerance = 1e-5;
    prev_error = Inf;

    for iter = 1:max_iter
        vest = rc_model_function([R(1)*1000, R(2)*1000, C(1)/1000, R(3)*1000, C(2)/1000], ik, vk, deltaT, Q, model);
        error = sum((vk - vest).^2);

        grad_R = zeros(size(R));
        grad_C = zeros(size(C));

        for i = 1:length(R)
            R_temp = R;
            R_temp(i) = R_temp(i) + 1e-6;
            vest_temp = rc_model_function([R_temp(1)*1000, R_temp(2)*1000, C(1)/1000, R_temp(3)*1000, C(2)/1000], ik, vk, deltaT, Q, model);
            grad_R(i) = (sum((vk - vest_temp).^2) - error) / 1e-6;
        end
        
        for i = 1:length(C)
            C_temp = C;
            C_temp(i) = C_temp(i) + 1e-6;
            vest_temp = rc_model_function([R(1)*1000, R(2)*1000, C_temp(1)/1000, R(3)*1000, C_temp(2)/1000], ik, vk, deltaT, Q, model);
            grad_C(i) = (sum((vk - vest_temp).^2) - error) / 1e-6;
        end

        R = R - alpha * grad_R;
        C = C - alpha * grad_C;

        R = max(min(R, [0.1, 0.1, 0.1]), [0.001, 0.001, 0.001]);
        C = max(min(C, [1, 1]), [0.001, 0.001]);

        if abs(prev_error - error) < tolerance
            break;
        end

        prev_error = error;
    end

    % Optimize Outputs
    R_opt = round(R * 1000, 3, "significant");
    C_opt = round(C / 1000, 3, "significant");

    % ✅ Print final results
    printf("✅ Optimization Complete!\n");
    printf("R0: %.3f, R1: %.3f, C1: %.3f, R2: %.3f, C2: %.3f\n", R_opt(1), R_opt(2), C_opt(1), R_opt(3), C_opt(2));
end
