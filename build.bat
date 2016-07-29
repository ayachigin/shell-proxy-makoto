rm *.dll
rm *.obj
rm *.lib
dmd -ofmakoto.dll -L/IMPLIB src/makoto.d src/main.d dll.def
copy makoto.dll C:\Users\kinoko\freeware\ssp_2_2_92f\ghost4\ghost_git\ghost\master\
