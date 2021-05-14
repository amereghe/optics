% {}~

% template analysis script
% - include Matlab library
pathToLibrary="..\..\MatLabTools";
addpath(genpath(pathToLibrary));
opticsFileName="example_optics.tfs";
geometryFileName="example_geometry.tfs";

% acquire data
optics = ParseTfsTable(opticsFileName,'optics');
[Qx,Qy,Chrx,Chry,Laccel,headerNames,headerValues] = ...
    ParseTfsTableHeader(opticsFileName);
geometry = ParseTfsTable(geometryFileName,'geometry');

% show the optics
ShowOptics(optics,geometry,"MEBT - Protons",Laccel,Qx,Qy,Chrx,Chry);
