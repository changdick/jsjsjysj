`timescale 1ns / 1ps

`include "defines.vh"

module myCPU (
    input  wire         cpu_rst,
    input  wire         cpu_clk,
    
    // Interface to IROM
`ifdef RUN_TRACE
    output wire [15:0]  inst_addr,
`else
    output wire [13:0]  inst_addr,
`endif
    input  wire [31:0]  inst,
    
    // Interface to Bridge
    output wire [31:0]  Bus_addr,
    input  wire [31:0]  Bus_rdata,
    output wire         Bus_we,
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

    // TODO: PIPELINE CPU
    // 信号声明

    wire  [4:0]        ID_rd, EX_rd, MEM_rd, WB_rd;                          // 目标寄存器
    wire  [31:0]       EX_d2RF, MEM_d2RF, WB_d2RF;                           // 写入寄存器的数据
    wire  [31:0]       EX_ALUres, MEM_ALUres, WB_ALUres;
    wire               EX_ALUbool;
    wire  [31:0]       EX_pc4,    MEM_pc4, WB_pc4;
    wire  [31:0]       ID_imm, EX_imm, MEM_imm,WB_imm;
    wire  [31:0]       ID_regdata2, EX_regdata2, MEM_regdata2;           
    wire  [31:0]       ID_regdata1, EX_regdata1;  
    wire  [1:0]        ID_WBSel,  EX_WBSel,  MEM_WBSel, WB_WBSel;
    wire  [31:0]       IF_pc, ID_pc, EX_pc;                     // pc  IF_pc 从PC模块接出来，接inst_addr信号

    wire [31:0] EX_npc;
    
    wire is_jump;
    wire pipeline_flush;                    // 这两个型号在EX阶段产生， 是控制冒险的信号，当有控制冒险时，这两个型号会控制pc跳转以及寄存器清空
    wire pipeline_stop;
    
    wire  [31:0]       IF_inst, ID_inst;
    
    assign IF_inst = inst;                  // inst 信号从 IROM 输进cpu， 然后IF_inst送进IF/ID寄存器
    
     
    // 控制信号   
    wire [2:0]         ID_npc_op, EX_npc_op;                           // npc_op 3位
    wire               ID_RegWEn, EX_RegWEn, MEM_RegWEn, WB_RegWEn;          // 寄存器的写使能信号                           // 寄存器写使能 1位
    wire [2:0]         ID_ImmSel;                           // 立即数类型选择 3位
    wire  [3:0]        ID_ALU_Sel, EX_ALU_Sel;               // alu运算类型 4位
    wire               ID_MemWEn, EX_MemWEn, MEM_MemWEn;                    // DMEM写使能                        // 存储器写使能 1位
    wire               ID_aluD2Sel, EX_aluD2Sel;            // alu数据源 1位
    wire [1:0] WBSel;                                       // 写回数据源选择 2位            一共7个控制信号，15位
    // interface to Harzard
    wire [4:0] ID_rs1,ID_rs2;
    assign ID_rs1 = ID_inst[19:15];
    assign ID_rs2 = ID_inst[24:20];      
    
    

    
    /////////////////////
    //     IF阶段
   ///////////////////////
    // PC 

    ProgramCounter PC (
        .clk   (cpu_clk),
        .rst   (cpu_rst),
        .jmp   (is_jump),           //  是否会跳转，如果跳转会使用imm_pc 的信号作为新的pc，这个jmp信号来自EX阶段 npc模块
        .stall (pipeline_stop),
        .imm_pc(EX_npc),
        
        
        .pc    (IF_pc)
    );
    
    // pc 送出地址
        // inst_addr  信号 作为输出cpu到IROM的选址信号， 定义的是14位或者16位
        // Interface between CPU and IROM
    `ifdef RUN_TRACE
    //wire [15:0]  inst_addr,
       assign inst_addr = IF_pc[17:2] ;
    `else
       assign inst_addr = IF_pc[15:2];
    `endif
    
    // IF/ID 寄存器
    reg [63:0]  IF_ID_REG;        //if/id寄存器，定义64位宽，存储pc和inst，其中【31：0】存储IF_pc, 【63：32】存储IF_inst
    //IF/ID 寄存器在控制冒险的时候要清空
    always @(posedge cpu_clk or posedge cpu_rst) begin
        if(cpu_rst)        IF_ID_REG <= 0;
        else if(pipeline_flush)    IF_ID_REG <= 0;
        else if(pipeline_stop)     IF_ID_REG <= IF_ID_REG;
        else                       IF_ID_REG <= {IF_inst, IF_pc};
    end
    assign ID_inst = IF_ID_REG[63:32];
    assign ID_pc = IF_ID_REG[31:0];
    
    
    // 寄存器堆
    RegisterFile RF (
        .rs1           (ID_inst[19:15]),
        .rs2           (ID_inst[24:20]),        // rs1 rs2 来自ID阶段的 inst
        .rd            (WB_rd),            // rd 来自WB阶段
        .wen           (WB_RegWEn),                       //来自WB阶段的控制信号
        .wdata         (WB_d2RF),             //来自WB阶段的写回信号 一共四个来源
        .rst           (cpu_rst),
        .clk           (cpu_clk),   
        
        .data1         (ID_regdata1),                                
        .data2         (ID_regdata2)                             
    
    
    );
    
     // 立即数生成器
    ImmGen ImmGenerator (
        .din          (ID_inst[31:7]),
        .immsel       (ID_ImmSel),            // 控制模块给出的立即数类型选择
        
        .imm          (ID_imm)             //连立即数信号
    
    );
        // 控制逻辑
    ControlLogic Control (
        .inst          (ID_inst),
                        
        .npc_op        (ID_npc_op),   
        .RegWEn        (ID_RegWEn),
        .ImmSel        (ID_ImmSel),
        .ALU_Sel       (ID_ALU_Sel),
        .MemWEn        (ID_MemWEn),
        .aluD2Sel      (ID_aluD2Sel),
        .WBSel         (ID_WBSel)
        
    );
    
    reg [154:0] ID_EX_REG;        // ID/EX寄存器  【31：0】存pc  【63：32】存ID_regdata1 [95:64]存ID_regdata2 【127：96】存ID_imm    【132：128】存储rs1 【137：133】 存储rs2
                                  //  [140:138] 存储npc_op   【141】存储RegWEn， 【145：142】存储ALU_Sel. 【146】 存储MemWEn， 【147】 存储 aluD2Sel, [149:148] WBSel  [154:150] rd
    
    // ID/EX在控制冒险的时候需要清空, 在数据冒险也就是暂停的时候，也清空

    
    always @(posedge cpu_clk or posedge cpu_rst) begin
        if(cpu_rst)          ID_EX_REG <= 0;
        else if(pipeline_flush || pipeline_stop)   ID_EX_REG <= 0;
//        else if(pipeline_stop)    ID_EX_REG <=  ID_EX_REG;
        
        else                      ID_EX_REG <= {ID_inst[11:7], ID_WBSel, ID_aluD2Sel, ID_MemWEn, ID_ALU_Sel, ID_RegWEn, ID_npc_op, ID_inst[24:15], ID_imm, ID_regdata2, ID_regdata1, ID_pc };
    end 
    
    assign EX_pc               = ID_EX_REG[31:0];
    assign EX_regdata1         = ID_EX_REG[63:32];
    assign EX_regdata2         = ID_EX_REG[95:64];
    assign EX_imm              = ID_EX_REG[127:96];
//    assign EX_rs1              = ID_EX_REG[132:128];
//    assign EX_rs2              = ID_EX_REG[137:133];？？？
    assign EX_npc_op           = ID_EX_REG[140:138];
    assign EX_RegWEn           = ID_EX_REG[141];
    assign EX_ALU_Sel          = ID_EX_REG[145:142];
    assign EX_MemWEn           = ID_EX_REG[146];
    assign EX_aluD2Sel         = ID_EX_REG[147];
    assign EX_WBSel            = ID_EX_REG[149:148];
    assign EX_rd               = ID_EX_REG[154:150];
    
    ////////
//    EX 部分  
    /////// 
    

    
    wire [31:0] aludata1;
    wire [31:0] aludata2;
    
      // ALU输入的值的选择
    assign aludata1 = EX_regdata1;
    assign aludata2 = (EX_aluD2Sel == `AluD2Sel_REG)? EX_regdata2: EX_imm;
    // ALU模块
    Module_ALU alu (
        .dataA              (aludata1),         // 连RF放出来的data1
        .dataB              (aludata2),         // RF.data2或者ImmGen.imm,根据控制信号选择
        .ALU_Sel            (EX_ALU_Sel),         // 控制信号输入的选择
        .result             (EX_ALUres),         // 连DRAM用于选择地址，也就是要输出(连Bus_addr)，，连RF的写入数据端，还要连到NPC.regpc用与jalr指令的新pc
        .bool               (EX_ALUbool)          // 连NPC.br用于B型指令是否跳转
    );
     // NPC模块
    Module_NPC NPC (
        .pc           (EX_pc),
        .offset       (EX_imm),          //连立即数
        .br           (EX_ALUbool),             
        .regpc        (EX_ALUres),
        .op           (EX_npc_op),
        
        .npc          (EX_npc),
        .pc4          (EX_pc4)            //后面需要npc和pc4输出去做一个跳转与否的判断
    );
    
    /////////////////////////////////////
    //   控制冒险的检测
    //////////////////////////////////////
    assign is_jump = (EX_npc!=EX_pc4);           // 如果EX阶段算出来npc和pc4是不一样的，那说明这个指令要跳转  
    assign pipeline_flush = is_jump;            // 当EX阶段发现npc和pc4不一致时，就说明发生了控制冒险，可能是条件分支也可能是无条件的跳转， isjump和flush是同一个信号，flush给前两个寄存器，is_jump给pc
    
    
    ///////////////////////////////////////////
    // 数据冒险的检测
    ////////////////////////////////////////////
    wire rs1_ID_EX_hazard = (EX_rd == ID_rs1) & EX_RegWEn & EX_rd != 0;
    wire rs2_ID_EX_hazard = (EX_rd == ID_rs2) & EX_RegWEn & EX_rd != 0;
    wire rs1_ID_MEM_hazard = (MEM_rd == ID_rs1) & MEM_RegWEn & MEM_rd != 0;
    wire rs2_ID_MEM_hazard = (MEM_rd == ID_rs2) & MEM_RegWEn & MEM_rd != 0;
    wire rs1_ID_WB_hazard = (WB_rd == ID_rs1) & WB_RegWEn & WB_rd != 0;
    wire rs2_ID_WB_hazard = (WB_rd == ID_rs2) & WB_RegWEn & WB_rd !=0;
    assign  pipeline_stop = rs1_ID_EX_hazard | rs2_ID_EX_hazard | rs1_ID_MEM_hazard | rs2_ID_MEM_hazard |rs1_ID_WB_hazard |rs2_ID_WB_hazard;
    
    

  
    
    
    // EX/MEM 寄存器，在数据冒险暂停或者控制冒险清空都不需要，一直往下流动
    reg [136:0] EX_MEM_REG;                                   // EX/MEM寄存器 [31:0] 存 regdata2， 【63：32】存alu计算结果， 【95：64】存imm， 【127：96】存pc加4，【128】存 RegWen， 
                                                                //    【130：129】存储WBSel  【131】存储MemWEn       [136:132] rd
                                                                
    always@(posedge cpu_clk or posedge cpu_rst) begin
        if(cpu_rst)                EX_MEM_REG <= 0;
        else                      EX_MEM_REG <= {EX_rd, EX_MemWEn, EX_WBSel, EX_RegWEn, EX_pc4, EX_imm, EX_ALUres, EX_regdata2 };
    end
    
    assign MEM_regdata2      = EX_MEM_REG[31:0];
    assign MEM_ALUres        = EX_MEM_REG[63:32];
    assign MEM_imm           = EX_MEM_REG[95:64];
    assign MEM_pc4           = EX_MEM_REG[127:96];
    assign MEM_RegWEn        = EX_MEM_REG[128];
    assign MEM_WBSel         = EX_MEM_REG[130:129];
    assign MEM_MemWEn        =  EX_MEM_REG[131];
    assign MEM_rd            = EX_MEM_REG[136:132];
    
    // MEM阶段访存接线
        // DRAM 接线  定义在上面// Interface to Bridge处
    assign  Bus_we = MEM_MemWEn;
    assign  Bus_wdata = MEM_regdata2;
    assign  Bus_addr = MEM_ALUres;
    // Bus_rdata 就是数据
    
    
    // MEM_WB寄存器 一直往下流动
    reg [135:0] MEM_WB_REG;                                //[31:0] 存 存储器数据 ， 【63：32】存alu计算结果， 【95：64】存imm， 【127：96】存pc加4，【128】存 RegWen， 
                                                                //    【130：129】存储WBSel    [135:131] rd
    always @(posedge cpu_clk or posedge cpu_rst) begin
        if(cpu_rst)            MEM_WB_REG <= 0;
        else                   MEM_WB_REG <={MEM_rd, MEM_WBSel, MEM_RegWEn, MEM_pc4, MEM_imm, MEM_ALUres, Bus_rdata };
    end
    
    wire [31:0] WB_Memrdata;
    reg [31:0] WB_data_W2RF;
    assign WB_ALUres = MEM_WB_REG[63:32];
    assign WB_imm = MEM_WB_REG[95:64];
    assign WB_Memrdata = MEM_WB_REG[31:0];
    assign WB_pc4 = MEM_WB_REG[127:96];
    assign WB_RegWEn = MEM_WB_REG[128];
    assign WB_WBSel = MEM_WB_REG[130:129];
    assign WB_rd = MEM_WB_REG[135:131];
    
        // RF的写入数据端 data_W2RF 的值
    always @(*) begin
        case(WB_WBSel)
            `WB_ALU:  WB_data_W2RF = WB_ALUres;
            `WB_MEM:  WB_data_W2RF = WB_Memrdata;  //DRAM输入进来的数据
            `WB_PC_4: WB_data_W2RF = WB_pc4;         // pc+4的值
            `WB_IMM:  WB_data_W2RF = WB_imm;       
        endcase
    end
    assign WB_d2RF =  WB_data_W2RF;
    
                               
    
//    // IF 用于生成pc（IF_pc），
//    IF_Module IF (
//        .clk (),
//        .rst (),
//        .EX_npc (),
//        .is_jmp (),
//        .stop  (),
//        .pc (IF_pc) 
           
    
//    );
    
//    assign inst_addr = IF_pc[15:2];     // pc输出14位地址给IROM 
    
//    // IF/ID 寄存器
//    REG_IF_ID Reg_IF_ID (
//        .clk     (),
//        .rst     (),
//        .pipeline_flush  (),
//        .pipeline_stop   (),
//        .IF_pc           (),
//        .IF_inst         (),
//        .ID_pc           (),
//        .id_inst         ()
    
//    );
        
        
//        //ID
        
    
//    ID_Module ID (
//        .clk  (),
//        .rst  (),
//        .inst (),
//        .WB_wdata  (),
//        .WB_rd (),
//        .WB_RegWEn(),
            //
    

`ifdef RUN_TRACE
    reg debug_id_have_inst;
    reg debug_ex_have_inst;
    reg debug_mem_have_inst;
    reg wb_have_inst;
    reg [31:0] wb_value;
    
    
    always @(posedge cpu_clk or posedge cpu_rst) begin
        if(cpu_rst) begin
            debug_id_have_inst<=0;
            debug_ex_have_inst<=0;
            debug_mem_have_inst<=0;
            wb_have_inst <= 0;
            wb_value <= 0;
            
        end
        else if (pipeline_flush) begin
            debug_id_have_inst<= 0;
            debug_ex_have_inst<=0;
            debug_mem_have_inst<=debug_ex_have_inst;
            wb_have_inst <=debug_mem_have_inst;
        end
         else if (pipeline_stop) begin
            debug_id_have_inst<= debug_id_have_inst;
            debug_ex_have_inst<=0;
            debug_mem_have_inst<=debug_ex_have_inst;
            wb_have_inst <=debug_mem_have_inst;
        end
        else begin
            debug_id_have_inst<= IF_inst != 0;
            debug_ex_have_inst<=debug_id_have_inst;
            debug_mem_have_inst<=debug_ex_have_inst;
            wb_have_inst <=debug_mem_have_inst;
//            wb_value <= WB_data_W2RF;
        end
    end
    // Debug Interface
    assign debug_wb_have_inst =   wb_have_inst ;
    assign debug_wb_pc        = MEM_WB_REG [127:96] - 4;
    assign debug_wb_ena       = MEM_WB_REG[128];
    assign debug_wb_reg       = MEM_WB_REG[135:131];
    assign debug_wb_value     = WB_data_W2RF;
`endif

endmodule
