//-------------------------------------------------------------------------------
// Copyright (c) 2026 Pedro Botelho
//-------------------------------------------------------------------------------
// FILE NAME : HDMI_Driver.v
// AUTHOR : Pedro Henrique Magalhães Botelho
// AUTHOR’S EMAIL : pedro.botelho@ufc.br
//-------------------------------------------------------------------------------

module HDMI_Driver (
    input  [15:0]   i_Data,
    input           i_Pixel_Clk,
    input           i_Fast_Clk,
    input           i_Rst,
    output [31:0]   o_Data_Addr,
    output          o_Output_Enable,
    output          o_Tmds_Clk_P,
    output          o_Tmds_Clk_N,
    output [2:0]    o_Tmds_Data_P,
    output [2:0]    o_Tmds_Data_N
);
    wire [7:0] w_Channel_R;
    wire [7:0] w_Channel_G;
    wire [7:0] w_Channel_B;

    wire [9:0] w_Tmds_R;
    wire [9:0] w_Tmds_G;
    wire [9:0] w_Tmds_B;

    wire w_Clk_Shift;
    wire w_Tmds_R_Shift;
    wire w_Tmds_G_Shift;
    wire w_Tmds_B_Shift;

    wire w_Video_Enable;
    wire w_H_Sync;
    wire w_V_Sync;
    wire [11:0] w_X;

    reg [15:0] r_Frame;
    reg [15:0] r_Counter;
    reg [31:0] r_Data_Addr;

    // Generate the HDMI required sync pulses
    HDMI_Sync e_HDMI_SYNC (
        .i_Clk(i_Pixel_Clk),
        .i_Rst(i_Rst),
        .o_Video_Enable(w_Video_Enable),
        .o_H_Sync(w_H_Sync),
        .o_V_Sync(w_V_Sync),
        .o_H_Pos(w_X),
        .o_V_Pos()
    );

    // Encode the color channels in TMDS
    TDMS_Encoder e_TMDS_ENCODER_R (
        .i_Data(w_Channel_R),
        .i_Clk(i_Pixel_Clk),
        .i_Rst(i_Rst),
        .i_Video_Enable(w_Video_Enable),
        .i_Control_1(1'b0),
        .i_Control_0(1'b0),
        .o_Encoded_Data(w_Tmds_R)
    );
    TDMS_Encoder e_TMDS_ENCODER_G (
        .i_Data(w_Channel_G),
        .i_Clk(i_Pixel_Clk),
        .i_Rst(i_Rst),
        .i_Video_Enable(w_Video_Enable),
        .i_Control_1(1'b0),
        .i_Control_0(1'b0),
        .o_Encoded_Data(w_Tmds_G)
    );
    TDMS_Encoder e_TMDS_ENCODER_B (
        .i_Data(w_Channel_B),
        .i_Clk(i_Pixel_Clk),
        .i_Rst(i_Rst),
        .i_Video_Enable(w_Video_Enable),
        .i_Control_1(w_V_Sync),
        .i_Control_0(w_H_Sync),
        .o_Encoded_Data(w_Tmds_B)
    );

    // Clock/Data Delay Matching
    OSER10 e_OSER_CLK (
        .Q(w_Clk_Shift),
        .D0(1'b1),
        .D1(1'b1),
        .D2(1'b1),
        .D3(1'b1),
        .D4(1'b1),
        .D5(1'b0),
        .D6(1'b0),
        .D7(1'b0),
        .D8(1'b0),
        .D9(1'b0),
        .PCLK(i_Pixel_Clk),
        .FCLK(i_Fast_Clk),
        .RESET(i_Rst)
    );

    // Gowin DDR shift registers (need a x5 clock)
    OSER10 e_OSER_R (
        .Q(w_Tmds_R_Shift),  
        .D0(w_Tmds_R[0]),
        .D1(w_Tmds_R[1]),
        .D2(w_Tmds_R[2]),
        .D3(w_Tmds_R[3]),
        .D4(w_Tmds_R[4]),
        .D5(w_Tmds_R[5]),
        .D6(w_Tmds_R[6]),
        .D7(w_Tmds_R[7]),
        .D8(w_Tmds_R[8]),
        .D9(w_Tmds_R[9]),
        .PCLK(i_Pixel_Clk),
        .FCLK(i_Fast_Clk),
        .RESET(i_Rst)
    );
    OSER10 e_OSER_G (
        .Q(w_Tmds_G_Shift),  
        .D0(w_Tmds_G[0]),
        .D1(w_Tmds_G[1]),
        .D2(w_Tmds_G[2]),
        .D3(w_Tmds_G[3]),
        .D4(w_Tmds_G[4]),
        .D5(w_Tmds_G[5]),
        .D6(w_Tmds_G[6]),
        .D7(w_Tmds_G[7]),
        .D8(w_Tmds_G[8]),
        .D9(w_Tmds_G[9]),
        .PCLK(i_Pixel_Clk),
        .FCLK(i_Fast_Clk),
        .RESET(i_Rst)
    );
    OSER10 e_OSER_B (
        .Q(w_Tmds_B_Shift),  
        .D0(w_Tmds_B[0]),
        .D1(w_Tmds_B[1]),
        .D2(w_Tmds_B[2]),
        .D3(w_Tmds_B[3]),
        .D4(w_Tmds_B[4]),
        .D5(w_Tmds_B[5]),
        .D6(w_Tmds_B[6]),
        .D7(w_Tmds_B[7]),
        .D8(w_Tmds_B[8]),
        .D9(w_Tmds_B[9]),
        .PCLK(i_Pixel_Clk),
        .FCLK(i_Fast_Clk),
        .RESET(i_Rst)
    );

    // Emulated LVDS buffers
    ELVDS_OBUF e_DIFF_CLK (
        .I(w_Clk_Shift),
        .O(o_Tmds_Clk_P),
        .OB(o_Tmds_Clk_N)
    );
    ELVDS_OBUF e_DIFF_R (
        .I(w_Tmds_R_Shift),
        .O(o_Tmds_Data_P[2]),
        .OB(o_Tmds_Data_N[2])
    );
    ELVDS_OBUF e_DIFF_G (
        .I(w_Tmds_G_Shift),
        .O(o_Tmds_Data_P[1]),
        .OB(o_Tmds_Data_N[1])
    );
    ELVDS_OBUF e_DIFF_B (
        .I(w_Tmds_B_Shift),
        .O(o_Tmds_Data_P[0]),
        .OB(o_Tmds_Data_N[0])
    );

    // Internal register logic
    always @ (posedge i_Pixel_Clk or posedge i_Rst) begin
        if(i_Rst) begin
            r_Frame <= 16'd0;
            r_Counter <= 16'd0;
            r_Data_Addr <= 32'h0;
        end
        else begin
            // Counter Lógic
            if (!w_V_Sync) begin
                r_Data_Addr <= 32'd0;
                r_Counter <= 16'd0;
            end
            else if(w_Video_Enable) begin
                r_Counter <= r_Counter + 16'd1;

                if (r_Counter == 16'd14) begin
                    r_Data_Addr <= r_Data_Addr + 32'd1;
                end
                else if (r_Counter == 16'd15) begin
                    r_Counter <= 32'd0;
                end
            end
        end
    end

    // Channel decode
    assign w_Channel_R = i_Data[w_X[3:0]] ? 8'hFF : 8'h00;
    assign w_Channel_G = i_Data[w_X[3:0]] ? 8'hFF : 8'h00;
    assign w_Channel_B = i_Data[w_X[3:0]] ? 8'hFF : 8'h00;

    assign o_Data_Addr = r_Data_Addr;
    assign o_Output_Enable = 1'b1;

endmodule