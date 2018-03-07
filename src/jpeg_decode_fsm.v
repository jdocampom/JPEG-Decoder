//---------------------------------------------------------------------------
// File Name    : jpeg_decode_fsm.v
// Module Name  : jpeg_decode_fsm
// Description  : Decode Maker
// Project      : JPEG Decoder
// Belong to    : 
// Author       : H.Ishihara
// E-Mail       : hidemi@sweetcafe.jp
// HomePage     : http://www.sweetcafe.jp/
// Date         : 2008/02/27
// Rev.         : 2.00
//---------------------------------------------------------------------------
// Rev. Date             Description
//---------------------------------------------------------------------------
// 1.01 2006/10/01 1st Release
// 1.02 2006/10/04 Remove a HmOldData register.
//                                              When reset, clear a ReadDqtTable register.
// 1.03 2007/04/11 Remove JpegDecodeStart
//                 Exchange StateMachine(Add ImageData)
//                 Remove JpegDecodeStart
// 2.00 2008/02/27 Exchange State Machine
//---------------------------------------------------------------------------
`timescale 1ps / 1ps
        
module jpeg_decode_fsm(
    rst,
    clk,

    // From FIFO
    DataInEnable,
    DataIn,
   
    JpegDecodeIdle,         // Deocder Process Idle(1:Idle, 0:Run)
   
    OutWidth,
    OutHeight,
    OutBlockWidth,
    OutEnable,
    OutPixelX,
    OutPixelY,
   
    //
    DqtEnable,
    DqtTable,
    DqtCount,
    DqtData,
   
    //
    DhtEnable,
    DhtTable,
    DhtCount,
    DhtData,
   
    //
    HuffmanEnable,
    HuffmanTable,
    HuffmanCount,
    HuffmanData,
    HuffmanStart,
   
    //
    ImageEnable,
   
    //
    UseByte,
    UseWord
);
    
    input           rst;
    input           clk;
    
    input           DataInEnable;
    input [31:0]    DataIn;
    
    output          JpegDecodeIdle;
    
    output [15:0]   OutWidth;
    output [15:0]   OutHeight;
    output [11:0]   OutBlockWidth;
    input           OutEnable;
    input [15:0]    OutPixelX;
    input [15:0]    OutPixelY;
    
    output          DqtEnable;
    output          DqtTable;
    output [5:0]    DqtCount;
    output [7:0]    DqtData;
    
    output          DhtEnable;
    output [1:0]    DhtTable;
    output [7:0]    DhtCount;
    output [7:0]    DhtData;
    
    //
    output          HuffmanEnable;
    output [1:0]    HuffmanTable;
    output [3:0]    HuffmanCount;
    output [15:0]   HuffmanData;
    output [7:0]    HuffmanStart;
    
    //
    output          ImageEnable;
    
    //
    output          UseByte;
    output          UseWord;
    
    //--------------------------------------------------------------------------
    // Read Maker from Jpeg Data
    //--------------------------------------------------------------------------
    // State Machine Parameter
    parameter S_Idle            = 5'd0;
    parameter S_GetMarker       = 5'd1;
    parameter S_ImageData       = 5'd2;
    // APP Segment
    parameter S_APPLength       = 5'd3;
    parameter S_APPRead         = 5'd4;
    // DQT Segment
    parameter S_DQTLength       = 5'd5;
    parameter S_DQTTable        = 5'd6;
    parameter S_DQTRead         = 5'd7;
    // DHT Segmen
    parameter S_DHTLength       = 5'd8;
    parameter S_DHTTable        = 5'd9;
    parameter S_DHTMakeHm0      = 5'd10;
    parameter S_DHTMakeHm1      = 5'd11;
    parameter S_DHTMakeHm2      = 5'd12;
    parameter S_DHTReadTable    = 5'd13;
    // SOS Segment
    parameter S_SOSLength       = 5'd14;
    parameter S_SOSRead0        = 5'd15;
    parameter S_SOSRead1        = 5'd16;
    parameter S_SOSRead2        = 5'd17;
    parameter S_SOSRead3        = 5'd18;
    parameter S_SOSRead4        = 5'd19;
    parameter S_SOFLength       = 5'd20;
    parameter S_SOFRead0        = 5'd21;
    parameter S_SOFReadY        = 5'd22;
    parameter S_SOFReadX        = 5'd23;
    parameter S_SOFReadComp     = 5'd24;
    parameter S_SOFMakeBlock0   = 5'd25;
    parameter S_SOFMakeBlock1   = 5'd26;
    
    reg [4:0]       State;
    //wire            ImageEnable;
    reg [15:0]      ReadCount;

    reg [15:0]      JpegWidth;
    reg [15:0]      JpegHeight;

    reg             ReadDqtTable;
    reg [1:0]       ReadDhtTable;

    reg [15:0]      HmShift;
    reg [15:0]      HmData;
    reg [7:0]       HmMax;
    reg [7:0]       HmCount;
    reg             HmEnable;

    reg [15:0]      JpegBlockWidth;
    reg [15:0]      JpegBlockHeight;
    
    reg             ImageEnable;

    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            State           <= S_Idle;
            ReadCount       <= 16'd0;
            JpegWidth       <= 16'd0;
            JpegHeight      <= 16'd0;
            ReadDqtTable    <= 1'b0;
            ReadDhtTable    <= 2'd0;
            HmShift         <= 16'd0;
            HmData          <= 16'd0;
            HmMax           <= 8'd0;
            HmCount         <= 8'd0;
            HmEnable        <= 1'b0;
            JpegBlockWidth  <= 16'd0;
            JpegBlockHeight <= 16'd0;
            ImageEnable     <= 1'b0;
        end else begin
            case(State)
                S_Idle: begin
                    if(DataInEnable == 1'b1) begin
                        State   <= S_GetMarker;
                    end
                end
                // Get Marker(with Header)
                S_GetMarker: begin
                    if(DataInEnable == 1'b1) begin
                        case(DataIn[31:16])
                            16'hFFD8: begin         // SOI Segment
                                State <= S_GetMarker;
                            end
                            16'hFFE0: begin         // APP0 Segment
                                State <= S_APPLength;
                            end
                            16'hFFDB: begin         // DQT Segment
                                State <= S_DQTLength;
                            end
                            16'hFFC4: begin         // DHT Segment
                                State <= S_DHTLength;
                            end
                            16'hFFC0: begin         // SOF0 Segment
                                State <= S_SOFLength;
                            end
                            16'hFFDA: begin         // SOS Segment
                                State <= S_SOSLength;
                            end
                            //16'hFFDD: begin       // DRI Segment
                            //      State <= S_DRI;
                            //end
                            //16'hFFDx: begin       // RSTn Segment
                            //      State <= S_RST;
                            //end
                            //16'hFFD9: begin       // EOI Segment
                            //      State <= S_EOI;
                            //end
                            default: begin
                                State <= S_APPLength;
                            end
                        endcase
                    end
                end
                // APP Segment
                S_APPLength: begin
                    if(DataInEnable == 1'b1) begin
                        ReadCount <= DataIn[31:16] -16'd2;
                        State     <= S_APPRead;
                    end
                end
                S_APPRead: begin
                    if(DataInEnable == 1'b1) begin
                        if(ReadCount == 16'd1) begin
                            State <= S_GetMarker;
                        end else begin
                            ReadCount <= ReadCount -16'd1;
                        end
                    end
                end
                // DQT Segment
                S_DQTLength: begin
                    if(DataInEnable == 1'b1) begin
                        State     <= S_DQTTable;
                        ReadCount <= DataIn[31:16] -16'd2;
                    end
                end
                S_DQTTable: begin
                    if(DataInEnable == 1'b1) begin
                        State         <= S_DQTRead;
                        ReadDqtTable  <= DataIn[24];
                        ReadCount     <= 16'd0;
                    end
                end
                S_DQTRead: begin
                    if(DataInEnable == 1'b1) begin
                        if(ReadCount ==63) begin
                            State     <= S_GetMarker;
                        end
                        ReadCount     <= ReadCount +16'd1;
                    end
                end
                // DHT Segment
                S_DHTLength: begin
                    if(DataInEnable == 1'b1) begin
                        State       <= S_DHTTable;
                        ReadCount   <= DataIn[31:16];
                    end
                end
                S_DHTTable: begin
                    if(DataInEnable == 1'b1) begin
                        State <= S_DHTMakeHm0;
                        case(DataIn[31:24])
                            8'h00: ReadDhtTable <= 2'b00;
                            8'h10: ReadDhtTable <= 2'b01;
                            8'h01: ReadDhtTable <= 2'b10;
                            8'h11: ReadDhtTable <= 2'b11;
                        endcase
                    end
                    HmShift     <= 16'h8000;
                    HmData      <= 16'h0000;
                    HmMax       <= 8'h00;
                    ReadCount   <= 16'd0;
                end
                S_DHTMakeHm0: begin
                    if(DataInEnable == 1'b1) begin
                        State   <= S_DHTMakeHm1;
                        HmCount <= DataIn[31:24];
                    end
                    HmEnable    <= 1'b0;
                end
                S_DHTMakeHm1: begin
                    State   <= S_DHTMakeHm2;
                    HmMax   <= HmMax + HmCount;
                end
                S_DHTMakeHm2: begin
                    if(HmCount != 0) begin
                        HmData  <= HmData + HmShift;
                        HmCount <= HmCount -8'd1;
                    end else begin
                        if(ReadCount == 15) begin
                            State       <= S_DHTReadTable;
                            HmCount     <= 8'h00;
                        end else begin
                            HmEnable    <= 1'b1;
                            State       <= S_DHTMakeHm0;
                            ReadCount   <= ReadCount +16'd1;
                        end
                        HmShift <= HmShift >> 1;
                    end
                end
                S_DHTReadTable: begin
                    HmEnable    <= 1'b0;
                    if(DataInEnable == 1'b1) begin
                        if(HmMax == HmCount +1) begin
                            State <= S_GetMarker;
                        end
                        HmCount <= HmCount +8'd1;
                    end
                end
                // SOS Segment            
                S_SOSLength: begin
                    if(DataInEnable == 1'b1) begin                 
                        State       <= S_SOSRead0;
                        ReadCount   <= DataIn[31:16];
                    end
                end
                S_SOSRead0: begin
                    if(DataInEnable == 1'b1) begin                 
                        State       <= S_SOSRead1;
                        ReadCount   <= {8'h00,DataIn[31:24]};
                    end
                end
                S_SOSRead1: begin
                    if(DataInEnable == 1'b1) begin
                        if(ReadCount == 1) begin
                            State       <= S_SOSRead2;
                        end else begin
                            ReadCount   <= ReadCount -16'd1;
                        end
                    end
                end
                S_SOSRead2: begin
                    if(DataInEnable == 1'b1) begin                 
                        State <= S_SOSRead3;
                    end
                end
                S_SOSRead3: begin
                    if(DataInEnable == 1'b1) begin                 
                        State <= S_SOSRead4;
                    end
                end
                S_SOSRead4: begin
                    if(DataInEnable == 1'b1) begin                 
                        State       <= S_ImageData;
                        ImageEnable <= 1'b1;
                    end
                end
                // SOF0 Segment
                S_SOFLength: begin
                    if(DataInEnable == 1'b1) begin                 
                        State       <= S_SOFRead0;
                        ReadCount   <= DataIn[31:16];
                    end
                end
                S_SOFRead0: begin
                    if(DataInEnable == 1'b1) begin                 
                        State   <= S_SOFReadY;
                    end
                end
                S_SOFReadY: begin
                    if(DataInEnable == 1'b1) begin                 
                        State           <= S_SOFReadX;
                        JpegHeight      <= DataIn[31:16];
                        JpegBlockHeight <= DataIn[31:16];
                    end
                end
                S_SOFReadX: begin
                    if(DataInEnable == 1'b1) begin                 
                        State           <= S_SOFReadComp;
                        JpegWidth       <= DataIn[31:16];
                        JpegBlockWidth  <= DataIn[31:16];
                        ReadCount       <= 16'd0;
                    end
                end
                S_SOFReadComp: begin
                    if(DataInEnable == 1'b1) begin
                        if(ReadCount == 9) begin
                            State       <= S_SOFMakeBlock0;
                        end else begin
                            ReadCount   <= ReadCount +16'd1;
                        end
                    end
                end
                S_SOFMakeBlock0:begin
                    State           <= S_SOFMakeBlock1;
                    JpegBlockWidth  <= JpegBlockWidth  +16'd15;
                    JpegBlockHeight <= JpegBlockHeight +16'd15;
                end
                S_SOFMakeBlock1:begin
                    State           <= S_GetMarker;
                    JpegBlockWidth  <= JpegBlockWidth  >> 4;
                    JpegBlockHeight <= JpegBlockHeight >> 4;
                end
              
                // Image Process
                S_ImageData: begin
                    if(OutEnable & (JpegWidth == (OutPixelX +1)) & (JpegHeight == (OutPixelY +1))) begin
                        State       <= S_Idle;
                        ImageEnable <= 1'b0;
                    end
                end
            endcase
        end
    end
    
    assign UseByte = (DataInEnable == 1'b1) & ((State == S_APPRead) |
                                               (State == S_DQTRead) | (State == S_DQTTable) |
                                               (State == S_DHTTable) | (State == S_DHTMakeHm0) | (State == S_DHTReadTable) |
                                               (State == S_SOSRead0) | (State == S_SOSRead2) | (State == S_SOSRead3) | (State == S_SOSRead4) |
                                               (State == S_SOFRead0) | (State == S_SOFReadComp)
                                              );
    assign UseWord = (DataInEnable == 1'b1) & ((State == S_GetMarker) |
                                               (State == S_APPLength) |
                                               (State == S_DQTLength) |
                                               (State == S_DHTLength) |
                                               (State == S_SOSLength) | (State == S_SOSRead1) |
                                               (State == S_SOFLength) | (State == S_SOFReadX) | (State == S_SOFReadY)
                                              );

    assign JpegDecodeIdle   = (State == S_Idle);
    //assign ImageEnable      = (State == S_ImageData);

    assign OutWidth         = JpegWidth;
    assign OutHeight        = JpegHeight;
    assign OutBlockWidth    = JpegBlockWidth[11:0];
    
    assign DqtEnable        = (State == S_DQTRead);
    assign DqtTable         = ReadDqtTable;
    assign DqtCount         = ReadCount[5:0];
    assign DqtData          = DataIn[31:24];
    
    assign DhtEnable        = (State == S_DHTReadTable);
    assign DhtTable         = ReadDhtTable;
    assign DhtCount         = HmCount;
    assign DhtData          = DataIn[31:24];
    
    assign HuffmanEnable    = HmEnable;
    assign HuffmanTable     = ReadDhtTable;
    assign HuffmanCount     = ReadCount[3:0];
    assign HuffmanData      = HmData;
    assign HuffmanStart     = HmMax;

endmodule
