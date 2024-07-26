`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/23 19:36:44
// Design Name: 
// Module Name: ProgramCounter
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


module ProgramCounter(
    input  clk ,
    input  rst,
    input [31:0] imm_pc,        // ����Ҫ��ת��ʱ�򣬻��յ�һ��32λ����pc
    input  jmp,                 // ���洫������Ҫ��ת�ź�
    input  stall,              // ��Ҫͣ���ź�
    
    output reg [31:0] pc
    
    );
    
    wire [31:0] next_pc = jmp ? imm_pc : pc+4;
    always @(posedge clk or posedge rst) begin
        if(rst)           pc <= 0;
        else if(stall & ~jmp)   pc <= pc;
        else              pc <= next_pc;
    end
endmodule
