//-------------------------------------------------------------------------------
// Copyright (c) 2026 Pedro Botelho
//-------------------------------------------------------------------------------
// FILE NAME : HDMI_Sync.v
// AUTHOR : Pedro Henrique Magalhães Botelho
// AUTHOR’S EMAIL : pedro.botelho@ufc.br
//-------------------------------------------------------------------------------

module HDMI_Sync #(
    parameter c_FRAME_WIDTH   = 640,
    parameter c_FRAME_HEIGHT  = 480,
    parameter c_H_FRONT_PORCH = 16,
    parameter c_H_PULSE_WIDTH = 96,
    parameter c_H_BACK_PORCH  = 48,
    parameter c_V_FRONT_PORCH = 10,
    parameter c_V_PULSE_WIDTH = 2,
    parameter c_V_BACK_PORCH  = 33
) (
    input         i_Clk,
    input         i_Rst,
    output        o_Video_Enable,
    output        o_H_Sync,
    output        o_V_Sync,
    output [11:0] o_H_Pos,
    output [11:0] o_V_Pos
);

    // Constantes calculadas
    localparam integer c_H_MAX = c_FRAME_WIDTH + c_H_FRONT_PORCH + c_H_PULSE_WIDTH + c_H_BACK_PORCH;
    localparam integer c_V_MAX = c_FRAME_HEIGHT + c_V_FRONT_PORCH + c_V_PULSE_WIDTH + c_V_BACK_PORCH;
    localparam integer c_PIXEL_CLK_DIV = 10;

    // Registradores internos
    reg        r_H_Sync    = 1;
    reg        r_V_Sync    = 1;
    reg [11:0] r_H_Pos     = 0;
    reg [11:0] r_V_Pos     = 0;

    // 2. Lógica de Sincronização (H_Sync e V_Sync)
    always @(posedge i_Clk or posedge i_Rst) begin
        if(i_Rst) begin
            r_H_Sync    = 1'b1;
            r_V_Sync    = 1'b1;
            r_H_Pos     = 12'b0;
            r_V_Pos     = 12'b0;
        end 
        else begin
            // Incremento dos contadores de posição
            if (r_H_Pos == c_H_MAX - 1) begin
                r_H_Pos <= 0;
                if (r_V_Pos == c_V_MAX - 1) begin
                    r_V_Pos <= 0;
                end else begin
                    r_V_Pos <= r_V_Pos + 1;
                end
            end else begin
                r_H_Pos <= r_H_Pos + 1;
            end

            // Geração do H_Sync (Ativo em nível baixo)
            if ((r_H_Pos >= c_FRAME_WIDTH + c_H_FRONT_PORCH) && 
                (r_H_Pos < c_FRAME_WIDTH + c_H_FRONT_PORCH + c_H_PULSE_WIDTH)) begin
                r_H_Sync <= 1'b0;
            end else begin
                r_H_Sync <= 1'b1;
            end

            // Geração do V_Sync (Ativo em nível baixo)
            if ((r_V_Pos >= c_FRAME_HEIGHT + c_V_FRONT_PORCH) && 
                (r_V_Pos < c_FRAME_HEIGHT + c_V_FRONT_PORCH + c_V_PULSE_WIDTH)) begin
                r_V_Sync <= 1'b0;
            end else begin
                r_V_Sync <= 1'b1;
            end
        end
    end

    // Atribuições de saída
    assign o_H_Pos        = r_H_Pos;
    assign o_V_Pos        = r_V_Pos;
    assign o_H_Sync       = r_H_Sync;
    assign o_V_Sync       = r_V_Sync;
    assign o_Video_Enable = (r_H_Pos < c_FRAME_WIDTH && r_V_Pos < c_FRAME_HEIGHT) ? 1'b1 : 1'b0;

endmodule
