function ocv = OCVfromSOCtemp(soc, temp, model)
    % Extract OCV tables
    OCV0 = model.OCV0(:);
    OCVrel = model.OCVrel(:);
    SOC = model.SOC(:);
    soccol = soc(:); % Ensure SOC input is a column vector

    % 🔹 Debug: Display lengths
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

    % ✅ Ensure Tcol matches soccol size
    Tcol = reshape(Tcol, size(soccol));

    % Initialize output
    ocv = zeros(size(soccol));

    % Find SOC out-of-range indices
    diffSOC = SOC(2) - SOC(1);
    I1 = find(soccol <= SOC(1)); % Below table range
    I2 = find(soccol >= SOC(end)); % Above table range
    I3 = find(soccol > SOC(1) & soccol < SOC(end)); % Inside table range

    % ✅ Interpolation within range
    if ~isempty(I3)
        I4 = (soccol(I3) - SOC(1)) / diffSOC;
        I5 = floor(I4);
        I45 = I4 - I5;
        omI45 = 1 - I45;

        % ✅ Ensure I5 does not exceed bounds
        I5(I5 < 1) = 1;
        I5(I5 >= length(OCV0)) = length(OCV0) - 1;

        % ✅ Correct indexing of OCV0 and OCVrel
        OCV0_I5 = OCV0(I5);
        OCV0_I5p1 = OCV0(I5+1);

        OCVrel_I5 = OCVrel(I5);
        OCVrel_I5p1 = OCVrel(I5+1);

        % 🚀 Fix shape mismatch by ensuring correct broadcasting
        OCVrel_corrected = (OCVrel_I5 .* omI45) + (OCVrel_I5p1 .* I45);
        
        % ✅ Ensure ocv_corrected matches shape expectations
        ocv_corrected = (OCV0_I5 .* omI45) + (OCV0_I5p1 .* I45);

        % ✅ Only reshape if needed
        if size(ocv_corrected) ~= size(Tcol(I3))
            ocv_corrected = reshape(ocv_corrected, size(Tcol(I3)));
        end
        if size(OCVrel_corrected) ~= size(Tcol(I3))
            OCVrel_corrected = reshape(OCVrel_corrected, size(Tcol(I3)));
        end

        ocv(I3) = ocv_corrected + (Tcol(I3) .* OCVrel_corrected);
    end

    % Ensure correct output shape
    ocv = reshape(ocv, size(soc));
end
