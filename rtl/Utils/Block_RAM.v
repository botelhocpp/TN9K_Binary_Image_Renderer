//-------------------------------------------------------------------------------
// Copyright (c) 2026 Pedro Botelho
//-------------------------------------------------------------------------------
// FILE NAME : Block_RAM.v
// AUTHOR : Pedro Henrique Magalhães Botelho
// AUTHOR’S EMAIL : pedro.botelho@ufc.br
//-------------------------------------------------------------------------------

module Block_RAM # (
    parameter integer N = 16,
    parameter integer M = 19200
) (
    input  [N-1:0]  i_Data,
    input  [31:0]   i_Read_Addr,
    input  [31:0]   i_Write_Addr,
    input           i_Clk,
    input           i_Write_Enable,
    input           i_Output_Enable,
    output [N-1:0]  o_Data
);
    reg [N-1:0] r_Data;

    (* ram_style = "block" *) reg [N-1:0] r_Contents [0:M-1];

    always @(posedge i_Clk) begin
        if(i_Write_Enable) begin
            r_Contents[i_Write_Addr] <= i_Data;
        end

        if(i_Output_Enable) begin
            r_Data <= r_Contents[i_Read_Addr];
        end
    end

    assign o_Data = r_Data;

endmodule
