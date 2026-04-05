//-------------------------------------------------------------------------------
// Copyright (c) 2026 Pedro Botelho
//-------------------------------------------------------------------------------
// FILE NAME : Controller.v
// AUTHOR : Pedro Henrique Magalhães Botelho
// AUTHOR’S EMAIL : pedro.botelho@ufc.br
//-------------------------------------------------------------------------------

module Controller (
    input  [15:0]   i_Flash_Data,
    input           i_Flash_Ready,
    input           i_Clk,
    input           i_Rst,
    output [23:0]   o_Flash_Read_Addr,
    output [31:0]   o_Bram_Write_Addr,
    output          o_Flash_Output_Enable,
    output          o_Bram_Write_Enable,
    output [15:0]   o_Bram_Data
);
    parameter s_READ_FLASH  = 4'd0;
    parameter s_WRITE_BRAM  = 4'd1;
    parameter s_IDLE        = 4'd2;

    // FSM internal registers
    reg  [3:0]      r_State;
    reg  [23:0]     r_Flash_Read_Addr;
    reg  [31:0]     r_Bram_Write_Addr;

    // FSM internal registers control
    reg             r_Increment_Flash_Read_Addr;
    reg             r_Increment_Bram_Write_Addr;
    reg             r_Load_Flash_Data;

    // Output values
    reg             r_Flash_Output_Enable;
    reg             r_Bram_Write_Enable;
    reg             r_Bram_Output_Enable;
    reg  [15:0]     r_Flash_Data;

    // Others
    wire            w_Is_Flash_Done = (r_Bram_Write_Addr == 19200 - 1);

    // Next state logic
    always @ (posedge i_Clk or posedge i_Rst) begin
        if(i_Rst) begin
            r_State <= s_READ_FLASH;
        end
        else begin
            case(r_State)
                s_READ_FLASH: begin
                    if(i_Flash_Ready) begin
                        r_State <= s_WRITE_BRAM;
                    end
                end

                s_WRITE_BRAM: begin
                    if(w_Is_Flash_Done) begin
                        r_State <= s_IDLE;
                    end
                    else begin
                        r_State <= s_READ_FLASH;
                    end
                end

                default: begin
                end
            endcase
        end
    end

    // Internal register logic
    always @ (posedge i_Clk or posedge i_Rst) begin
        if(i_Rst) begin
            r_Flash_Read_Addr <= 24'h100000;
            r_Bram_Write_Addr <= 32'h0;
            r_Flash_Data <= 16'h0;
        end
        else begin
            // Flash Read Address register
            if(r_Increment_Flash_Read_Addr) begin
                r_Flash_Read_Addr <= r_Flash_Read_Addr + 24'h2;
            end

            // BRAM Write Address register
            if(r_Increment_Bram_Write_Addr) begin
                r_Bram_Write_Addr <= r_Bram_Write_Addr + 1;
            end

            // Flash read data register
            if(r_Load_Flash_Data) begin
                r_Flash_Data <= i_Flash_Data;
            end
        end
    end

    // Output logic
    always @ (*) begin    
        // FSM internal registers control
        r_Increment_Flash_Read_Addr = 1'b0;
        r_Increment_Bram_Write_Addr = 1'b0;
        r_Load_Flash_Data = 1'b0;

        // Output values
        r_Flash_Output_Enable = 1'b0;
        r_Bram_Write_Enable = 1'b0;

        case(r_State)
            s_READ_FLASH: begin
                if(i_Flash_Ready) begin
                    r_Increment_Flash_Read_Addr = 1'b1;
                    r_Load_Flash_Data = 1'b1;
                end
                else begin
                    r_Flash_Output_Enable = 1'b1;
                end
            end

            s_WRITE_BRAM: begin
                r_Bram_Write_Enable = 1'b1;
                r_Increment_Bram_Write_Addr = 1'b1;
            end

            default: begin
            end
        endcase
    end

    // Assign outputs
    assign o_Flash_Read_Addr = r_Flash_Read_Addr;
    assign o_Bram_Write_Addr = r_Bram_Write_Addr;
    assign o_Flash_Output_Enable = r_Flash_Output_Enable;
    assign o_Bram_Write_Enable = r_Bram_Write_Enable;
    assign o_Bram_Data = r_Flash_Data;

endmodule
