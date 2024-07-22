`timescale 1ns / 1ps
`include "defines.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/10 11:01:07
// 立即数生成模块 从指令中提取立即数进行符号扩展输出
//输入 指令的[31:7]字段  控制模块的ImmSel信号
// 输出 imm 32位立即数 送入ALU的输入端（和RF输出的data2要做一个选择）， 送入NPC的Offset端
// 
//////////////////////////////////////////////////////////////////////////////////


module ImmGenerator(
    input [31:7] din,
    input [2:0]  immsel,
    output reg [31:0] imm

    );
    always @(*) begin
        case(immsel)
            `ImmSel_I: imm = {{20{din[31]}} , din[31:20]};
            `ImmSel_S: imm = {{20{din[31]}} , din[31:25] , din[11:7]};
            `ImmSel_B: imm = {{20{din[31]}} , din[7] , din[30:25] , din[11:8] , 1'b0};
            `ImmSel_U: imm = {din[31:12] , 12'b0};
            `ImmSel_J: imm = {{12{din[31]}} , din[19:12] , din[20], din[30:21], 1'b0};
            `ImmSel_ISHIFT: imm = {27'b0, din[24:20]};
            default: imm = {{20{din[31]}} , din[31:20]};
        endcase
    end
    
    
    
    
endmodule
