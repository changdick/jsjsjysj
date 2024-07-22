`timescale 1ns / 1ps
////2/2///0//1//1//0//4//3///0/////////////////////////////////////////////////////////////
// Company: 
//  
// 
// Create Date: 2024/07/10 10:37:19
// Design Name: 
// Module Name: RegisterFile
// �����ź�  rs2 �Ĵ���2�ĵ�ַ ����cpu���inst[24:20]      rs1 �Ĵ���1�ĵ�ַ ����cpu���inst[19:15]       rd Ŀ�ļĴ�����ַ ����cpu��� inst[11:7]      wdata д��Ŀ�ļĴ���������  WB�׶νӻ���������
// clk ʱ���ź� ��cpu_clk  ʱ���ź�����ʱ��Ÿ���д�룬д����ʱ���·               дʹ��wen �ӿ���ģ�������ź� wenΪ1�Ż�д��
// ����ź� 32λdata1 rs1����������     32λdata2 rs2����������           ������������߼�
// 
// 
//////////////////////////////////////////////////////////////////////////////////


module RegisterFile(
    input [4:0] rs1,
    input [4:0] rs2,
    input [4:0] rd,
    input       wen,
    input [31:0] wdata,
    input       rst,
    
    output [31:0] data1,
    output [31:0] data2,
    
    input clk
    );
    
    reg [31:0] registers [31:0];
    
    // read 
    assign data1 = (rs1 == 5'b00000) ? 32'b0: registers[rs1];
    assign data2 = (rs2 == 5'b00000) ? 32'b0: registers[rs2];
    integer i;
    // write
    always@(posedge clk or posedge rst) begin
        if(rst) begin
            
            for(i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'b0;
            end
        end
        else if(wen)
            registers[rd] <= wdata;
        
    end
    
    
    
    
endmodule
