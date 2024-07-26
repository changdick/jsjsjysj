`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: ��ˮ�ߵ� RF �͵�������ȫһ��ֱ�������ã� �ӵ�ʱ��һ����wen��rd��wdataҪ��MEM/WB�Ĵ���������ӹ���
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
