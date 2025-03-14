function theParam = getParamESC(paramName, temp, model)
    temp = min(temp, max(model.temps));
    temp = max(temp, min(model.temps));

    mdlFields = fieldnames(model);
    theField = find(strcmpi(paramName, mdlFields));
    if isempty(theField)
        error('Bad argument to "paramName"');
    end

    fieldData = model.(mdlFields{theField});
    theParam = repmat(fieldData, size(temp));

    if length(fieldData) > 1
        if length(temp) > 1
            theParam = interp1(model.temps, fieldData, temp, 'spline');
        else
            ind = find(model.temps == temp);
            if ~isempty(ind)
                theParam = fieldData(ind);
            else
                theParam = interp1(model.temps, fieldData, temp, 'spline');
            end
        end
    end
end
