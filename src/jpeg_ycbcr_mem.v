//---------------------------------------------------------------------------
// File Name    : jpeg_ycbcr_mem.v
// Module Name  : jpeg_ycbcr_mem
// Description  : Memory for YCbCr2RGB
// Project      : JPEG Decoder
// Belong to    : 
// Author       : H.Ishihara
// E-Mail       : hidemi@sweetcafe.jp
// HomePage     : http://www.sweetcafe.jp/
// Date         : 2006/10/01
// Rev.         : 2.00
//---------------------------------------------------------------------------
// Rev. Date       Description
//---------------------------------------------------------------------------
// 1.01 2006/10/01 1st Release
// 1.02 2006/10/04 remove a WriteData,WriteDataA,WriteDataB wires.
// 2.00 2007/03/25 Replace to RAM from D-FF
//---------------------------------------------------------------------------
`timescale 1ps / 1ps

module jpeg_ycbcr_mem(
    rst,
    clk,

    DataInit,

    DataInEnable,
    DataInColor,
    DataInPage,
    DataInCount,
    Data0In,
    Data1In,

    DataOutEnable,
    DataOutAddress,
    DataOutRead,
    DataOutY,
    DataOutCb,
    DataOutCr
);
    
    input           rst;
    input           clk;
    
    input           DataInit;
   
    input           DataInEnable;
    input [2:0]     DataInColor;
    input [2:0]     DataInPage;
    input [1:0]     DataInCount;
    input [8:0]     Data0In;
    input [8:0]     Data1In;

    output          DataOutEnable;    
    input [7:0]     DataOutAddress;
    input           DataOutRead;
    output [8:0]    DataOutY;
    output [8:0]    DataOutCb;
    output [8:0]    DataOutCr;
    
    reg [8:0]       MemYA  [0:511];
    reg [8:0]       MemYB  [0:511];
    reg [8:0]       MemCbA [0:127];
    reg [8:0]       MemCbB [0:127];
    reg [8:0]       MemCrA [0:127];
    reg [8:0]       MemCrB [0:127];
    
    reg [1:0]       WriteBank, ReadBank;

    wire [5:0]      DataInAddress;
    
    assign DataInAddress = {DataInPage, DataInCount};

    // Bank
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            WriteBank <= 2'd0;
            ReadBank <= 2'd0;
        end else begin
            if(DataInit) begin
                WriteBank <= 2'd0;
            end else if(DataInEnable && (DataInAddress == 5'h1F) && (DataInColor == 3'b101)) begin
                WriteBank <= WriteBank + 2'd1;
            end
            if(DataInit) begin
                ReadBank <= 2'd0;
            end else if(DataOutRead && (DataOutAddress == 8'hFF)) begin
                ReadBank <= ReadBank + 2'd1;
            end
        end
    end

    wire [6:0]      WriteAddressA;
    wire [6:0]      WriteAddressB;
    
    function [6:0] F_WriteAddressA;
        input [2:0]    DataInColor;
    	input [2:0]    DataInPage;
    	input [1:0]    DataInCount;
        begin
            F_WriteAddressA[6]   = DataInColor[1];
            if(DataInColor[2] == 1'b0) begin
                F_WriteAddressA[5:4] = DataInCount[1:0];
                F_WriteAddressA[3]   = DataInColor[0] & ~DataInColor[2];
            end else begin
                F_WriteAddressA[5]  = 1'b0;
                F_WriteAddressA[4:3] = DataInCount[1:0];
            end
            F_WriteAddressA[2:0] = DataInPage[2:0];
        end
    endfunction
    
    function [6:0] F_WriteAddressB;
        input [2:0]    DataInColor;
    	input [2:0]    DataInPage;
    	input [1:0]    DataInCount;
        begin
            F_WriteAddressB[6]   = DataInColor[1];
            if(DataInColor[2] == 1'b0) begin
                F_WriteAddressB[5:4] = ~DataInCount[1:0];
                F_WriteAddressB[3]   = DataInColor[0] & ~DataInColor[2];
            end else begin
                F_WriteAddressB[5]   = 1'b0;
                F_WriteAddressB[4:3] = ~DataInCount[1:0];
            end
            F_WriteAddressB[2:0] = DataInPage[2:0];
        end
    endfunction

    assign WriteAddressA = F_WriteAddressA(DataInColor, DataInPage, DataInCount);
    assign WriteAddressB = F_WriteAddressB(DataInColor, DataInPage, DataInCount);

    always @(posedge clk) begin
        if(DataInColor[2] == 1'b0 & DataInEnable == 1'b1) begin
            MemYA[{WriteBank, WriteAddressA}] <= Data0In;
            MemYB[{WriteBank, WriteAddressB}] <= Data1In;
        end
    end
    
    always @(posedge clk) begin
        if(DataInColor == 3'b100 & DataInEnable == 1'b1) begin
            MemCbA[{WriteBank, WriteAddressA[4:0]}] <= Data0In;
            MemCbB[{WriteBank, WriteAddressB[4:0]}] <= Data1In;
        end
    end
    
    always @(posedge clk) begin
        if(DataInColor == 3'b101 & DataInEnable == 1'b1) begin
            MemCrA[{WriteBank, WriteAddressA[4:0]}] <= Data0In;
            MemCrB[{WriteBank, WriteAddressB[4:0]}] <= Data1In;
        end
    end
    
    reg [8:0] ReadYA;
    reg [8:0] ReadYB;
    reg [8:0] ReadCbA;
    reg [8:0] ReadCbB;
    reg [8:0] ReadCrA;
    reg [8:0] ReadCrB;
    
    reg [7:0] RegAdrs;
    
    always @(posedge clk) begin
        RegAdrs <= DataOutAddress;

        ReadYA  <= MemYA[{ReadBank, DataOutAddress[7],DataOutAddress[5:0]}];
        ReadYB  <= MemYB[{ReadBank, DataOutAddress[7],DataOutAddress[5:0]}];
        
        ReadCbA <= MemCbA[{ReadBank, DataOutAddress[6:5],DataOutAddress[3:1]}];
        ReadCrA <= MemCrA[{ReadBank, DataOutAddress[6:5],DataOutAddress[3:1]}];
        
        ReadCbB <= MemCbB[{ReadBank, DataOutAddress[6:5],DataOutAddress[3:1]}];
        ReadCrB <= MemCrB[{ReadBank, DataOutAddress[6:5],DataOutAddress[3:1]}];
    end
    
    assign DataOutEnable = (WriteBank != ReadBank);
    assign DataOutY  = (RegAdrs[6] ==1'b0)?ReadYA:ReadYB;
    assign DataOutCb = (RegAdrs[7] ==1'b0)?ReadCbA:ReadCbB;
    assign DataOutCr = (RegAdrs[7] ==1'b0)?ReadCrA:ReadCrB;
      
endmodule
