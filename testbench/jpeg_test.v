//---------------------------------------------------------------------------
// File Name   : jpeg_test.v
// Module Name : jpeg_test
// Description : TestBench
// Project     : JPEG Decoder
// Belong to   : 
// Author      : H.Ishihara
// E-Mail      : hidemi@sweetcafe.jp
// HomePage    : http://www.sweetcafe.jp/
// Date        : 2006/10/01
// Rev.        : 1.1
//---------------------------------------------------------------------------
// Rev. Date       Description
//---------------------------------------------------------------------------
// 1.01 2006/10/01 1st Release
//---------------------------------------------------------------------------
// $Id: 
//---------------------------------------------------------------------------
`timescale 1ps / 1ps

module jpeg_test;
   reg rst;
   reg clk;

   reg [31:0] JPEG_MEM [0:1*1024*1024-1];

   integer    DATA_COUNT;
   
   parameter clkP = 10000; // 100MHz
   parameter clkH = clkP /2;
   parameter clkL = clkP - clkH;

   wire [31:0] JPEG_DATA;
   reg         DATA_ENABLE;
   wire        READ_ENABLE;
   wire        JPEG_IDLE;

   wire        OutEnable;
   wire [15:0] OutWidth;
   wire [15:0] OutHeight;
   wire [15:0] OutPixelX;
   wire [15:0] OutPixelY;
   wire [7:0]  OutR;
   wire [7:0]  OutG;
   wire [7:0]  OutB;

   integer     count;
   reg [23:0]  rgb_mem [0:1920*1080-1];
   
   initial begin
      count = 0;
      while(1) begin
         @(posedge clk);
         count = count +1;
      end
   end
      
   jpeg_decode u_jpeg_decode
     (
      .rst(rst),
      .clk(clk),
      
      .DataIn          (JPEG_DATA),
      .DataInEnable    (DATA_ENABLE),
      .DataInRead      (READ_ENABLE),
      .JpegDecodeIdle  (JPEG_IDLE),

      .OutEnable ( OutEnable ),
      .OutWidth  ( OutWidth  ),
      .OutHeight ( OutHeight ),
      .OutPixelX ( OutPixelX ),
      .OutPixelY ( OutPixelY ),
      .OutR      ( OutR      ),
      .OutG      ( OutG      ),
      .OutB      ( OutB      )
      );
   
   
   // Clock
   always begin
      #clkH clk = 0;
      #clkL clk = 1;
   end
    
   initial begin
      rst = 1'b0;
      repeat (3) @(posedge clk);
      rst = 1'b1;
   end

   // Read JPEG File
   initial begin
      $readmemh("test.mem",JPEG_MEM);
   end
   
   // Initial
   initial begin
      DATA_COUNT  <= 0;
      DATA_ENABLE <= 1'b0;
      wait (rst == 1'b1);
      @(posedge clk);
      $display(" Start Clock: %d",count);
      @(posedge clk);
      @(posedge clk);
      DATA_ENABLE <= 1'b1;
      forever begin
         if(READ_ENABLE == 1'b1) begin
            DATA_COUNT  <= DATA_COUNT +1;
         end
         @(posedge clk);
      end
   end // initial begin

   assign JPEG_DATA = JPEG_MEM[DATA_COUNT];
   
   integer i;

/*      
   initial begin
      @(posedge u_jpeg_decode.ImageEnable);

      $display("------------------------------");
      $display("Image Run");
      $display("------------------------------");
      $display(" DQT Y Table");
      for(i=0;i<64;i=i+1) begin
         $display(" %2d: %2x",i,u_jpeg_decode.u_jpeg_haffuman.u_jpeg_dqt.DQT_Y[i]);
      end

      $display("------------------------------");
      $display(" DQT Cb/Cr Table");
      for(i=0;i<64;i=i+1) begin
         $display(" %2d: %2x",i,u_jpeg_decode.u_jpeg_haffuman.u_jpeg_dqt.DQT_C[i]);
      end
      $display("------------------------------");
      
      $display("------------------------------");
      $display(" Haffuman Y-DC Code/Number");
      for(i=0;i<16;i=i+1) begin
         $display(" %2d: %2x,%2x",i,u_jpeg_decode.u_jpeg_haffuman.u_jpeg_hm_decode.HaffumanTable0r[i],u_jpeg_decode.u_jpeg_haffuman.u_jpeg_hm_decode.HaffumanNumber0r[i]);
      end
      $display("------------------------------");
      
      $display("------------------------------");
      $display(" Haffuman Y-DC Table");
      for(i=0;i<16;i=i+1) begin
         $display(" %2d: %2x",i,u_jpeg_decode.u_jpeg_haffuman.u_jpeg_dht.DHT_Ydc[i]);
      end
      $display("------------------------------");
      
      $display("------------------------------");
      $display(" Haffuman Y-AC Code/Number");
      for(i=0;i<16;i=i+1) begin
         $display(" %2d: %2x,%2x",i,u_jpeg_decode.u_jpeg_haffuman.u_jpeg_hm_decode.HaffumanTable1r[i],u_jpeg_decode.u_jpeg_haffuman.u_jpeg_hm_decode.HaffumanNumber1r[i]);
      end
      $display("------------------------------");
      
      $display("------------------------------");
      $display(" Haffuman Y-AC Table");
      for(i=0;i<162;i=i+1) begin
         $display(" %2d: %2x",i,u_jpeg_decode.u_jpeg_haffuman.u_jpeg_dht.DHT_Yac[i]);
      end
      $display("------------------------------");
      
      $display("------------------------------");
      $display(" Haffuman C-DC Table");
      for(i=0;i<16;i=i+1) begin
         $display(" %2d: %2x,%2x",i,u_jpeg_decode.u_jpeg_haffuman.u_jpeg_hm_decode.HaffumanTable2r[i],u_jpeg_decode.u_jpeg_haffuman.u_jpeg_hm_decode.HaffumanNumber2r[i]);
      end
      $display("------------------------------");
      
      $display("------------------------------");
      $display(" Haffuman C-DC Table");
      for(i=0;i<16;i=i+1) begin
         $display(" %2d: %2x",i,u_jpeg_decode.u_jpeg_haffuman.u_jpeg_dht.DHT_Cdc[i]);
      end
      $display("------------------------------");
      
      $display("------------------------------");
      $display(" Haffuman C-AC Table");
      for(i=0;i<16;i=i+1) begin
         $display(" %2d: %2x,%2x",i,u_jpeg_decode.u_jpeg_haffuman.u_jpeg_hm_decode.HaffumanTable3r[i],u_jpeg_decode.u_jpeg_haffuman.u_jpeg_hm_decode.HaffumanNumber3r[i]);
      end
      $display("------------------------------");
      
      $display("------------------------------");
      $display(" Haffuman C-AC Table");
      for(i=0;i<162;i=i+1) begin
         $display(" %2d: %2x",i,u_jpeg_decode.u_jpeg_haffuman.u_jpeg_dht.DHT_Cac[i]);
      end
      $display("------------------------------");
   end
*/    
/*   
   initial begin
      while(1) begin
         @(posedge clk);
         if(u_jpeg_decode.u_jpeg_haffuman.u_jpeg_hm_decode.Process == 4'h2)
           $display(" Color: %d,%d",u_jpeg_decode.u_jpeg_haffuman.u_jpeg_hm_decode.ProcessColor,
                    u_jpeg_decode.u_jpeg_haffuman.u_jpeg_hm_decode.ProcessCount);
      end
   end


   initial begin
      while(1) begin
         @(posedge clk);
         if(u_jpeg_decode.u_jpeg_haffuman.u_jpeg_hm_decode.Process == 4'h4)
           for(i=0;i<16;i=i+1) begin
              $display(" Data Code: %8x,%8x",u_jpeg_decode.u_jpeg_haffuman.u_jpeg_hm_decode.HaffumanTable[i],u_jpeg_decode.u_jpeg_haffuman.u_jpeg_hm_decode.HaffumanNumber[i]);
           end
      end
   end
*/

/*
   initial begin
      while(1) begin
         @(posedge clk);
         if(u_jpeg_decode.u_jpeg_haffuman.u_jpeg_hm_decode.Process == 4'h6)
           $display(" Wait for RAM");
      end
   end
*/
/*
   initial begin
      while(1) begin
         @(posedge clk);
         if(u_jpeg_decode.u_jpeg_haffuman.u_jpeg_hm_decode.Process == 4'h4)
           $display(" Data Code: %8x",u_jpeg_decode.u_jpeg_haffuman.u_jpeg_hm_decode.ProcessData);
      end
   end
*/
/*   
   initial begin
      while(1) begin
         @(posedge clk);
         if(u_jpeg_decode.u_jpeg_haffuman.u_jpeg_hm_decode.Process == 4'hB)
           $display(" Data Code: %d,%d,%4x,%4x,%4x,%4x,%2x,%4x,%4x,%4x,%8x",
                    u_jpeg_decode.u_jpeg_haffuman.u_jpeg_hm_decode.CodeNumber,
                    u_jpeg_decode.u_jpeg_haffuman.u_jpeg_hm_decode.ProcessCount,
                    u_jpeg_decode.u_jpeg_haffuman.u_jpeg_hm_decode.DhtNumber,
                    u_jpeg_decode.u_jpeg_haffuman.u_jpeg_hm_decode.DhtZero,
                    u_jpeg_decode.u_jpeg_haffuman.u_jpeg_hm_decode.DataNumber,
                    u_jpeg_decode.u_jpeg_haffuman.u_jpeg_hm_decode.TableCode,
                    u_jpeg_decode.u_jpeg_haffuman.u_jpeg_hm_decode.NumberCode,
                    u_jpeg_decode.u_jpeg_haffuman.u_jpeg_hm_decode.DqtData,
                    u_jpeg_decode.u_jpeg_haffuman.u_jpeg_hm_decode.OutCode,
                    u_jpeg_decode.u_jpeg_haffuman.u_jpeg_hm_decode.OutData,
                    u_jpeg_decode.u_jpeg_haffuman.u_jpeg_hm_decode.ProcessData);
      end
   end
    
    
   
   initial begin
      while(1) begin
         @(posedge clk);
         if(u_jpeg_decode.u_jpeg_haffuman.HmDecEnable == 1'b1)
              $display(" HmDec Code: %d,%4x",
                       u_jpeg_decode.u_jpeg_haffuman.HmDecCount,
                       u_jpeg_decode.u_jpeg_haffuman.HmDecData);
      end
   end
*/

/*
   initial begin
      while(1) begin
         @(posedge clk);
         if(u_jpeg_decode.u_jpeg_haffuman.HmOutEnable == 1'b1)
           for(i=0;i<64;i=i+1) begin
              $display(" Data Code: %d,%4x",i,
                       u_jpeg_decode.u_jpeg_haffuman.u_jpeg_ziguzagu.RegData[i]);
           end
      end
   end
*/
    
/*
   initial begin
      while(1) begin
         @(posedge clk);
         if(u_jpeg_decode.u_jpeg_idct.DctXEnable == 1'b1)
           $display(" Dct Data[X]: %d,%4x,%4x",u_jpeg_decode.u_jpeg_idct.DctXCount,u_jpeg_decode.u_jpeg_idct.DctXData0r,u_jpeg_decode.u_jpeg_idct.DctXData1r);
      end
   end
   
   initial begin
      while(1) begin
         @(posedge clk);
         if(u_jpeg_decode.u_jpeg_idct.u_jpeg_idcty.Phase3Enable == 1'b1)
           $display(" Dct Data[Y2]: %d,%8x,%8x,%8x,%8x,%8x,%8x,%8x,%8x",u_jpeg_decode.u_jpeg_idct.u_jpeg_idcty.Phase3Count,u_jpeg_decode.u_jpeg_idct.u_jpeg_idcty.Phase2Reg[0],u_jpeg_decode.u_jpeg_idct.u_jpeg_idcty.Phase2Reg[1],u_jpeg_decode.u_jpeg_idct.u_jpeg_idcty.Phase2Reg[2],u_jpeg_decode.u_jpeg_idct.u_jpeg_idcty.Phase2Reg[3],u_jpeg_decode.u_jpeg_idct.u_jpeg_idcty.Phase2Reg[4],u_jpeg_decode.u_jpeg_idct.u_jpeg_idcty.Phase2Reg[5],u_jpeg_decode.u_jpeg_idct.u_jpeg_idcty.Phase3Reg[6],u_jpeg_decode.u_jpeg_idct.u_jpeg_idcty.Phase2Reg[7]);
      end
   end
   
   initial begin
      while(1) begin
         @(posedge clk);
         if(u_jpeg_decode.u_jpeg_idct.u_jpeg_idcty.Phase5Enable == 1'b1)
           $display(" Dct Data[Y5]: %d,%8x,%8x,%8x,%8x,%8x,%8x,%8x,%8x,%8x,%8x",u_jpeg_decode.u_jpeg_idct.u_jpeg_idcty.Phase5Count,u_jpeg_decode.u_jpeg_idct.u_jpeg_idcty.Phase5R0w,u_jpeg_decode.u_jpeg_idct.u_jpeg_idcty.Phase5R1w,u_jpeg_decode.u_jpeg_idct.u_jpeg_idcty.Phase3Reg[0],u_jpeg_decode.u_jpeg_idct.u_jpeg_idcty.Phase3Reg[1],u_jpeg_decode.u_jpeg_idct.u_jpeg_idcty.Phase3Reg[2],u_jpeg_decode.u_jpeg_idct.u_jpeg_idcty.Phase3Reg[3],u_jpeg_decode.u_jpeg_idct.u_jpeg_idcty.Phase3Reg[4],u_jpeg_decode.u_jpeg_idct.u_jpeg_idcty.Phase3Reg[5],u_jpeg_decode.u_jpeg_idct.u_jpeg_idcty.Phase3Reg[6],u_jpeg_decode.u_jpeg_idct.u_jpeg_idcty.Phase3Reg[7]);
      end
   end


      
   initial begin
      while(1) begin
         @(posedge clk);
         if(u_jpeg_decode.DctEnable == 1'b1)
           $display(" Dct Data[Y]: %d,%4x,%4x",u_jpeg_decode.DctCount,u_jpeg_decode.Dct0Data,u_jpeg_decode.Dct1Data);
      end
   end
*/

   integer address;
   integer fp;
   
   initial begin
      
      while(1) begin
         if(u_jpeg_decode.OutEnable == 1'b1) begin
            address = u_jpeg_decode.OutWidth * u_jpeg_decode.OutPixelY +
                      u_jpeg_decode.OutPixelX;
            /*
            $display(" RGB[%4d,%4d,%4d,%4d](%d): %3x,%3x,%3x = %2x,%2x,%2x",OutPixelX,OutPixelY,u_jpeg_decode.OutWidth,u_jpeg_decode.OutHeight,
                    address,
                    u_jpeg_decode.u_jpeg_ycbcr.u_jpeg_ycbcr2rgb.Phase3Y,
                    u_jpeg_decode.u_jpeg_ycbcr.u_jpeg_ycbcr2rgb.Phase3Cb,
                    u_jpeg_decode.u_jpeg_ycbcr.u_jpeg_ycbcr2rgb.Phase3Cr,
                    OutR,OutG,OutB);
             */
            rgb_mem[address] = {OutR,OutG,OutB};
         end
         @(posedge clk);
      end
   end
    

   initial begin
      wait(!JPEG_IDLE);
      wait(JPEG_IDLE);
      
      $display(" End Clock %d",count);
      fp = $fopen("sim.dat");
      $fwrite(fp,"%0d\n",OutWidth);
      $fwrite(fp,"%0d\n",OutHeight);
      
      for(i=0;i<OutWidth*OutHeight;i=i+1) begin
         $fwrite(fp,"%06x\n",rgb_mem[i]);
      end
      $fclose(fp);
      
      $finish();
   end
      

   

endmodule // jpeg_test
