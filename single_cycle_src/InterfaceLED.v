`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/18 10:16:52
// Design Name: 
// Module Name: InterfaceLED
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


module InterfaceLED(
    input rst,
    input clk,
    input we,
    input [31:0] addr,
    input [31:0] data,
    output reg [23:0] led
    
    );
    
    always @(posedge clk or posedge rst) begin
        if(rst)
            led <= 24'h00000;
        else 
            led <= data[23:0];
    end
    
    
endmodule
