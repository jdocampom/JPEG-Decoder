#!/bin/csh

if($#argv == 0) then
  echo Usage: run.ms IMAGENAME
  exit
endif

../c_model/convbtoh ../image/$argv[1].jpg test.mem 

if(-d ./work) rm -rf work

vlib work
vlog \
../src/jpeg_regdata.v \
../src/jpeg_ziguzagu_reg.v \
../src/jpeg_ziguzagu.v \
../src/jpeg_dqt.v \
../src/jpeg_dht.v \
../src/jpeg_hm_decode.v \
../src/jpeg_haffuman.v \
../src/jpeg_idctb.v \
../src/jpeg_idctx.v \
../src/jpeg_idcty.v \
../src/jpeg_idct.v \
../src/jpeg_ycbcr_mem.v \
../src/jpeg_ycbcr2rgb.v \
../src/jpeg_ycbcr.v \
../src/jpeg_decode_fsm.v \
../src/jpeg_decode.v \
jpeg_test.v 
#jpeg_test
#-cover \


#echo "vsim -coverage -t 1ps -lib work jpeg_test" > modelsim.fdo
echo "vsim -t 1ps -lib work jpeg_test" > modelsim.fdo
echo "view wave" >> modelsim.fdo
#echo "do wave.do" >> modelsim.fdo
#echo "vcd file vcd/jpeg_test.vcd" >> modelsim.fdo
#echo "vcd add -r *" >> modelsim.fdo
echo "run 100 ms" >> modelsim.fdo
echo "quit" >> modelsim.fdo

#vsim -c -do modelsim.fdo
vsim -do modelsim.fdo

../c_model/convsim sim.dat sim.bmp 

rm -rf ./work
rm transcript
rm modelsim.fdo
