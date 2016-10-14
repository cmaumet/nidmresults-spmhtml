function nidm_results_display(jsonfilepath, overWrite)
    
    %Checks on input
    narginchk(1, 2);
    if nargin > 1
        validateattributes(overWrite,{'numeric'}, {'binary'});
    end
    %Ask user whether to overwrite files
    if nargin < 2
        button = questdlg('There currently exists a folder named HTML in the output directory. Would you like this folder to be overwritten? Note: All files in the HTML folder will be lost if overwritten.', 'Warning', 'Overwrite', 'Do not overwrite', 'Do not overwrite');
        switch button
            case 'Overwrite'
                overWrite = 1;
            case 'Do not overwrite'
                overWrite = 0;
            case ''
                overWrite = 0;
        end
    end
    
    %Record users choice and filepath.
    jsondoc=spm_jsonread(jsonfilepath);
    pathstr = fileparts(jsonfilepath); 
    jsondoc.filepath = pathstr;
    jsondoc.overWrite = overWrite;
    
    %Add path to required methods
    if exist('changeNIDMtoSPM') ~= 2
        addpath(fullfile(fileparts(mfilename('fullpath')), 'lib'));
    end
    
    spm_results_export(changeNIDMtoSPM(jsondoc),changeNIDMtoxSPM(jsondoc),changeNIDMtoTabDat(jsondoc));
    
end