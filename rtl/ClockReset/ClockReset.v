//-------------------------------------------------------------------------------
// Copyright (c) 2026 Pedro Botelho
//-------------------------------------------------------------------------------
// FILE NAME : ClockReset.v
// AUTHOR : Pedro Henrique Magalhães Botelho
// AUTHOR’S EMAIL : pedro.botelho@ufc.br
//-------------------------------------------------------------------------------

module ClockReset (
    input i_Clk,
    input i_nRst,
    output o_Rst,
    output o_Fast_Clk,
    output o_Slow_Clk
);
    wire w_Rst;
    wire w_Clk_Lock;
    wire w_Fast_Clk;
    wire w_Slow_Clk;

    // Generate fast (~126 MHz) and slow (~25.2 MHz) clocks
    ClockTree e_CLOCK_CONTROL (
        .i_Clk(i_Clk),
        .o_Clk_Lock(w_Clk_Lock),
        .o_Fast_Clk(w_Fast_Clk),
        .o_Slow_Clk(w_Slow_Clk)
    );

    // Generate a reset pulse at power-on
    PowerOnReset e_RESET (
        .i_nRst(i_nRst),
        .i_Clk(i_Clk),
        .o_Rst(w_Rst)
    );

    assign o_Rst = w_Rst || !w_Clk_Lock;
    assign o_Fast_Clk = w_Fast_Clk;
    assign o_Slow_Clk = w_Slow_Clk;
endmodule
