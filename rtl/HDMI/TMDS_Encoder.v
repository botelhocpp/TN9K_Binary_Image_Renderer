//-------------------------------------------------------------------------------
// Copyright (c) 2026 Pedro Botelho
//-------------------------------------------------------------------------------
// FILE NAME : TDMS_Encoder.v
// AUTHOR : Pedro Henrique Magalhães Botelho
// AUTHOR’S EMAIL : pedro.botelho@ufc.br
//-------------------------------------------------------------------------------

module TDMS_Encoder (
    input  [7:0] i_Data,
    input        i_Clk,
    input        i_Rst,
    input        i_Video_Enable,
    input        i_Control_1,
    input        i_Control_0,
    output reg [9:0] o_Encoded_Data
);
    // Sinais internos
    wire [1:0] w_Control;
    reg  [8:0] w_Intermediary_Data;
    integer    w_Number_Ones_Data;
    integer    w_Number_Ones_Intermediary_Data;
    integer    w_Diff_Ones_Zeros;
    integer    v_Disparity = 0; // Registrador de disparidade acumulada

    assign w_Control = {i_Control_1, i_Control_0};

    // 1. Contagem de uns no byte de entrada
    integer i;
    always @* begin
        w_Number_Ones_Data = 0;
        for (i = 0; i < 8; i = i + 1) begin
            if (i_Data[i] == 1'b1)
                w_Number_Ones_Data = w_Number_Ones_Data + 1;
        end
    end

    // 2. Codificação XOR/XNOR para minimizar transições
    always @* begin
        if (w_Number_Ones_Data > 4 || (w_Number_Ones_Data == 4 && i_Data[0] == 1'b0)) begin
            w_Intermediary_Data[0] = i_Data[0];
            w_Intermediary_Data[1] = w_Intermediary_Data[0] ^~ i_Data[1];
            w_Intermediary_Data[2] = w_Intermediary_Data[1] ^~ i_Data[2];
            w_Intermediary_Data[3] = w_Intermediary_Data[2] ^~ i_Data[3];
            w_Intermediary_Data[4] = w_Intermediary_Data[3] ^~ i_Data[4];
            w_Intermediary_Data[5] = w_Intermediary_Data[4] ^~ i_Data[5];
            w_Intermediary_Data[6] = w_Intermediary_Data[5] ^~ i_Data[6];
            w_Intermediary_Data[7] = w_Intermediary_Data[6] ^~ i_Data[7];
            w_Intermediary_Data[8] = 1'b0;
        end else begin
            w_Intermediary_Data[0] = i_Data[0];
            w_Intermediary_Data[1] = w_Intermediary_Data[0] ^ i_Data[1];
            w_Intermediary_Data[2] = w_Intermediary_Data[1] ^ i_Data[2];
            w_Intermediary_Data[3] = w_Intermediary_Data[2] ^ i_Data[3];
            w_Intermediary_Data[4] = w_Intermediary_Data[3] ^ i_Data[4];
            w_Intermediary_Data[5] = w_Intermediary_Data[4] ^ i_Data[5];
            w_Intermediary_Data[6] = w_Intermediary_Data[5] ^ i_Data[6];
            w_Intermediary_Data[7] = w_Intermediary_Data[6] ^ i_Data[7];
            w_Intermediary_Data[8] = 1'b1;
        end
    end

    // 3. Contagem de uns nos dados intermediários
    integer j;
    always @* begin
        w_Number_Ones_Intermediary_Data = 0;
        for (j = 0; j < 8; j = j + 1) begin
            if (w_Intermediary_Data[j] == 1'b1)
                w_Number_Ones_Intermediary_Data = w_Number_Ones_Intermediary_Data + 1;
        end
        // Diferença entre uns e zeros (8 bits: uns - (8 - uns) = 2*uns - 8)
        w_Diff_Ones_Zeros = (2 * w_Number_Ones_Intermediary_Data) - 8;
    end

    // 4. Determinação da saída e disparidade (Sincronizado no Clock)
    always @(posedge i_Clk or posedge i_Rst) begin
        if(i_Rst) begin
            o_Encoded_Data <= 0;
            v_Disparity    <= 0;
        end
        else begin
            if (i_Video_Enable) begin
                if (v_Disparity == 0 || w_Number_Ones_Intermediary_Data == 4) begin
                    if (w_Intermediary_Data[8] == 1'b0) begin
                        o_Encoded_Data <= {~w_Intermediary_Data[8], w_Intermediary_Data[8], ~w_Intermediary_Data[7:0]};
                        v_Disparity    <= v_Disparity - w_Diff_Ones_Zeros;
                    end else begin
                        o_Encoded_Data <= {~w_Intermediary_Data[8], w_Intermediary_Data[8:0]};
                        v_Disparity    <= v_Disparity + w_Diff_Ones_Zeros;
                    end
                end else begin
                    if ((v_Disparity > 0 && w_Number_Ones_Intermediary_Data > 4) || 
                        (v_Disparity < 0 && w_Number_Ones_Intermediary_Data < 4)) begin
                        o_Encoded_Data <= {1'b1, w_Intermediary_Data[8], ~w_Intermediary_Data[7:0]};
                        if (w_Intermediary_Data[8] == 1'b0)
                            v_Disparity <= v_Disparity - w_Diff_Ones_Zeros;
                        else
                            v_Disparity <= v_Disparity - w_Diff_Ones_Zeros + 2;
                    end else begin
                        o_Encoded_Data <= {1'b0, w_Intermediary_Data[8:0]};
                        if (w_Intermediary_Data[8] == 1'b0)
                            v_Disparity <= v_Disparity + w_Diff_Ones_Zeros - 2;
                        else
                            v_Disparity <= v_Disparity + w_Diff_Ones_Zeros;
                    end
                end
            end else begin
                // Período de Controle (Blanking)
                case (w_Control)
                    2'b00: o_Encoded_Data <= 10'b1101010100;
                    2'b01: o_Encoded_Data <= 10'b0010101011;
                    2'b10: o_Encoded_Data <= 10'b0101010100;
                    2'b11: o_Encoded_Data <= 10'b1010101011;
                    default: o_Encoded_Data <= 10'b1101010100;
                endcase
                v_Disparity <= 0;
            end
        end
    end

endmodule
