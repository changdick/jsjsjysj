`timescale 1ns / 1ps

`include "defines.vh"

module Bridge (
    // Interface to CPU
    input  wire         rst_from_cpu,
    input  wire         clk_from_cpu,
    input  wire [31:0]  addr_from_cpu,      // 地址线，cpu把地址给到总线，这个地址既是dram选址，也是选择外设的
    input  wire         we_from_cpu,
    input  wire [31:0]  wdata_from_cpu,      // 数据线， cpu把数据传到总线，总线再传向指定地址可能是存储器可能是外设
    output reg  [31:0]  rdata_to_cpu,
    
    // Interface to DRAM
    // output wire         rst_to_dram,
    output wire         clk_to_dram,
    output wire [31:0]  addr_to_dram,
    input  wire [31:0]  rdata_from_dram,
    output wire         we_to_dram,
    output wire [31:0]  wdata_to_dram,
    
    // Interface to 7-seg digital LEDs
    output wire         rst_to_dig,
    output wire         clk_to_dig,
    output wire [31:0]  addr_to_dig,
    output wire         we_to_dig,
    output wire [31:0]  wdata_to_dig,

    // Interface to LEDs
    output wire         rst_to_led,
    output wire         clk_to_led,
    output wire [31:0]  addr_to_led,
    output wire         we_to_led,
    output wire [31:0]  wdata_to_led,

    // Interface to switches
    output wire         rst_to_sw,
    output wire         clk_to_sw,
    output wire [31:0]  addr_to_sw,
    input  wire [31:0]  rdata_from_sw,

    // Interface to buttons
    output wire         rst_to_btn,
    output wire         clk_to_btn,
    output wire [31:0]  addr_to_btn,
    input  wire [31:0]  rdata_from_btn
);

    // cpu写出去的数据，不管地址对不对都会发送到，只要地址对了，access就会是1，就会有对应的写使能。所以可以用写使能来判断是否该写入

        // 1 通过cpu发来的地址，按规则生成5位的access码，就知道该次访问哪个设备。 

    wire access_mem = (addr_from_cpu[31:12] != 20'hFFFFF) ? 1'b1 : 1'b0;
    wire access_dig = (addr_from_cpu == `PERI_ADDR_DIG) ? 1'b1 : 1'b0;
    wire access_led = (addr_from_cpu == `PERI_ADDR_LED) ? 1'b1 : 1'b0;
    wire access_sw  = (addr_from_cpu == `PERI_ADDR_SW ) ? 1'b1 : 1'b0;
    wire access_btn = (addr_from_cpu == `PERI_ADDR_BTN) ? 1'b1 : 1'b0;
    
    wire [4:0] access_bit = { access_mem,
                              access_dig,
                              access_led,
                              access_sw,
                              access_btn };

//2 固定的接线， cpu的时钟、数据和复位要接到多个设备。 

    // DRAM
    // assign rst_to_dram  = rst_from_cpu;
    assign clk_to_dram   = clk_from_cpu;
    assign addr_to_dram  = addr_from_cpu;
    assign we_to_dram    = we_from_cpu & access_mem;
    assign wdata_to_dram = wdata_from_cpu;

    // 7-seg LEDs
    assign rst_to_dig    = rst_from_cpu;
    assign clk_to_dig    = clk_from_cpu;
    assign addr_to_dig   = addr_from_cpu;
    assign we_to_dig     = we_from_cpu & access_dig;
    assign wdata_to_dig  = wdata_from_cpu;

    // LEDs
    assign rst_to_led    = rst_from_cpu;
    assign clk_to_led    = clk_from_cpu;
    assign addr_to_led   = addr_from_cpu;
    assign we_to_led     = we_from_cpu & access_led;
    assign wdata_to_led  = wdata_from_cpu;
    
    // Switches
    assign rst_to_sw     = rst_from_cpu;
    assign clk_to_sw     = clk_from_cpu;
    assign addr_to_sw    = addr_from_cpu;

    // Buttons
    assign rst_to_btn    = rst_from_cpu;
    assign clk_to_btn    = clk_from_cpu;
    assign addr_to_btn   = addr_from_cpu;


//3 输入信号的连接 一共三个设备能够写入cpu 存储器 开关 和按钮， 输入哪一个取决于access码是多少
    // Select read data towards CPU
    always @(*) begin
        casex (access_bit)
            5'b1????: rdata_to_cpu = rdata_from_dram;
            5'b00010: rdata_to_cpu = rdata_from_sw;
            5'b00001: rdata_to_cpu = rdata_from_btn;
            default:  rdata_to_cpu = 32'hFFFF_FFFF;
        endcase
    end

endmodule
