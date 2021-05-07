# optics
Repository storing some optics material - e.g. synchrotron, HEBT, MADX macros, etc...

## MAD-X file extensions
Extensions are given in alphabetical order

| extension | description |
| --------- | ----------- |
| `.aper`  | aperture file |
| `.beamx` | definition of beam |
| `.cmdx`  | specific, customised MAD-X commands |
| `.def`   | some definitions |
| `.ele`   | definition of single elements |
| `.madx`  | generic MAD-X script |
| `.opt`   | optical functions (e.g. starting conditions) |
| `.seq`   | definition of sequence |
| `.str`   | magnet strengths for a specific optics |

## Using an .xlsx file for ramp generation to set magnet strengths
It is possible to get magnet settings directly from excel files used to generate the ramp functions - please have a look at e.g. `loopThroughGenRampFile.cmdx` or `loopThroughLGENFile.cmdx`, and `settings_from_rampGen_table.str` or `settings_from_LGEN_table.str` files in the `synchro` folder.
You cannot use the `.xlsx` file as is - MADX won't crunch it correctly. You can use the `makeTableFromOP.m` script or convert it by hand.

In the latter case, please remember to add a suitable header that MADX can use to properly treat the columns:
1. add a MADX (fake) header, e.g.
```
@ TYPE             %05s "TWISS"
@ TITLE            %09s "CNAO SYNC"
@ ORIGIN           %18s "5.03.04 Windows 64"
@ DATE             %08s "11/09/17"
@ TIME             %08s "16.08.31"
```
1. add a `*` char at the beginning of the header line of the ramp file, otherwise MADX won't be able to correctly detect columns. At the same time, please remove all odd ASCII characters - e.g. all parentheses, empty spaces, all `-` should become `_`, etc...

1. add a format line specifying the type of the column, e.g.:
```
$ %le %le %le %le %le %le %le %le %le %le %le %le %le %le %le %le %le %le %le %le %le %le %le %le %le %le %le %le %le %le %le %le %le %le
```
