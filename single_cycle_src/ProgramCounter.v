`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/10 09:44:31
// PC 32位pc寄存器 输入为 时钟信号clk, 接cpu里的的cpu_clk    |   下一个PC值din 接cpu里NPC模块输出的npc信号  | 复位信号rst 接cpu里的cpu_rst信号 |  输出为pc 接cpu里的inst_addr信号
// 
//////////////////////////////////////////////////////////////////////////////////


module ProgramCounter(
    input [31:0] din,
    input rst,
    input clk,
    
    output reg [31:0] pc
    );
    
    always @ (posedge clk or posedge rst) begin
        if (rst) 
            pc <= 32'h0;   
        
        else
            pc <= din;
    end
    
    
endmodule
