% {}~

% parse CyCo vs Energy
% - 1: Ek [MeV/n];
% - 2: cycle code;
% - 3: range [mm];
FileName="S:\Accelerating-System\Accelerator-data\Area dati MD\00Setting\MeVvsCyCo_P.xlsx";
CyCoData = getMyData(FileName,"Sheet1");
% remove header
CyCoData = CyCoData(2:end,:);

% parse Brho vs Energy
% - 1: range [mm];
% - 2: Brho [Tm];
FileName="S:\Accelerating-System\Accelerator-data\Area dati MD\00Setting\EvsBro_P.xlsx";
BrhoData = getMyData(FileName,"Sheet1");
% remove header
BrhoData = BrhoData(2:end,:);

% parse file with currents at FT
% - nRows: number of power supplies + a header
% - nColumns: number of cycle codes + 2 (PS name + property)
FileName="S:\Accelerating-System\Accelerator-data\Area dati MD\00Setting\Sincro\CorrentiFlatTop\ProtoniSincro_2021-02-13.xlsx";
currents = getMyData(FileName,"Foglio1");
% - get cycle codes to be crunched
currCycodes=currents(1,3:end);
nCyCodes=length(currCycodes);
for ii=1:nCyCodes
    currCycodes{ii}=currCycodes{ii}(1:4);
end
% - get PS to be crunched
psNames=currents(2:end,1);
nPSs=length(psNames);
% - remove useless data from PS file:
currents=currents(2:end,3:end);
% - get common ranges
[commonRanges,iCRa,iCRb]=intersect(cell2mat(CyCoData(:,3)),cell2mat(BrhoData(:,1)));
CyCoData=CyCoData(iCRa,:);
BrhoData=BrhoData(iCRb,:);
[commonCyCodes,iCCa,iCCb]=intersect(currCycodes,CyCoData(:,2));
if ( iCCa~=nCyCodes )
    warning("not all cycle codes in PS file will be dumped!");
end
CyCoData=CyCoData(iCCb,:);
BrhoData=BrhoData(iCCb,:);
commonRanges=commonRanges(iCCb,:);
currents=currents(:,iCCa);
nCyCodes=length(commonCyCodes);

% build table to be exported
% - nRows: number of cycle codes
% - nColumns: number of PSs + 3 (range[mm],Brho[Tm],Ek[MeV/n])
bigTable=zeros(nCyCodes,nPSs+3);
for ii=1:nCyCodes
    bigTable(ii,1)=commonRanges(ii);
    bigTable(ii,2)=cell2mat(BrhoData(ii,2));
    bigTable(ii,3)=cell2mat(CyCoData(ii,1));
    for jj=1:nPSs
        bigTable(ii,3+jj)=cell2mat(currents(jj,ii));
    end
end
% prepare header
headers=strings(1,nPSs+3);
headers(1)="range_mm";
headers(2)="Brho_Tm";
headers(3)="Ek_MeVN";
headers(4:end)=psNames+"_A";
% prepare header type
headerTypes=strings(1,nPSs+3);
headerTypes(:)="%le";
% export MADX table
FileName="synchro\ProtoniSincro_2021-02-13.tfs";
title="myTable";
exportMADXtable(FileName,title,bigTable,headers,headerTypes);

function myData=getMyData(FileName,sheetName)
    tmpFile=dir(FileName);
    if ( length(tmpFile)>1 )
        error("Path %s is not a single file!",tmpFile);
    end
    fprintf("acquring data from file %s in folder %s...\n",tmpFile(1).name,tmpFile(1).folder);
    if ( exist('sheetName','var') )
        myData=readcell(sprintf("%s\\%s",tmpFile(1).folder,tmpFile(1).name),"Sheet",sheetName);
    else
        myData=readcell(sprintf("%s\\%s",tmpFile(1).folder,tmpFile(1).name));
    end
end

function exportMADXtable(FileName,title,bigTable,headers,headerTypes)
    fprintf("saving data to file %s...\n",FileName);
    T=now;
    fileID = fopen(FileName,'w');
    % - MADX table header
    writeMADXHeaderLine(fileID,"TYPE","TWISS");
    writeMADXHeaderLine(fileID,"TITLE",title);
    writeMADXHeaderLine(fileID,"ORIGIN","MatLab");
    writeMADXHeaderLine(fileID,"DATE",datestr(T,'dd/mm/yy'));
    writeMADXHeaderLine(fileID,"TIME",datestr(T,'hh.mm.ss'));
    % - column names
    fprintf(fileID,"*");
    fprintf(fileID,"\t%s",headers);
    fprintf(fileID,"\n");
    % - column types
    fprintf(fileID,"$");
    fprintf(fileID,"\t%s",headerTypes);
    fprintf(fileID,"\n");
    % - actual data
    for ii=1:size(bigTable,1)
        fprintf(fileID,"\t%f",bigTable(ii,:));
        fprintf(fileID,"\n");
    end
    fclose(fileID);
end

function writeMADXHeaderLine(fileID,what,content)
    fprintf(fileID,"@ %-16s %%%02is ""%s""\n",what,strlength(content),content);
end