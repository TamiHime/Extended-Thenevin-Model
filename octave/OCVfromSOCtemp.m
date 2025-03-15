function ocv = OCVfromSOCtemp(soc, temp, model)
    OCV0 = model.OCV0(:);
    SOC = model.SOC(:);
    
    % Debug: Display OCV0 length
    disp(["🔍 Length of OCV0:", num2str(length(OCV0))]);
    disp(["🔍 Length of SOC:", num2str(length(SOC))]);

    % Ensure SOC lookup does not exceed bounds
    if max(soc) > max(SOC)
        error("❌ SOC value exceeds OCV lookup table bounds!");
    end
    
    % Extract OCV tables
    OCV0 = model.OCV0(:);
    OCVrel = model.OCVrel(:);
    SOC = model.SOC(:);
    soccol = soc(:);
    
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
    
    % Extrapolate below table
    if ~isempty(I1)
        dvdz = ((OCV0(2) + Tcol .* OCVrel(2)) - (OCV0(1) + Tcol .* OCVrel(1))) / diffSOC;
        ocv(I1) = (soccol(I1) - SOC(1)) .* dvdz + OCV0(1) + Tcol(I1) .* OCVrel(1);
    end

    % Extrapolate above table
    if ~isempty(I2)
        dvdz = ((OCV0(end) + Tcol .* OCVrel(end)) - (OCV0(end-1) + Tcol .* OCVrel(end-1))) / diffSOC;
        ocv(I2) = (soccol(I2) - SOC(end)) .* dvdz + OCV0(end) + Tcol(I2) .* OCVrel(end);
    end
    
    % Interpolation within range
    if ~isempty(I3)
        I4 = (soccol(I3) - SOC(1)) / diffSOC;
        I5 = floor(I4);
        I45 = I4 - I5;
        omI45 = 1 - I45;
        ocv(I3) = OCV0(I5+1) .* omI45 + OCV0(I5+2) .* I45;
        ocv(I3) = ocv(I3) + Tcol(I3) .* (OCVrel(I5+1) .* omI45 + OCVrel(I5+2) .* I45);
    end
    
    % Ensure correct output shape
    ocv = reshape(ocv, size(soc));
end
