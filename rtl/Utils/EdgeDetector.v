//-------------------------------------------------------------------------------
// Copyright (c) 2026 Pedro Botelho
//-------------------------------------------------------------------------------
// FILE NAME : Top.v
// AUTHOR : Pedro Henrique Magalhães Botelho
// AUTHOR’S EMAIL : pedro.botelho@ufc.br
//-------------------------------------------------------------------------------

module EdgeDetector (
    input i_Signal,
    input i_Clk,
    input i_Rst,
    output o_Posedge,
    output o_Negedge
);
    reg r_Signal;
    reg r_Posedge;
    reg r_Negedge;

    // Transições
    always @ (posedge i_Clk or posedge i_Rst) begin
        if(i_Rst) begin
            r_Signal <= 1'b0;
            r_Posedge <= 1'b0;
            r_Negedge <= 1'b0;
        end
        else begin
            r_Signal <= i_Signal;

            if(i_Signal && !r_Signal) begin
                r_Posedge <= 1'b1;
            end
            else begin
                r_Posedge <= 1'b0;
            end

            if(!i_Signal && r_Signal) begin
                r_Negedge <= 1'b1;
            end
            else begin
                r_Negedge <= 1'b0;
            end
        end
    end

    assign o_Posedge = r_Posedge;
    assign o_Negedge = r_Negedge;

endmodule
