`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/18 10:00:12
// Design Name: 
// Module Name: InterfaceSwitches
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


module InterfaceSwitches(
    input [23:0] sw,
    input clk,
    input rst,
    input [31:0] addr,
     
    output [31:0] data
    
    );
    
    assign data ={8'h00 , sw};
    
    
endmodule
