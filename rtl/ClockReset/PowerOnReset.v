//-------------------------------------------------------------------------------
// Copyright (c) 2026 Pedro Botelho
//-------------------------------------------------------------------------------
// FILE NAME : PowerOnReset.v
// AUTHOR : Pedro Henrique Magalhães Botelho
// AUTHOR’S EMAIL : pedro.botelho@ufc.br
//-------------------------------------------------------------------------------

module PowerOnReset(
    input i_nRst,
    input i_Clk,
    output o_Rst
);
    reg r_Rst_Sync = 0;
    reg r_Rst = 0;

    always @ (posedge i_Clk) begin
        r_Rst_Sync <= i_nRst;
        r_Rst <= r_Rst_Sync;
    end

    assign o_Rst = ~r_Rst;
endmodule