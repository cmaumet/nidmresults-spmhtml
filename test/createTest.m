%==========================================================================
%This function writes a function, testDataSets, for testing the viewer on
%all jsons stored locally in the Data/jsons directory. 
%
%Authors: Thomas Maullin, Camille Maumet, Thomas Nichols
%==========================================================================

function createTest()
       
    %Create new test file for editing.
    FID = fopen(fullfile(fileparts(mfilename('fullpath')), 'testDataSets.m'),'wt');
    
    %Make a list of all json names stored locally.
    files=dir([fullfile(fileparts(mfilename('fullpath')), '..', 'test', 'data', 'jsons','*.json')]);
    jsonFileList={files.name};
    jsonFileNameList = strrep(jsonFileList, '.json', '');
    jsons={};
    maxLength = 1;
    
    %Calculate the maximum excursion set length.
    for i = 1:length(jsonFileList)  
        %Retrieve the json.
        jsons{i} = spm_jsonread(fullfile(fileparts(mfilename('fullpath')), '..', 'test', 'data', 'jsons', jsonFileList{i}));
        % Deal with sub-graphs (bundle)
        graph = jsons{i}.x_graph;
        if isfield(graph{2}, 'x_graph')
            graph = graph{2}.x_graph;
        end
        excursionSets = searchforType('nidm_ExcursionSetMap', graph);
        if(length(excursionSets)>maxLength)
            maxLength=length(excursionSets);
        end
    end
    
    %Add the start of the test code.
    start = sprintf('%s' , '%%==========================================================================',...
        '\n%%Unit tests for testing whether datasets run in the viewer. To run the',... 
        '\n%%below run the runTest function. The html files generated can be found in',...
        '\n%%the corresponding folders after the test has been run.',...
        '\n%%',...
        '\n%%Authors: Thomas Maullin, Camille Maumet. (Generated by the createTest',...
        '\n%%function).',...
        '\n%%==========================================================================',...
        '\n classdef testDataSets < matlab.unittest.TestCase',...  
        '\n \n \t methods',...
        '\n \t \t %%Function for deleting any HTML generated previously by the viewer',...
        '\n \t \t function delete_html_file(testCase, data_path)',...
        '\n \t \t \t index = fullfile(data_path,', sprintf('''index.html'''), ');',...
        '\n \t \t \t if exist(index, ', sprintf('''file'''), ')',...
        '\n \t \t \t \t delete(index);');
    
    if(maxLength>1)
        loopString = sprintf('%s' ,...
            '\n \t \t \t else',...
            '\n \t \t \t \t for(i = 1:', num2str(maxLength), ')',...
            '\n \t \t \t \t \t index = fullfile(data_path,',...
                                sprintf('%s','[','''index''', ', num2str(i), ','''.html''', ']'), ');',...
            '\n \t \t \t \t \t if exist(index, ', sprintf('''file'''), ')',...
            '\n \t \t \t \t \t \t delete(index);',...
            '\n \t \t \t \t \t end',...
            '\n \t \t \t \t end');
        start = sprintf('%s' , start, loopString);
    end 
    
    start = sprintf('%s' , start,...
        '\n \t \t \t end',...
        '\n \t \t end',...
        '\n \t end',...  
        '\n \n \t methods(Test)');  %#ok<*NOPRT>
    
    fprintf(FID, start);

    %For each json, create a test.
    
    for i = 1:length(jsonFileList)      
      
        % Deal with sub-graphs (bundle)
        graph = jsons{i}.x_graph;
        if isfield(graph{2}, 'x_graph')
            graph = graph{2}.x_graph;
        end
        
        [designMatrix, ~] = searchforType('nidm_DesignMatrix', graph);
        goAhead = true;
        jsonLocation = [fileparts(designMatrix{1}.prov_atLocation.x_value), '.zip'];
        %ex_spm_default is an exception.
        if strcmp(jsonFileNameList{i}, 'ex_spm_default')
            jsonLocation = 'http://neurovault.org/collections/1692/ex_spm_default.nidm.zip';
        end
        if strcmp(jsonLocation, '.zip')
            % Design matrix file was define with relative path
            jsonLocation = ['http://neurovault.org/collections/IBRBTZPC/' jsonFileNameList{i} '.nidm.zip'];
        end
        %In case this is a json we cannot test, as we cannot obtain the 
        %json's corresponding files, so we don't make a test for it.
        if ((strcmp(jsonLocation,'')) || (strcmp(jsonLocation(1),'.')))...
                &&~exist(fullfile(fileparts(mfilename('fullpath')),'..','test', 'data',jsonFileNameList{i}), 'dir')
            goAhead = false;     
        end
        
        if(goAhead)
            tests = sprintf('%s' , '\n \n \t \t %%Test viewer displays ',jsonFileNameList{i},... 
                '\n \t \t function test_', jsonFileNameList{i},'(testCase)',...
                '\n \t \t \t data_path = fullfile(fileparts(mfilename(', sprintf('''fullpath'''), ')),', sprintf('''..'','), sprintf('''test'','), sprintf('''data'','), '''', jsonFileNameList{i}, '''', ');',...
                '\n \t \t \t', sprintf(' if(~exist(data_path, ''dir''))'),...
                '\n \t \t \t \t mkdir(data_path);',...
                '\n \t \t \t \t websave([data_path, filesep, ''temp.zip''], ''', jsonLocation,''');',...
                '\n \t \t \t \t unzip([data_path, filesep, ''temp.zip''], [data_path, filesep]);',...
                '\n \t \t \t end',...
                '\n \t \t \t testCase.delete_html_file(data_path);',...
                '\n \t \t \t nidm_results_display(fullfile(fileparts(mfilename(''fullpath'')), ''..'', ''test'',''data'', ''jsons'',','''', jsonFileList{i},'''', '), ''all'');',...
                '\n \t \t end');
            fprintf(FID, tests);
        end 
    end
    
    %end the test file.
    last = sprintf('%s', '\n \n \t end', '\n \n end');
    fprintf(FID, last);
    
    fclose(FID);

end

function [result, index] = searchforType(type, graph) 
    
    index = [];
    result = [];
    n = 1;
    
    %Look through the graph for objects of a type 'type'.
    for k = 1:length(graph)
        %If an object has one of its types listed as 'type' recorded it.
        if any(ismember(graph{k}.('x_type'), type)) && isa(graph{k}.('x_type'), 'cell')
            result{n} = graph{k};
            index{n} = k;
            n = n+1;
        end
        %If an object has it's only type listed as 'type' recorded it.
        if isa(graph{k}.('x_type'), 'char')
            if strcmp(graph{k}.('x_type'), type)
                result{n} = graph{k};
                index{n} = k;
                n = n+1;
            end
        end
    end
end