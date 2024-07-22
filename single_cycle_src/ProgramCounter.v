`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/10 09:44:31
// PC 32λpc�Ĵ��� ����Ϊ ʱ���ź�clk, ��cpu��ĵ�cpu_clk    |   ��һ��PCֵdin ��cpu��NPCģ�������npc�ź�  | ��λ�ź�rst ��cpu���cpu_rst�ź� |  ���Ϊpc ��cpu���inst_addr�ź�
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
