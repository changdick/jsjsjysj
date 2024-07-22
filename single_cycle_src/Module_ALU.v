`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/11 14:14:05
// Design Name: 
// Module Name: Module_ALU
// ALU模块 输入信号 操作数A 来自RF给出的data1   操作数B 来自RF给出的data2或者立即数模块给的imm        控制信号ALU_Sel
//输出信号 ALU_res 32bit计算结果    ALU_bool 1bit条件判断结果
//////////////////////////////////////////////////////////////////////////////////


module Module_ALU(
    input [31:0] dataA,
    input [31:0] dataB,
    
    input [3:0] ALU_Sel,
    
    output reg [31:0] result,
    output reg     bool

    );
    
    // ALU_Sel
//`define ALU_ADD         4'b0000
//`define ALU_SUB         4'b0001
//`define ALU_AND         4'b0010
//`define ALU_OR          4'b0011
//`define ALU_XOR         4'b0100
//`define ALU_SLL         4'b0101
//`define ALU_SRL         4'b0110
//`define ALU_SRA         4'b0111
//`define ALU_BEQ         4'b1000
//`define ALU_BNE         4'b1001
//`define ALU_BGE         4'b1010
//`define ALU_BLT         4'b1011
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
