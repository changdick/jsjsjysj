`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/18 09:14:08
// Design Name: 
// Module Name: InterfaceTube
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


module InterfaceTube(
    input clk,
    input rst,
    input [31:0] data,                // cpu送来的数据，这个可能是任何数据，不一定是写给7段数码管的。
    input we,
    input [31:0] addr,
    
    output reg [7:0] site_en,         // 选位使能
    output [7:0] num_sel             // 选段使能
    );
    // data 可以分成8个数字，每个数字都是0到9的数字
    //
    reg [31:0] data_current;           //汇编程序最后送出来的32位表示的显示内容，如果是有效的数据写入，接口电路要寄存下来，
    
    always @(posedge clk or posedge rst) begin
        if(rst)
            data_current <= 0;
        else if(we) 
            data_current <= data;             // 只有给到接口的写使能有效，才会做出更改，寄存cpu写入到数码管的数据
        else
            data_current <= data_current;
    end
    
    
    
    //计数器
    reg[31:0] counter;
    
    always @(posedge clk or posedge rst) begin
        if(rst)
            counter <= 0;
        else if (counter == 32'd12000)
            counter <= 0;
        else 
            counter <= counter + 1;
    end
    
    // 数码管选位信号
    always @(posedge clk or posedge rst) begin
        if(rst)
            site_en <= 8'b11111111;
        else if(site_en == 8'b11111111)
            site_en <= 8'b0111_1111;
        else if(counter == 32'd6000)
            site_en <= {site_en[0], site_en[7:1]};
        else 
            site_en <= site_en;
    end
    
    
    reg [3:0] num_to_show;
    always @(*) begin
        case(site_en)
            8'b01111111:   num_to_show = data_current[31:28];
            8'b10111111:   num_to_show = data_current[27:24];
            8'b11011111:   num_to_show = data_current[23:20];
            8'b11101111:   num_to_show = data_current[19:16];
            8'b11110111:   num_to_show = data_current[15:12];
            8'b11111011:   num_to_show = data_current[11:8];
            8'b11111101:   num_to_show = data_current[7:4];
            8'b11111110:   num_to_show = data_current[3:0];
            default:       num_to_show = 0;
        endcase
    end 
    
    
    
    reg [7:0] ledcode;
    
    always @(*) begin
        case(num_to_show) 
            4'h0:      ledcode = 8'b00000011;
            4'h1:      ledcode = 8'b10011111;
            4'h2:      ledcode = 8'b00100101; 
            4'h3:      ledcode = 8'b00001101; 
            4'h4:      ledcode = 8'b10011001; 
            4'h5:      ledcode = 8'b01001001; 
            4'h6:      ledcode = 8'b01000001; 
            4'h7:      ledcode = 8'b00011111; 
            4'h8:      ledcode = 8'b00000001; 
            4'h9:      ledcode = 8'b00001001; 
            4'ha:      ledcode = 8'b00010001;
            4'hb:      ledcode = 8'b11000001;
            4'hc:      ledcode = 8'b01100011;
            4'hd:      ledcode = 8'b10000101;
            4'he:      ledcode = 8'b01100001;
            4'hf:      ledcode = 8'b01110001; 
            default:  ledcode = 8'b11111111;
        endcase
    end
    
    assign num_sel = ledcode;
    
    
    
    
endmodule
