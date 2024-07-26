`timescale 1ns / 1ps
`include "defines.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/23 13:59:48
// Design Name: 
// Module Name: ImmGen  立即数生成单元  单周期实现好了一样的
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


module ImmGen(
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
