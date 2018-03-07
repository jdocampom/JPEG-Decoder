//---------------------------------------------------------------------------
// File Name   : jpeg_ycbcr.v
// Module Name : jpeg_ycbcr
// Description : Convert to RGB from YCbCr 
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
`timescale 1ps / 1ps

module jpeg_ycbcr(
    rst,
    clk,

    ProcessInit,

    DataInEnable,
    DataInPage,
    DataInCount,
    DataInIdle,
    Data0In,
    Data1In,
    DataInBlockWidth,

    OutEnable,
    OutPixelX,
    OutPixelY,
    OutR,
    OutG,
    OutB
    );

    input           rst;
    input           clk;
    
    input           ProcessInit;
    
    input           DataInEnable;
    input [2:0]     DataInPage;
    input [1:0]     DataInCount;
    output          DataInIdle;
    input [8:0]     Data0In;
    input [8:0]     Data1In;
    input [11:0]    DataInBlockWidth;
    
    output          OutEnable;
    output [15:0]   OutPixelX;
    output [15:0]   OutPixelY;
    output [7:0]    OutR;
    output [7:0]    OutG;
    output [7:0]    OutB;
    
    reg [2:0]       DataInColor;
    reg [11:0]      DataInBlockX;
    reg [11:0]      DataInBlockY;

    wire            ConvertEnable;
    wire            ConvertRead;
    wire            ConvertBank;
    wire [7:0]      ConvertAddress;
    wire [8:0]      DataY;
    wire [8:0]      DataCb;
    wire [8:0]      DataCr;
    wire [11:0]     ConvertBlockX;
    wire [11:0]     ConvertBlockY;
    
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            DataInColor  <= 3'b000;
        end else begin
            if(ProcessInit) begin
                DataInColor <= 3'b000;
            end else if(DataInEnable == 1'b1 & DataInPage == 3'b111 & DataInCount == 2'b11) begin
                if(DataInColor == 3'b101) begin
                    DataInColor <= 3'b000;
                end else begin
                    DataInColor <= DataInColor + 3'b001;
                end
            end
            
        end
    end
    
    //------------------------------------------------------------------------
    // YCbCr Memory
    //------------------------------------------------------------------------
    jpeg_ycbcr_mem u_jpeg_ycbcr_mem(
        .rst            ( rst               ),
        .clk            ( clk               ),
        
        .DataInit       ( ProcessInit       ),
        
        .DataInEnable   ( DataInEnable      ),
        .DataInColor    ( DataInColor       ),
        .DataInPage     ( DataInPage        ),
        .DataInCount    ( DataInCount       ),
        .Data0In        ( Data0In           ),
        .Data1In        ( Data1In           ),
        
        .DataOutEnable  ( ConvertEnable     ),
        .DataOutAddress ( ConvertAddress    ),
        .DataOutRead    ( ConvertRead       ),
        .DataOutY       ( DataY             ),
        .DataOutCb      ( DataCb            ),
        .DataOutCr      ( DataCr            )
    );
    //------------------------------------------------------------------------
    // YCbCr to RGB
    //------------------------------------------------------------------------
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            DataInBlockX <= 12'h000;
            DataInBlockY <= 12'h000;
        end else begin
            if(ProcessInit) begin
                DataInBlockX <= 12'h000;
                DataInBlockY <= 12'h000;
            end else if((ConvertRead == 1'b1) && (ConvertAddress == 5'h1F)) begin
                if(DataInBlockWidth == DataInBlockX +1) begin
                    DataInBlockX <= 12'h000;
                    DataInBlockY <= DataInBlockY + 12'h001;
                end else begin
                    DataInBlockX <= DataInBlockX + 12'h001;
                end
            end
        end
    end

    jpeg_ycbcr2rgb u_jpeg_yccr2rgb(
        .rst        ( rst               ),
        .clk        ( clk               ),
        
        .InEnable   ( ConvertEnable     ),
        .InRead     ( ConvertRead       ),
        .InBlockX   ( DataInBlockX      ),
        .InBlockY   ( DataInBlockY      ),
        .InAddress  ( ConvertAddress    ),
        .InY        ( DataY             ),
        .InCb       ( DataCb            ),
        .InCr       ( DataCr            ),
        
        .OutEnable  ( OutEnable         ),
        .OutPixelX  ( OutPixelX         ),
        .OutPixelY  ( OutPixelY         ),
        .OutR       ( OutR              ),
        .OutG       ( OutG              ),
        .OutB       ( OutB              )
    );
endmodule
