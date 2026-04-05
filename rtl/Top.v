//-------------------------------------------------------------------------------
// Copyright (c) 2026 Pedro Botelho
//-------------------------------------------------------------------------------
// FILE NAME : Top.v
// AUTHOR : Pedro Henrique Magalhães Botelho
// AUTHOR’S EMAIL : pedro.botelho@ufc.br
//-------------------------------------------------------------------------------

module Top (
    input        i_Flash_Miso,
    input        i_Clk,
    input        i_nRst,
    output       o_Hdmi_Tmds_Clk_P,
    output       o_Hdmi_Tmds_Clk_N,
    output [2:0] o_Hdmi_Tmds_Data_P,
    output [2:0] o_Hdmi_Tmds_Data_N,
    output       o_Flash_Clk,
    output       o_Flash_Cs,
    output       o_Flash_Mosi
);
    // Clock/Reset system
    wire            w_Rst;
    wire            w_Fast_Clk;
    wire            w_Slow_Clk;

    // Controller interface
    wire [15:0]     w_Flash_Read_Data;
    wire [15:0]     w_Bram_Write_Data;
    wire            w_Flash_Ready;
    wire [23:0]     w_Flash_Read_Addr;
    wire [31:0]     w_Bram_Read_Addr;
    wire [31:0]     w_Bram_Write_Addr;
    wire            w_Flash_Output_Enable;
    wire            w_Bram_Write_Enable;
    wire            w_Bram_Output_Enable;
    wire [15:0]     w_Bram_Read_Data;

    // Generate fast (~126 MHz) and slow (~25.2 MHz) clocks and a reset pulse at power-on
    ClockReset e_CLOCK_RESET (
        .i_Clk(i_Clk),
        .i_nRst(i_nRst),
        .o_Rst(w_Rst),
        .o_Fast_Clk(w_Fast_Clk),
        .o_Slow_Clk(w_Slow_Clk)
    );

    // Controls HDMI display operation
    Controller e_CONTROLLER (
        .i_Flash_Data(w_Flash_Read_Data),
        .i_Flash_Ready(w_Flash_Ready),
        .i_Clk(w_Slow_Clk),
        .i_Rst(w_Rst),
        .o_Flash_Read_Addr(w_Flash_Read_Addr),
        .o_Bram_Write_Addr(w_Bram_Write_Addr),
        .o_Flash_Output_Enable(w_Flash_Output_Enable),
        .o_Bram_Write_Enable(w_Bram_Write_Enable),
        .o_Bram_Data(w_Bram_Write_Data)
    );

    // Controls the onboard SPI Flash memory
    FlashController e_FLASH_CONTROLLER (
        .i_Miso(i_Flash_Miso),
        .i_Read_Addr(w_Flash_Read_Addr),
        .i_Output_Enable(w_Flash_Output_Enable),
        .i_Clk(w_Slow_Clk),
        .i_Rst(w_Rst),      
        .o_Data(w_Flash_Read_Data),
        .o_Ready(w_Flash_Ready),
        .o_Clk(o_Flash_Clk),
        .o_Mosi(o_Flash_Mosi),
        .o_Cs(o_Flash_Cs)
    );

    // Framebuffer for the HDMI
    Block_RAM e_BLOCK_RAM (
        .i_Data(w_Bram_Write_Data),
        .i_Read_Addr(w_Bram_Read_Addr),
        .i_Write_Addr(w_Bram_Write_Addr),
        .i_Clk(w_Slow_Clk),
        .i_Write_Enable(w_Bram_Write_Enable),
        .i_Output_Enable(w_Bram_Output_Enable),
        .o_Data(w_Bram_Read_Data)
    );

    // Handle HDMI hardware
    HDMI_Driver e_HDMI_DRIVER (
        .i_Data(w_Bram_Read_Data),
        .i_Pixel_Clk(w_Slow_Clk),
        .i_Fast_Clk(w_Fast_Clk),
        .i_Rst(w_Rst),
        .o_Data_Addr(w_Bram_Read_Addr),
        .o_Output_Enable(w_Bram_Output_Enable),
        .o_Tmds_Clk_P(o_Hdmi_Tmds_Clk_P),
        .o_Tmds_Clk_N(o_Hdmi_Tmds_Clk_N),
        .o_Tmds_Data_P(o_Hdmi_Tmds_Data_P),
        .o_Tmds_Data_N(o_Hdmi_Tmds_Data_N)
    );
endmodule