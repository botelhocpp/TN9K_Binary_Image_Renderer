//-------------------------------------------------------------------------------
// Copyright (c) 2026 Pedro Botelho
//-------------------------------------------------------------------------------
// FILE NAME : Testbench.v
// AUTHOR : Pedro Henrique Magalhães Botelho
// AUTHOR’S EMAIL : pedro.botelho@ufc.br
//-------------------------------------------------------------------------------

`timescale 1ns / 1ps

module Testbench;
    reg         i_Clk;
    reg         i_nRst;

    wire        i_Flash_Miso;
    wire        o_Hdmi_Tmds_Clk_P;
    wire        o_Hdmi_Tmds_Clk_N;
    wire [2:0]  o_Hdmi_Tmds_Data_P;
    wire [2:0]  o_Hdmi_Tmds_Data_N;
    wire        o_Flash_Clk;
    wire        o_Flash_Cs;
    wire        o_Flash_Mosi;

    parameter real T = 37.037;

    // Device under test
    Top e_TOP (
        .i_Flash_Miso(i_Flash_Miso),
        .i_Clk(i_Clk),
        .i_nRst(i_nRst),
        .o_Hdmi_Tmds_Clk_P(o_Hdmi_Tmds_Clk_P),
        .o_Hdmi_Tmds_Clk_N(o_Hdmi_Tmds_Clk_N),
        .o_Hdmi_Tmds_Data_P(o_Hdmi_Tmds_Data_P),
        .o_Hdmi_Tmds_Data_N(o_Hdmi_Tmds_Data_N),
        .o_Flash_Clk(o_Flash_Clk),
        .o_Flash_Cs(o_Flash_Cs),
        .o_Flash_Mosi(o_Flash_Mosi)
    );

    // Flash memory simulation
    FlashMemory e_FLASH_MEMORY (
        .i_Mosi(o_Flash_Mosi),
        .i_Cs(o_Flash_Cs),
        .i_Clk(o_Flash_Clk),
        .o_Miso(i_Flash_Miso)
    );

    initial i_nRst = 1'b1;
    initial i_Clk  = 1'b0;
    always  i_Clk  = #(T / 2.0) ~i_Clk;

    initial begin
        #1000000 $finish;
    end

endmodule