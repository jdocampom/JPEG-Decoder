//---------------------------------------------------------------------------
// File Name   : jpeg_decode.v
// Module Name : jpeg_decode
// Description : JPEG Deocder top module
// Project     : JPEG Decoder
// Belong to   : 
// Author      : H.Ishihara
// E-Mail      : hidemi@sweetcafe.jp
// HomePage    : http://www.sweetcafe.jp/
// Date        : 2008/03/05
// Rev.        : 2.00
//---------------------------------------------------------------------------
// Rev. Date       Description
//---------------------------------------------------------------------------
// 1.01 2006/10/01 1st Release
// 1.02 2006/10/04 add ProcessIdle register
// 1.99 2007/04/11 
// 2.00 2008/03/05 New Verion
//---------------------------------------------------------------------------

`timescale 1ps / 1ps
  
// From FIFO: DataIn, DataInEnable, DataInRead
// Decoder Process Idle (1:Idle, 0:Run): JPEGDecodeIdle.

module jpeg_decode(rst, clk, DataIn, DataInEnable, DataInRead, JpegDecodeIdle, OutEnable, 
				   OutWidth, OutHeight, OutPixelX, OutPixelY, OutR, OutG, OutB);

/* Inputs and Outputs */

    input           rst;
    input           clk;
    input [31:0]    DataIn;
    input           DataInEnable;
    output          DataInRead;
    output          JpegDecodeIdle;
    output          OutEnable;
    output [15:0]   OutWidth;
    output [15:0]   OutHeight;
    output [15:0]   OutPixelX;
    output [15:0]   OutPixelY;
    output [7:0]    OutR;
    output [7:0]    OutG;
    output [7:0]    OutB;

/* Registers and Wires */

//  reg             ProcessIdle;    
    wire [31:0]     JpegData;
    wire            JpegDataEnable;
    wire            JpegDecodeIdle;
    wire            UseBit;
    wire [6:0]      UseWidth;
    wire            UseByte;
    wire            UseWord;
    wire            ImageEnable;
    wire            EnableFF00;

/* Read JPEG Data from FIFO */

    jpeg_regdata u_jpeg_regdata(
        .rst(rst),
        .clk(clk),       
// Read Data
        .DataIn         (DataIn),
        .DataInEnable   (DataInEnable),
        .DataInRead     (DataInRead),       
// DataOut
        .DataOut        (JpegData),
        .DataOutEnable  (JpegDataEnable),
// Image Processing
        .ImageEnable    (ImageEnable),
        .ProcessIdle    (JpegDecodeIdle),       
// UseData
        .UseBit         (UseBit),
        .UseWidth       (UseWidth),
        .UseByte        (UseByte),
        .UseWord        (UseWord)
        );

    //--------------------------------------------------------------------------
    // Read Maker from Jpeg Data
    //--------------------------------------------------------------------------
    wire            DqtEnable;
    wire            DqtTable;
    wire [5:0]      DqtCount;
    wire [7:0]      DqtData;
    
    wire            DhtEnable;
    wire [1:0]      DhtTable;
    wire [7:0]      DhtCount;
    wire [7:0]      DhtData;
    
    //
    wire            HuffmanEnable;
    wire [1:0]      HuffmanTable;
    wire [3:0]      HuffmanCount;
    wire [15:0]     HuffmanData;
    wire [7:0]      HuffmanStart;
    
    wire [11:0]     JpegBlockWidth;
    
    jpeg_decode_fsm u_jpeg_decode_fsm(
        .rst            ( rst               ),
        .clk            ( clk               ),
        
        // From FIFO
        .DataInEnable   ( JpegDataEnable    ),
        .DataIn         ( JpegData          ),
        
        .JpegDecodeIdle ( JpegDecodeIdle    ),
        
        .OutWidth       ( OutWidth          ),
        .OutHeight      ( OutHeight         ),
        .OutBlockWidth  ( JpegBlockWidth    ),
        .OutEnable      ( OutEnable         ),
        .OutPixelX      ( OutPixelX         ),
        .OutPixelY      ( OutPixelY         ),
        
        //
        .DqtEnable      ( DqtEnable         ),
        .DqtTable       ( DqtTable          ),
        .DqtCount       ( DqtCount          ),
        .DqtData        ( DqtData           ),
        
        //
        .DhtEnable      ( DhtEnable         ),
        .DhtTable       ( DhtTable          ),
        .DhtCount       ( DhtCount          ),
        .DhtData        ( DhtData           ),
        
        //
        .HuffmanEnable  ( HuffmanEnable     ),
        .HuffmanTable   ( HuffmanTable      ),
        .HuffmanCount   ( HuffmanCount      ),
        .HuffmanData    ( HuffmanData       ),
        .HuffmanStart   ( HuffmanStart      ),
        
        //
        .ImageEnable    ( ImageEnable       ),
        
        //
        .UseByte        ( UseByte           ),
        .UseWord        ( UseWord           )
        );
    
    
    wire            HmDecEnable;
    wire [2:0]      HmDecColor;
    wire            HmRead;
    wire [4:0]      HmAddress;
    
    wire [15:0]     HmDataA, HmDataB;
    
    
    jpeg_huffman u_jpeg_huffman(
        .rst                ( rst               ),
        .clk                ( clk               ),
        
        .ProcessInit        ( JpegDecodeIdle    ),
        
        // DQT Table
        .DqtInEnable        ( DqtEnable         ),
        .DqtInColor         ( DqtTable          ),
        .DqtInCount         ( DqtCount[5:0]     ),
        .DqtInData          ( DqtData           ),
        
        // DHT Table
        .DhtInEnable        ( DhtEnable         ),
        .DhtInColor         ( DhtTable          ),
        .DhtInCount         ( DhtCount          ),
        .DhtInData          ( DhtData           ),
        
        // Huffman Table   
        .HuffmanTableEnable ( HuffmanEnable     ),
        .HuffmanTableColor  ( HuffmanTable      ),
        .HuffmanTableCount  ( HuffmanCount      ),
        .HuffmanTableCode   ( HuffmanData       ),
        .HuffmanTableStart  ( HuffmanStart      ),
        
        // Huffman Decode
        .DataInRun          ( ImageEnable       ),
        .DataInEnable       ( JpegDataEnable    ),
        .DataIn             ( JpegData          ),
        
        // Output decode data   
        .DecodeUseBit       ( UseBit            ),
        .DecodeUseWidth     ( UseWidth          ),
        
        // Data Out
        .DataOutEnable      ( HmDecEnable       ),
        .DataOutRead        ( HmRead            ),
        .DataOutAddress     ( HmAddress         ),
        .DataOutColor       ( HmDecColor        ),
        .DataOutA           ( HmDataA           ),
        .DataOutB           ( HmDataB           )
        );
    
    wire            DctEnable;
    wire [2:0]      DctColor;
    wire [2:0]      DctPage;
    wire [1:0]      DctCount;
    wire [8:0]      Dct0Data, Dct1Data;
    
    wire [15:0]     DctWidth, DctHeight;
    wire [11:0]     DctBlockX, DctBlockY;
    
    wire            YCbCrIdle;
    
    jpeg_idct u_jpeg_idct(
        .rst            ( rst           ),
        .clk            ( clk           ),
        
        .ProcessInit    ( JpegDecodeIdle    ),
        
        .DataInEnable   ( HmDecEnable   ),
        .DataInRead     ( HmRead        ),
        .DataInAddress  ( HmAddress     ),
        .DataInA        ( HmDataA       ),
        .DataInB        ( HmDataB       ),
        
        .DataOutEnable  ( DctEnable     ),
        .DataOutPage    ( DctPage       ),
        .DataOutCount   ( DctCount      ),
        .Data0Out       ( Dct0Data      ),
        .Data1Out       ( Dct1Data      )
        );
    
    wire            ColorEnable;
    wire [15:0]     ColorPixelX, ColorPixelY;
    wire [7:0]      ColorR, ColorG, ColorB;
    jpeg_ycbcr u_jpeg_ycbcr(
        .rst                ( rst               ),
        .clk                ( clk               ),
        
        .ProcessInit        ( JpegDecodeIdle    ),
        
        .DataInEnable       ( DctEnable         ),
        .DataInPage         ( DctPage           ),
        .DataInCount        ( DctCount          ),
        .DataInIdle         ( YCbCrIdle         ),
        .Data0In            ( Dct0Data          ),
        .Data1In            ( Dct1Data          ),
        .DataInBlockWidth   ( JpegBlockWidth    ),
        
        .OutEnable          ( ColorEnable       ),
        .OutPixelX          ( ColorPixelX       ),
        .OutPixelY          ( ColorPixelY       ),
        .OutR               ( ColorR            ),
        .OutG               ( ColorG            ),
        .OutB               ( ColorB            )
        );
    // OutData
    assign OutEnable = (ImageEnable)?ColorEnable:1'b0;
    assign OutPixelX = (ImageEnable)?ColorPixelX:16'd0;
    assign OutPixelY = (ImageEnable)?ColorPixelY:16'd0;
    assign OutR      = (ImageEnable)?ColorR:8'd0;
    assign OutG      = (ImageEnable)?ColorG:8'd0;
    assign OutB      = (ImageEnable)?ColorB:8'd0;

endmodule
