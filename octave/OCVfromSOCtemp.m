function ocv = OCVfromSOCtemp(soc, temp, model)
    % Extract OCV tables
    OCV0 = model.OCV0(:);
    OCVrel = model.OCVrel(:);
    SOC = model.SOC(:);
    soccol = soc(:); % Ensure SOC input is a column vector

    % 🔹 Debugging: Print sizes
    disp(["🔍 Length of OCV0:", num2str(length(OCV0))]);
    disp(["🔍 Length of SOC:", num2str(length(SOC))]);
    disp(["🔍 Length of OCVrel:", num2str(length(OCVrel))]);

    % ✅ Ensure all lookup tables have the same length
    if length(OCV0) ~= length(SOC) || length(OCVrel) ~= length(SOC)
        error("❌ Mismatch: OCV0, OCVrel, and SOC must have the same number of elements.");
    end

    % ✅ Ensure SOC lookup does not exceed bounds
    soccol(soccol < SOC(1)) = SOC(1);
    soccol(soccol > SOC(end)) = SOC(end);

    % Handle temperature input
    if isscalar(temp)
        Tcol = temp * ones(size(soccol)); % Apply scalar temperature
    else
        Tcol = temp(:); % Convert to column vector
    end

    % ✅ Debugging: Ensure Tcol is correct
    disp(["🔹 Size of Tcol before reshape: ", num2str(size(Tcol))]);

    % ✅ Ensure Tcol matches soccol size
    Tcol = reshape(Tcol, size(soccol));

    % Initialize output
    ocv = zeros(size(soccol));

    % Fix potential scalar vs. vector issue
    SOC_1 = SOC(1); % Ensures it is a scalar (1x1)
    diffSOC = SOC(2) - SOC_1; % Ensures scalar difference

    % Find SOC out-of-range indices
    I1 = find(soccol <= SOC_1); % Below table range
    I2 = find(soccol >= SOC(end)); % Above table range
    I3 = find(soccol > SOC_1 & soccol < SOC(end)); % Inside table range

    % ✅ Debugging: Print I3 size
    disp(["🔹 Size of I3: ", num2str(size(I3))]);

    % ✅ Interpolation within range
    if ~isempty(I3)
        % ✅ Ensure I4 is a column vector
        I4 = (soccol(I3) - SOC_1) ./ diffSOC;
        I4 = I4(:);

        I5 = floor(I4);
        I45 = I4 - I5;
        omI45 = 1 - I45;

        % ✅ Fix: Ensure I5 does not exceed bounds
        I5(I5 < 1) = 1;
        I5(I5 >= length(OCV0) - 1) = length(OCV0) - 1;  % Prevent overflow

        % ✅ Debugging: Print I5 size
        disp(["🔹 Size of I5: ", num2str(size(I5))]);

        % ✅ Ensure correct indexing of OCV0 and OCVrel
        OCV0_I5 = OCV0(I5);
        OCV0_I5p1 = OCV0(I5+1);

        OCVrel_I5 = OCVrel(I5);
        OCVrel_I5p1 = OCVrel(I5+1);

        % 🚀 Fix the shape issue: Ensure all values are column vectors
        omI45 = omI45(:);
        I45 = I45(:);
        OCV0_I5 = OCV0_I5(:);
        OCV0_I5p1 = OCV0_I5p1(:);
        OCVrel_I5 = OCVrel_I5(:);
        OCVrel_I5p1 = OCVrel_I5p1(:);

        % ✅ Fix the interpolation calculations
        OCVrel_corrected = (OCVrel_I5 .* omI45) + (OCVrel_I5p1 .* I45);
        ocv_corrected = (OCV0_I5 .* omI45) + (OCV0_I5p1 .* I45);

        % ✅ Debugging - Display variable sizes before assignment
        disp(["🔹 Size of ocv_corrected: ", num2str(size(ocv_corrected))]);
        disp(["🔹 Size of Tcol(I3): ", num2str(size(Tcol(I3)))]);
        disp(["🔹 Size of OCVrel_corrected: ", num2str(size(OCVrel_corrected))]);

        % ✅ Ensure all terms are column vectors before assignment
        ocv_corrected = reshape(ocv_corrected, [], 1);
        OCVrel_corrected = reshape(OCVrel_corrected, [], 1);
        Tcol_I3_reshaped = reshape(Tcol(I3), [], 1);

        % ✅ 🔥 Final Fix 🔥 Ensure ocv(I3) is also a column vector
        ocv(I3) = reshape(ocv_corrected, [], 1) + (reshape(Tcol(I3), [], 1) .* reshape(OCVrel_corrected, [], 1));
    end

    % Ensure correct output shape
    ocv = reshape(ocv, size(soc));
end
