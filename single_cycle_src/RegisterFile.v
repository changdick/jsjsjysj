`timescale 1ns / 1ps
////2/2///0//1//1//0//4//3///0/////////////////////////////////////////////////////////////
// Company: 
//  
// 
// Create Date: 2024/07/10 10:37:19
// Design Name: 
// Module Name: RegisterFile
// 输入信号  rs2 寄存器2的地址 接入cpu里的inst[24:20]      rs1 寄存器1的地址 接入cpu里的inst[19:15]       rd 目的寄存器地址 接入cpu里的 inst[11:7]      wdata 写入目的寄存器的数据  WB阶段接回来的数据
// clk 时钟信号 接cpu_clk  时钟信号来的时候才更新写入，写入是时序电路               写使能wen 从控制模块来的信号 wen为1才会写入
// 输出信号 32位data1 rs1读出的数据     32位data2 rs2读出的数据           读数据是组合逻辑
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
