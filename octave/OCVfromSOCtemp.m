function ocv = OCVfromSOCtemp(soc, temp, model)
    % Extract OCV tables
    OCV0 = model.OCV0(:);
    OCVrel = model.OCVrel(:);
    SOC = model.SOC(:);
    soccol = soc(:); % Ensure SOC input is a column vector

    % 🔹 Debug: Display OCV0 and SOC lengths
    disp(["🔍 Length of OCV0:", num2str(length(OCV0))]);
    disp(["🔍 Length of SOC:", num2str(length(SOC))]);

    % ✅ Ensure SOC and OCV0 have the same length
    if length(OCV0) ~= length(SOC)
        error("❌ Mismatch: OCV0 and SOC must have the same number of elements.");
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

    % Initialize output
    ocv = zeros(size(soccol));

    % Find SOC out-of-range indices
    diffSOC = SOC(2) - SOC(1);
    I1 = find(soccol <= SOC(1)); % Below table range
    I2 = find(soccol >= SOC(end)); % Above table range
    I3 = find(soccol > SOC(1) & soccol < SOC(end)); % Inside table range

    % ✅ Extrapolate below table range
    if ~isempty(I1)
        dvdz = (OCV0(2) - OCV0(1)) / diffSOC;
        ocv(I1) = (soccol(I1) - SOC(1)) .* dvdz + OCV0(1);
        ocv(I1) = ocv(I1) + Tcol(I1) .* OCVrel(1);
    end

    % ✅ Extrapolate above table range
    if ~isempty(I2)
        dvdz = (OCV0(end) - OCV0(end-1)) / diffSOC;
        ocv(I2) = (soccol(I2) - SOC(end)) .* dvdz + OCV0(end);
        ocv(I2) = ocv(I2) + Tcol(I2) .* OCVrel(end);
    end

    % ✅ Interpolation within range
    if ~isempty(I3)
        I4 = (soccol(I3) - SOC(1)) / diffSOC;
        I5 = floor(I4);
        I45 = I4 - I5;
        omI45 = 1 - I45;

        % Ensure indices are within valid bounds
        I5(I5 < 1) = 1;
        I5(I5 >= length(OCV0)) = length(OCV0) - 1;

        ocv(I3) = OCV0(I5) .* omI45 + OCV0(I5+1) .* I45;
        ocv(I3) = ocv(I3) + Tcol(I3) .* (OCVrel(I5) .* omI45 + OCVrel(I5+1) .* I45);
    end

    % Ensure correct output shape
    ocv = reshape(ocv, size(soc));
end
