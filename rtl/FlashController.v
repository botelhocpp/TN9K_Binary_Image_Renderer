//-------------------------------------------------------------------------------
// Copyright (c) 2026 Pedro Botelho
//-------------------------------------------------------------------------------
// FILE NAME : Controller.v
// AUTHOR : Pedro Henrique Magalhães Botelho
// AUTHOR’S EMAIL : pedro.botelho@ufc.br
//-------------------------------------------------------------------------------
 
module FlashController (
    input         i_Miso,
    input  [23:0] i_Read_Addr,
    input         i_Output_Enable,
    input         i_Clk,
    input         i_Rst,
    output        o_Clk,
    output [15:0] o_Data,
    output        o_Ready,
    output        o_Mosi,
    output        o_Cs
);
    // PUYA Flash commands
    parameter READ_COMMAND    = 8'h03;

    // FSM states
    parameter s_IDLE          = 3'd0;
    parameter s_LOAD_COMMAND  = 3'd1;
    parameter s_LOAD_ADDRESS  = 3'd2;
    parameter s_TRANSMIT      = 3'd3;
    parameter s_RECEIVE       = 3'd4;
    parameter s_DONE          = 3'd5;
    
    // Input values
    reg [23:0]  r_Address;

    // Internal FSM registers
    reg [7:0]   r_Byte_Out;
    reg [1:0]   r_Byte_Num;
    reg [23:0]  r_Input_Data_Shift;
    reg [23:0]  r_Output_Data_Shift;
    reg [8:0]   r_Bits_To_Send;
    reg [16:0]  r_Counter;
    reg [2:0]   r_State;
    reg [2:0]   r_Return_State;

    // Outputs
    reg         r_Clk;
    reg [15:0]  r_Data;
    reg         r_Ready;
    reg         r_Mosi;
    reg         r_Cs;

    always @(posedge i_Rst or posedge i_Clk) begin
        if(i_Rst) begin
            r_Byte_Out          <= 8'b0;
            r_Byte_Num          <= 2'b0;
            r_Address           <= 24'b0;
            r_Input_Data_Shift  <= 24'b0;
            r_Output_Data_Shift <= 24'b0;
            r_Bits_To_Send      <= 9'b0;
            r_Counter           <= 17'b0;
            r_State             <= 3'b0;
            r_Return_State      <= 3'b0;
            r_Clk               <= 1'b0;
            r_Data              <= 16'b0;
            r_Ready             <= 1'b0;
            r_Mosi              <= 1'b0;
            r_Cs                <= 1'b0;
        end
        else begin
            case (r_State)
                s_IDLE: begin
                    r_Cs    <= 1'b1;
                    r_Ready <= 1'b0;
                    if (i_Output_Enable) begin
                        r_Address   <= i_Read_Addr;
                        r_State     <= s_LOAD_COMMAND;
                        r_Counter   <= 16'b0;
                        r_Byte_Out  <= 8'b0;
                    end
                end

                s_LOAD_COMMAND: begin
                    r_Cs                        <= 1'b0;
                    r_Output_Data_Shift[23-:8]  <= READ_COMMAND;
                    r_Bits_To_Send              <= 9'd8;
                    r_State                     <= s_TRANSMIT;
                    r_Return_State              <= s_LOAD_ADDRESS;
                end

                s_TRANSMIT: begin
                    if (r_Counter == 16'd0) begin
                        r_Clk               <= 1'b0;
                        r_Mosi              <= r_Output_Data_Shift[23];
                        r_Output_Data_Shift <= {r_Output_Data_Shift[22:0], 1'b0};
                        r_Bits_To_Send      <= r_Bits_To_Send - 9'd1;
                        r_Counter           <= 16'd1;
                    end
                    else begin
                        r_Counter   <= 16'd0;
                        r_Clk       <= 1'b1;
                        if (r_Bits_To_Send == 9'd0) begin
                            r_State <= r_Return_State;
                        end
                    end
                end

                s_LOAD_ADDRESS: begin
                    r_Output_Data_Shift <= r_Address;
                    r_Bits_To_Send      <= 9'd24;
                    r_State             <= s_TRANSMIT;
                    r_Return_State      <= s_RECEIVE;
                    r_Byte_Num          <= 2'd0;
                end

                s_RECEIVE: begin
                    if (r_Counter[0] == 1'b0) begin
                        r_Clk       <= 1'b0;
                        r_Counter   <= r_Counter + 16'd1;

                        if (r_Counter[3:0] == 4'd0 && r_Counter > 16'd0) begin
                            r_Counter   <= 16'd0;
                            r_Byte_Num  <= r_Byte_Num + 2'd1;

                            if (r_Byte_Num == 2'd1) begin
                                r_Data  <= {r_Input_Data_Shift[7:0], r_Input_Data_Shift[15:8]};
                                r_State <= s_DONE;
                            end
                        end
                    end
                    else begin
                        r_Clk               <= 1'b1;
                        r_Input_Data_Shift  <= {r_Input_Data_Shift[14:0], i_Miso};
                        r_Counter           <= r_Counter + 16'd1;
                    end
                end

                s_DONE: begin
                    r_Ready <= 1'b1;
                    r_Cs    <= 1'b1;
                    r_State <= s_IDLE;
                end
            endcase
        end
    end

    // Assign outputs
    assign o_Clk    = r_Clk;
    assign o_Data   = r_Data;
    assign o_Ready  = r_Ready;
    assign o_Mosi   = r_Mosi;
    assign o_Cs     = r_Cs;

endmodule
