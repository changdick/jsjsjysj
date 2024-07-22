`timescale 1ns / 1ps

`include "defines.vh"

module myCPU (
    input  wire         cpu_rst,
    input  wire         cpu_clk,

    // Interface to IROM  if RUN_TRACE     if REAL 14bit   因为IROM模块设置的寻址单位是32位，所以这边地址在模拟的时候是按B寻址，但是实际送ROM的时候可以直接按4B寻址
`ifdef RUN_TRACE
    output wire [15:0]  inst_addr,
`else
    output wire [13:0]  inst_addr,
`endif
    input  wire [31:0]  inst,
    
    // Interface to Bridge
    output wire [31:0]  Bus_addr,            // 传出的选址信号
    input  wire [31:0]  Bus_rdata,           // 写入的数据
    output wire         Bus_we,               // 连控制信号的 MemWEn
    output wire [31:0]  Bus_wdata

`ifdef RUN_TRACE
    ,// Debug Interface
    output wire         debug_wb_have_inst,
    output wire [31:0]  debug_wb_pc,
    output              debug_wb_ena,
    output wire [ 4:0]  debug_wb_reg,
    output wire [31:0]  debug_wb_value
`endif
);

    // TODO: 瀹屾垚浣犺嚜宸辩殑鍗曞懆鏈烠PU璁捐 完成你自己的单周期CPU设计
    wire [31:0] pc;
    wire [31:0] npc;                // npc模块  ->  PC模块
    wire [31:0] pc4;           //PC + 4   连NPC.pc4端口，到RF
    wire [31:0] imm;
   
    // ALU的输入输出信号
    wire aluD2Sel; // 这个是控制信号
    wire [31:0] aludata1;
    wire [31:0] aludata2;
    wire [31:0] alu_result;
    wire        alu_bool;
    
    // 控制信号   
    

    wire [2:0] npc_op;
    wire       RegWEn;
    wire [2:0] ImmSel;
    wire [3:0] ALU_Sel;
    wire       MemWEn;
    // aluD2Sel 上面定义了
    wire [1:0] WBSel;
    
    // PC模块
    ProgramCounter PC(
        .din   (npc),
        .rst   (cpu_rst),
        .clk   (cpu_clk),
        
        .pc    (pc)
    );
    // NPC模块
    Module_NPC NPC (
        .pc           (pc),
        .offset       (imm),          //连立即数
        .br           (alu_bool),             
        .regpc        (alu_result),
        .op           (npc_op),
        
        .npc          (npc),
        .pc4          (pc4)
    );
    
    // inst_addr  信号 作为输出cpu到IROM的选址信号， 定义的是14位或者16位
        // Interface between CPU and IROM
`ifdef RUN_TRACE
//wire [15:0]  inst_addr,
   assign inst_addr = pc[17:2] ;
`else
   assign inst_addr = pc[15:2];
`endif
    
    // 立即数生成器
    ImmGenerator ImmGen (
        .din          (inst[31:7]),
        .immsel       (ImmSel),            // 控制模块给出的立即数类型选择
        
        .imm          (imm)             //连立即数信号
    
    );
    
    wire [31:0] regdata1;
    wire [31:0] regdata2; 
    reg  [31:0] data_W2RF;
    
    // RF的写入数据端 data_W2RF 的值
    always @(*) begin
        case(WBSel)
            `WB_ALU:  data_W2RF = alu_result;
            `WB_MEM:  data_W2RF = Bus_rdata;  //DRAM输入进来的数据
            `WB_PC_4: data_W2RF = pc4;         // pc+4的值
            `WB_IMM:  data_W2RF = imm;       
        endcase
    end
    
    // 寄存器堆
    RegisterFile RF (
        .rs1           (inst[19:15]),
        .rs2           (inst[24:20]),       
        .rd            (inst[11:7]),
        .wen           (RegWEn),                       //连控制器给出的写使能信号
        .wdata         (data_W2RF),             //WB阶段的写回信号 一共四个来源
        .rst           (cpu_rst),
        .clk           (cpu_clk),   
        
        .data1         (regdata1),                                //送alu输入口1
        .data2         (regdata2)                                // 送alu输入口2，要和立即数选    还要送到DRAM通过总线桥(Bus_wdata = 这里接出来)
    
    
    );
   
    // ALU输入的值的选择
    assign aludata1 = regdata1;
    assign aludata2 = (aluD2Sel == `AluD2Sel_REG)? regdata2: imm;
    // ALU模块
    Module_ALU alu (
        .dataA              (aludata1),         // 连RF放出来的data1
        .dataB              (aludata2),         // RF.data2或者ImmGen.imm,根据控制信号选择
        .ALU_Sel            (ALU_Sel),         // 控制信号输入的选择
        .result             (alu_result),         // 连DRAM用于选择地址，也就是要输出(连Bus_addr)，，连RF的写入数据端，还要连到NPC.regpc用与jalr指令的新pc
        .bool               (alu_bool)          // 连NPC.br用于B型指令是否跳转
    );
    
    // DRAM 接线  定义在上面// Interface to Bridge处
    assign  Bus_we = MemWEn;
    assign  Bus_wdata = regdata2;
    assign  Bus_addr = alu_result;
    
    
    
    // 控制逻辑
    ControlLogic Control (
        .inst          (inst),
                        
        .npc_op        (npc_op),
        .RegWEn        (RegWEn),
        .ImmSel        (ImmSel),
        .ALU_Sel       (ALU_Sel),
        .MemWEn        (MemWEn),
        .aluD2Sel      (aluD2Sel),
        .WBSel         (WBSel)
        
    );
    
    //


// TRace测试的时候，取指令正确了，但是所有指令都快了1个周期，所以调试信号全部存一个寄存器，延缓一个周期

reg [31:0] PC0;
reg        RegWEn0;
reg [4:0]  rd0;
reg [31:0] data0;
always@(posedge cpu_clk ) begin
    PC0 <= pc;
    RegWEn0 <= RegWEn;
    rd0 <= inst[11:7];
    data0 <= data_W2RF;
end
    
`ifdef RUN_TRACE
    // Debug Interface
    assign debug_wb_have_inst = 1'b1;           // single cycle cpu: constant 1
    assign debug_wb_pc        = PC0;              // 此阶段的pc
    assign debug_wb_ena       = RegWEn0;
    assign debug_wb_reg       = rd0;
    assign debug_wb_value     = data0;
`endif

endmodule
