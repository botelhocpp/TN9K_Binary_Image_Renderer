//-------------------------------------------------------------------------------
// Copyright (c) 2026 Pedro Botelho
//-------------------------------------------------------------------------------
// FILE NAME : Testbench.v
// AUTHOR : Pedro Henrique Magalhães Botelho
// AUTHOR’S EMAIL : pedro.botelho@ufc.br
//-------------------------------------------------------------------------------

module FlashMemory (
    input   i_Mosi,
    input   i_Cs,
    input   i_Clk,
    output  o_Miso
);
    reg         r_Miso;
    reg [7:0]   r_Memory;
    reg [7:0]   r_Shift_Reg;
    reg [23:0]  r_Address;
    reg [31:0]  r_Counter;
    reg [31:0]  r_Miso_Counter;
    reg [2:0]   r_State;
    
    localparam s_IDLE       = 3'b000;
    localparam s_READ_CMD   = 3'b001;
    localparam s_READ_ADDR  = 3'b010;
    localparam s_READ_DATA  = 3'b011;
    localparam s_WRITE_CMD  = 3'b100;
    localparam s_WRITE_ADDR = 3'b101;
    localparam s_WRITE_DATA = 3'b110;
    
    always @(posedge i_Clk or posedge i_Cs) begin
        if (i_Cs) begin
            r_Shift_Reg <= 0;
            r_Address <= 0;
            r_Counter <= 0;
            r_Miso_Counter <= 7;
            r_State <= s_IDLE;
        end
        else begin
                case (r_State)
                    s_IDLE: begin
                        if (r_Counter == 8) begin
                            if (r_Shift_Reg == 8'h03) begin
                                r_State <= s_READ_ADDR;
                            end
                            r_Counter <= 0;
                        end
                        else begin
                            r_Shift_Reg <= {r_Shift_Reg[6:0], i_Mosi};
                            r_Counter <= r_Counter + 1;
                        end
                    end
                    
                    s_READ_ADDR: begin
                            if(r_Counter == 23) begin
                                r_State <= s_READ_DATA;
                            end
                            else begin
                                r_Address <= {r_Address[22:0], i_Mosi};
                                r_Counter <= r_Counter + 1;
                                r_Miso_Counter <= 7;
                            end
                    end

                    s_READ_DATA: begin
                    end
                endcase
        end
    end

    always @(negedge i_Clk or posedge i_Cs) begin
        if(i_Cs) begin
            r_Miso <= 0;
        end
        else begin
            r_Miso <= r_Memory[r_Miso_Counter];
            r_Miso_Counter <= r_Miso_Counter - 1;
            if (r_State == s_READ_DATA) begin
                if (r_Miso_Counter == 0) begin
                    r_Address <= r_Address + 1;
                    r_Miso_Counter <= 7;
                end
            end
        end
    end

    assign o_Miso = r_Miso;

    /* Test Data */
    always @ (*) begin
        case (r_Address)
            default: r_Memory = 8'h00;
        endcase
    end
endmodule
