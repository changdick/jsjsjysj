`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/23 14:05:32
// Design Name: 
// Module Name: Module_ALU
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Module_ALU(
    input [31:0] dataA,
    input [31:0] dataB,
    
    input [3:0] ALU_Sel,
    
    output reg [31:0] result,
    output reg     bool

    );
    
    always @(*) begin
        case(ALU_Sel) 
            `ALU_ADD:    result = dataA + dataB;
            `ALU_SUB:    result = dataA - dataB;
            `ALU_AND:    result = dataA & dataB;
            `ALU_OR:     result = dataA | dataB;
            `ALU_XOR:    result = dataA ^ dataB;
            `ALU_SLL:    result = dataA << dataB[4:0];
            `ALU_SRL:    result = dataA >> dataB[4:0];
            `ALU_SRA:    result = $signed(dataA) >>> dataB[4:0];        
            default:     result = dataA + dataB;
        endcase
    end
    always @(*) begin
        case(ALU_Sel)
            `ALU_BEQ:    bool = (dataA == dataB);
            `ALU_BNE:    bool = (dataA != dataB);
            `ALU_BGE:    bool = ($signed(dataA) >= $signed(dataB));
            `ALU_BLT:    bool = ($signed(dataA) < $signed(dataB));
            default:     bool = 1'b0;
        endcase
    end
    
endmodule
