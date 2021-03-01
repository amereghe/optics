% {}~

% template analysis script
% - include Matlab library
pathToLibrary="..\..\..\MatLabTools";
addpath(genpath(pathToLibrary));
opticsFileName="..\linet_optics.tfs";
geometryFileName="..\linet_geometry.tfs";

% acquire data
optics = ParseTfsTable(opticsFileName,'optics');
[Qx,Qy,Chrx,Chry,Laccel,headerNames,headerValues] = ...
    ParseTfsTableHeader(opticsFileName);
geometry = ParseTfsTable(geometryFileName,'geometry');

% show the optics
ShowOptics(optics,geometry,"Line T (sala 3) - 270mm",Laccel,Qx,Qy,Chrx,Chry);