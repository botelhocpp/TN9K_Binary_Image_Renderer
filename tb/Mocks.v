//-------------------------------------------------------------------------------
// Copyright (c) 2026 Pedro Botelho
//-------------------------------------------------------------------------------
// FILE NAME : Mocks.v
// AUTHOR : Pedro Henrique Magalhães Botelho
// AUTHOR’S EMAIL : pedro.botelho@ufc.br
//-------------------------------------------------------------------------------

module rPLL #(
    parameter FCLKIN = "27",
    parameter IDIV_SEL = 0, 
    parameter FBDIV_SEL = 0,
    parameter ODIV_SEL = 0,
    parameter DYN_SDIV_SEL = 0
) (
    input CLKIN,
    input RESET,
    input RESET_P,
    input CLKFB,
    output CLKOUT,
    output LOCK
);
    assign CLKOUT = CLKIN;
    assign LOCK = 1'b1;
endmodule

module CLKDIV # (
    parameter DIV_MODE = "5"
) (
    input HCLKIN,
    input RESETN,
    output CLKOUT
);
    assign CLKOUT = HCLKIN; 
endmodule

module OSER10 (
    input D0,
    input D1,
    input D2,
    input D3,
    input D4, 
    input D5,
    input D6,
    input D7,
    input D8,
    input D9,
    input PCLK,
    input FCLK,
    input RESET,
    output Q
);
    assign Q = D0;
endmodule

module ELVDS_OBUF (
    input I, 
    output O,
    output OB
);
    assign O = I;
    assign OB = ~I;
endmodule