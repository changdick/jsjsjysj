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
    input [31:0] data,                // cpu���������ݣ�����������κ����ݣ���һ����д��7������ܵġ�
    input we,
    input [31:0] addr,
    
    output reg [7:0] site_en,         // ѡλʹ��
    output [7:0] num_sel             // ѡ��ʹ��
    );
    // data ���Էֳ�8�����֣�ÿ�����ֶ���0��9������
    //
    reg [31:0] data_current;           //����������ͳ�����32λ��ʾ����ʾ���ݣ��������Ч������д�룬�ӿڵ�·Ҫ�Ĵ�������
    
    always @(posedge clk or posedge rst) begin
        if(rst)
            data_current <= 0;
        else if(we) 
            data_current <= data;             // ֻ�и����ӿڵ�дʹ����Ч���Ż��������ģ��Ĵ�cpuд�뵽����ܵ�����
        else
            data_current <= data_current;
    end
    
    
    
    //������
    reg[31:0] counter;
    
    always @(posedge clk or posedge rst) begin
        if(rst)
            counter <= 0;
        else if (counter == 32'd12000)
            counter <= 0;
        else 
            counter <= counter + 1;
    end
    
    // �����ѡλ�ź�
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
