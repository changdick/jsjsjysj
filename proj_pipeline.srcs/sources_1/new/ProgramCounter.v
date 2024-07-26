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
    input [31:0] imm_pc,        // 但需要跳转的时候，会收到一个32位的新pc
    input  jmp,                 // 后面传来的需要跳转信号
    input  stall,              // 需要停顿信号
    
    output reg [31:0] pc
    
    );
    
    wire [31:0] next_pc = jmp ? imm_pc : pc+4;
    always @(posedge clk or posedge rst) begin
        if(rst)           pc <= 0;
        else if(stall & ~jmp)   pc <= pc;
        else              pc <= next_pc;
    end
endmodule
