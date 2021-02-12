% {}~

% template analysis script
% - include Matlab library
pathToLibrary="..\..\..\MatLabTools";
addpath(genpath(pathToLibrary));
opticsFileName="..\extraction_optics.tfs";
geometryFileName="..\extraction_geometry.tfs";

% acquire data
optics = ParseTfsTable(opticsFileName,'optics');
[Qx,Qy,Chrx,Chry,Laccel,headerNames,headerValues] = ...
    ParseTfsTableHeader(opticsFileName);
geometry = ParseTfsTable(geometryFileName,'geometry');

% show the optics
ShowOptics(optics,geometry,"RFKO - Carbon - 270 mm",Laccel,Qx,Qy,Chrx,Chry);