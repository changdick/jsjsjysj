`timescale 1ns / 1ps

`include "defines.vh"

module miniRV_SoC (
    input  wire         fpga_rst,   // High active
    input  wire         fpga_clk,   // 板上的100MHz时钟信号

    input  wire [23:0]  sw,
    input  wire [ 4:0]  button,
    output wire [ 7:0]  dig_en,
    output wire         DN_A,
    output wire         DN_B,
    output wire         DN_C,
    output wire         DN_D,
    output wire         DN_E,
    output wire         DN_F,
    output wire         DN_G,
    output wire         DN_DP,
    output wire [23:0]  led

`ifdef RUN_TRACE
    ,// Debug Interface
    output wire         debug_wb_have_inst, // 褰撳墠鏃堕挓鍛ㄦ湡鏄惁鏈夋寚浠ゅ啓鍥? (瀵瑰崟鍛ㄦ湡CPU锛屽彲鍦ㄥ浣嶅悗鎭掔疆1) 当前时钟周期是否有指令写?? (对单周期CPU，可在复位后恒置1)
    output wire [31:0]  debug_wb_pc,        // 褰撳墠鍐欏洖鐨勬寚浠ょ殑PC (鑻b_have_inst=0锛屾椤瑰彲涓轰换鎰忓??)
    output              debug_wb_ena,       // 鎸囦护鍐欏洖鏃讹紝瀵勫瓨鍣ㄥ爢鐨勫啓浣胯兘 (鑻b_have_inst=0锛屾椤瑰彲涓轰换鎰忓??)
    output wire [ 4:0]  debug_wb_reg,       // 鎸囦护鍐欏洖鏃讹紝鍐欏叆鐨勫瘎瀛樺櫒鍙? (鑻b_ena鎴杦b_have_inst=0锛屾椤瑰彲涓轰换鎰忓??)
    output wire [31:0]  debug_wb_value      // 鎸囦护鍐欏洖鏃讹紝鍐欏叆瀵勫瓨鍣ㄧ殑鍊? (鑻b_ena鎴杦b_have_inst=0锛屾椤瑰彲涓轰换鎰忓??)
`endif
);

    wire        pll_lock;
    wire        pll_clk;
    wire        cpu_clk;

    // Interface between CPU and IROM
`ifdef RUN_TRACE
    wire [15:0] inst_addr;
`else
    wire [13:0] inst_addr;
`endif
    wire [31:0] inst;

    // Interface between CPU and Bridge
    wire [31:0] Bus_rdata;
    wire [31:0] Bus_addr;
    wire        Bus_we;
    wire [31:0] Bus_wdata;
    
    // Interface between bridge and DRAM
    // wire         rst_bridge2dram;
    wire         clk_bridge2dram;
    wire [31:0]  addr_bridge2dram;
    wire [31:0]  rdata_dram2bridge;
    wire         we_bridge2dram;
    wire [31:0]  wdata_bridge2dram;
    
    // Interface between bridge and peripherals
    // TODO: 鍦ㄦ瀹氫箟鎬荤嚎妗ヤ笌澶栬I/O鎺ュ彛鐢佃矾妯″潡鐨勮繛鎺ヤ俊鍙?、
    
    
    // Interface between bridge and 7-seg LEDs
    wire        clk_bridge2digLEDs;
    wire        rst_bridge2digLEDs;
    wire [31:0] addr_bridge2digLEDs;
    wire        we_bridge2digLEDs;
    wire [31:0] wdata_bridge2digLEDs;
    
    // Interface between bridge and LED
    wire        clk_bridge2LED;
    wire        rst_bridge2LED;
    wire        we_bridge2LED;
    wire [31:0] wdata_bridge2LED;
    
    
    // Interface between bridge and switches
    wire [31:0] rdata_switches2bridge;
    
    // Interface between bridge and button
    wire [31:0] rdata_button2bridge;
    
`ifdef RUN_TRACE
    // Trace璋冭瘯鏃讹紝鐩存帴浣跨敤澶栭儴杈撳叆鏃堕挓 Trace调试时，直接使用外部输入时钟
    assign cpu_clk = fpga_clk;
`else
    // 涓嬫澘鏃讹紝浣跨敤PLL鍒嗛鍚庣殑鏃堕挓    下板时，使用PLL分频后的时钟   用ip核输出的时钟和locked信号与运算，得到cpu的时钟信号，送入cpu
    assign cpu_clk = pll_clk & pll_lock;
    cpuclk Clkgen (
        // .resetn     (!fpga_rst),
        .clk_in1    (fpga_clk),
        .clk_out1   (pll_clk),
        .locked     (pll_lock)
    );
`endif
    
    myCPU Core_cpu (
        .cpu_rst            (fpga_rst),
        .cpu_clk            (cpu_clk),

        // Interface to IROM
        .inst_addr          (inst_addr),
        .inst               (inst),

        // Interface to Bridge
        .Bus_addr           (Bus_addr),
        .Bus_rdata          (Bus_rdata),
        .Bus_we             (Bus_we),
        .Bus_wdata          (Bus_wdata)           // cpu -> Bridge

`ifdef RUN_TRACE
        ,// Debug Interface
        .debug_wb_have_inst (debug_wb_have_inst),
        .debug_wb_pc        (debug_wb_pc),
        .debug_wb_ena       (debug_wb_ena),
        .debug_wb_reg       (debug_wb_reg),
        .debug_wb_value     (debug_wb_value)
`endif
    );
    // 
    IROM Mem_IROM (
        .a          (inst_addr),
        .spo        (inst)
    );
    
    
    //总线桥
    Bridge Bridge (       
        // Interface to CPU
        .rst_from_cpu       (fpga_rst),
        .clk_from_cpu       (cpu_clk),
        .addr_from_cpu      (Bus_addr),
        .we_from_cpu        (Bus_we),
        .wdata_from_cpu     (Bus_wdata),
        .rdata_to_cpu       (Bus_rdata),
        
        // Interface to DRAM
        // .rst_to_dram    (rst_bridge2dram),
        .clk_to_dram        (clk_bridge2dram),
        .addr_to_dram       (addr_bridge2dram),
        .rdata_from_dram    (rdata_dram2bridge),
        .we_to_dram         (we_bridge2dram),
        .wdata_to_dram      (wdata_bridge2dram),
        
        // Interface to 7-seg digital LEDs
        .rst_to_dig         (rst_bridge2digLEDs),
        .clk_to_dig         (clk_bridge2digLEDs),
        .addr_to_dig        (addr_bridge2digLEDs),
        .we_to_dig          (we_bridge2digLEDs),
        .wdata_to_dig       (wdata_bridge2digLEDs),

        // Interface to LEDs
        .rst_to_led         (rst_bridge2LED),
        .clk_to_led         (clk_bridge2LED),
//        .addr_to_led        (/* TODO */),
        .we_to_led          (we_bridge2LED),
        .wdata_to_led       (wdata_bridge2LED),

        // Interface to switches
//        .rst_to_sw          (/* TODO */),
//        .clk_to_sw          (/* TODO */),
//        .addr_to_sw         (/* TODO */),
        .rdata_from_sw      (rdata_switches2bridge),

        // Interface to buttons
//        .rst_to_btn         (/* TODO */),
//        .clk_to_btn         (/* TODO */),
//        .addr_to_btn        (/* TODO */),
        .rdata_from_btn     (rdata_button2bridge)
    );

    DRAM Mem_DRAM (
        .clk        (clk_bridge2dram),
        .a          (addr_bridge2dram[15:2]),
        .spo        (rdata_dram2bridge),
        .we         (we_bridge2dram),
        .d          (wdata_bridge2dram)
    );
    
    // TODO: 鍦ㄦ瀹炰緥鍖栦綘鐨勫璁綢/O鎺ュ彛鐢佃矾妯″潡
    //
    // io接口
    InterfaceTube digLEDs (
        .clk       (clk_bridge2digLEDs),
        .rst       (rst_bridge2digLEDs),
        .data      (wdata_bridge2digLEDs),
        .we        (we_bridge2digLEDs),
        .addr      (addr_bridge2digLEDs),
        .site_en   (dig_en),
        .num_sel   ({DN_A,DN_B,DN_C,DN_D,DN_E,DN_F,DN_G,DN_DP})
    );
    
    
    InterfaceSwitches switches(
        .sw          (sw),
        .data        (rdata_switches2bridge)
    );
    
    

    InterfaceLED LEDs (
        .rst        (rst_bridge2LED),
        .clk        (clk_bridge2LED),
        .data       (wdata_bridge2LED),
        .we         (we_bridge2LED),
        .led        (led)
    
    );
    
    InterfaceButton Buttons (
        .btn     (button),
        .data    (rdata_button2bridge)
    );


endmodule