//---------------------------------------------------------------------------
// File Name    : jpeg_dht.v
// Module Name  : jpeg_dht
// Description  : DHT space
// Project      : JPEG Decoder
// Belong to    : 
// Author       : H.Ishihara
// E-Mail       : hidemi@sweetcafe.jp
// HomePage     : http://www.sweetcafe.jp/
// Date         : 2006/10/01
// Rev.         : 1.1
//---------------------------------------------------------------------------
// Rev. Date         Description
//---------------------------------------------------------------------------
// 1.01 2006/10/01 1st Release
//---------------------------------------------------------------------------
`timescale 1ps / 1ps

module jpeg_dht(
    rst,
    clk,

    DataInEnable,
    DataInColor,
    DataInCount,
    DataIn,

    ColorNumber,
    TableNumber,
    ZeroTable,
    WidhtTable
    );

    input           rst;
    input           clk;

    input           DataInEnable;
    input [1:0]     DataInColor;
    input [7:0]     DataInCount;
    input [7:0]     DataIn;

    input [1:0]     ColorNumber;
    input [7:0]     TableNumber;
    output [3:0]    ZeroTable;
    output [3:0]    WidhtTable;

    // RAM
    reg [7:0]       DHT_Ydc [0:15];
    reg [7:0]       DHT_Yac [0:255];
    reg [7:0]       DHT_Cdc [0:15];
    reg [7:0]       DHT_Cac [0:255];

    reg [7:0]       ReadDataYdc;
    reg [7:0]       ReadDataYac;
    reg [7:0]       ReadDataCdc;
    reg [7:0]       ReadDataCac;

    wire [7:0]      ReadData;
    
    // RAM
    always @(posedge clk) begin
        if(DataInEnable ==1'b1 & DataInColor ==2'b00) begin
            DHT_Ydc[DataInCount[3:0]] <= DataIn;
        end
        if(DataInEnable ==1'b1 & DataInColor ==2'b01) begin
            DHT_Yac[DataInCount] <= DataIn;
        end
        if(DataInEnable ==1'b1 & DataInColor ==2'b10) begin
            DHT_Cdc[DataInCount[3:0]] <= DataIn;
        end
        if(DataInEnable ==1'b1 & DataInColor ==2'b11) begin
            DHT_Cac[DataInCount] <= DataIn;
        end
    end

    always @(posedge clk) begin
        ReadDataYdc <= DHT_Ydc[TableNumber[3:0]];
        ReadDataYac <= DHT_Yac[TableNumber];
        ReadDataCdc <= DHT_Cdc[TableNumber[3:0]];
        ReadDataCac <= DHT_Cac[TableNumber];
    end
    
    // Selector
    function [7:0] ReadDataSel;
        input [1:0]    ColorNumber;
        input [7:0]    ReadDataYdc;
        input [7:0]    ReadDataYac;
        input [7:0]    ReadDataCdc;
        input [7:0]    ReadDataCac;
        begin
            case (ColorNumber)
            2'b00: ReadDataSel = ReadDataYdc;
            2'b01: ReadDataSel = ReadDataYac;
            2'b10: ReadDataSel = ReadDataCdc;
            2'b11: ReadDataSel = ReadDataCac;
            endcase
        end
    endfunction
    
    assign ReadData = ReadDataSel(ColorNumber, ReadDataYdc, ReadDataYac, ReadDataCdc, ReadDataCac);
    
    assign ZeroTable  = ReadData[7:4];
    assign WidhtTable = ReadData[3:0];
    
endmodule
