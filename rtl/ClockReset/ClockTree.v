//-------------------------------------------------------------------------------
// Copyright (c) 2026 Pedro Botelho
//-------------------------------------------------------------------------------
// FILE NAME : ClockTree.v
// AUTHOR : Pedro Henrique Magalhães Botelho
// AUTHOR’S EMAIL : pedro.botelho@ufc.br
//-------------------------------------------------------------------------------

module ClockTree (
    input i_Clk,
    output o_Clk_Lock,
    output o_Fast_Clk,
    output o_Slow_Clk
);
    wire w_Clk_Lock;
    wire w_Clk_Pll;
    wire w_Clk_Div;

    // Generate a ~126MHz fast clock (HDMI's FCLK)
    rPLL #(
        .FCLKIN("27"),
        .IDIV_SEL(2),
        .FBDIV_SEL(13),
        .ODIV_SEL(4),
        .DYN_SDIV_SEL(4)
    ) e_PLL (
        .CLKOUT(w_Clk_Pll),
        .LOCK(w_Clk_Lock),
        .CLKIN(i_Clk),
        .RESET(1'b0),     
        .RESET_P(1'b0),
        .CLKFB(1'b0)
    );

    // Generate a ~25.2MHz pixel clock (HDMI's PCLK)
    CLKDIV #(
        .DIV_MODE("5")
    ) e_pixel_clk_gen (
        .CLKOUT(w_Clk_Div),
        .HCLKIN(w_Clk_Pll),
        .RESETN(w_Clk_Lock)
    );

    assign o_Clk_Lock = w_Clk_Lock;
    assign o_Fast_Clk = w_Clk_Pll;
    assign o_Slow_Clk = w_Clk_Div;

endmodule
