//---------------------------------------------------------------------------
// File Name    : jpeg_dqt.v
// Module Name  : jpeg_dqt
// Description  : DQT spcae
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

module jpeg_dqt(
    rst,
    clk,

    DataInEnable,
    DataInColor,
    DataInCount,
    DataIn,

    TableColor,
    TableNumber,
    TableData
);

    input           rst;
    input           clk;

    input           DataInEnable;
    input           DataInColor;
    input [5:0]     DataInCount;
    input [7:0]     DataIn;

    input           TableColor;
    input  [5:0]    TableNumber;
    output [7:0]    TableData;

    // RAM
    reg [7:0]       DQT_Y [0:63];
    reg [7:0]       DQT_C [0:63];

    // RAM
    always @(posedge clk) begin
        if(DataInEnable ==1'b1 && DataInColor ==1'b0) begin
            DQT_Y[DataInCount] <= DataIn;
        end
        if(DataInEnable ==1'b1 && DataInColor ==1'b1) begin
            DQT_C[DataInCount] <= DataIn;
        end
    end

    reg [7:0] TableDataY;
    reg [7:0] TableDataC;

    // RAM out
    always @(posedge clk) begin
        TableDataY <= DQT_Y[TableNumber];
        TableDataC <= DQT_C[TableNumber];
    end

    // Selector
    assign TableData = (TableColor)?TableDataC:TableDataY;
    
endmodule
