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
    // �ź�����

    wire  [4:0]        ID_rd, EX_rd, MEM_rd, WB_rd;                          // Ŀ��Ĵ���
    wire  [31:0]       EX_d2RF, MEM_d2RF, WB_d2RF;                           // д��Ĵ���������
    wire  [31:0]       EX_ALUres, MEM_ALUres, WB_ALUres;
    wire               EX_ALUbool;
    wire  [31:0]       EX_pc4,    MEM_pc4, WB_pc4;
    wire  [31:0]       ID_imm, EX_imm, MEM_imm,WB_imm;
    wire  [31:0]       ID_regdata2, EX_regdata2, MEM_regdata2;           
    wire  [31:0]       ID_regdata1, EX_regdata1;  
    wire  [1:0]        ID_WBSel,  EX_WBSel,  MEM_WBSel, WB_WBSel;
    wire  [31:0]       IF_pc, ID_pc, EX_pc;                     // pc  IF_pc ��PCģ��ӳ�������inst_addr�ź�

    wire [31:0] EX_npc;
    
    wire is_jump;
    wire pipeline_flush;                    // �������ͺ���EX�׶β����� �ǿ���ð�յ��źţ����п���ð��ʱ���������ͺŻ����pc��ת�Լ��Ĵ������
    wire pipeline_stop;
    
    wire  [31:0]       IF_inst, ID_inst;
    
    assign IF_inst = inst;                  // inst �źŴ� IROM ���cpu�� Ȼ��IF_inst�ͽ�IF/ID�Ĵ���
    
     
    // �����ź�   
    wire [2:0]         ID_npc_op, EX_npc_op;                           // npc_op 3λ
    wire               ID_RegWEn, EX_RegWEn, MEM_RegWEn, WB_RegWEn;          // �Ĵ�����дʹ���ź�                           // �Ĵ���дʹ�� 1λ
    wire [2:0]         ID_ImmSel;                           // ����������ѡ�� 3λ
    wire  [3:0]        ID_ALU_Sel, EX_ALU_Sel;               // alu�������� 4λ
    wire               ID_MemWEn, EX_MemWEn, MEM_MemWEn;                    // DMEMдʹ��                        // �洢��дʹ�� 1λ
    wire               ID_aluD2Sel, EX_aluD2Sel;            // alu����Դ 1λ
    wire [1:0] WBSel;                                       // д������Դѡ�� 2λ            һ��7�������źţ�15λ
    // interface to Harzard
    wire [4:0] ID_rs1,ID_rs2;
    assign ID_rs1 = ID_inst[19:15];
    assign ID_rs2 = ID_inst[24:20];      
    
    

    
    /////////////////////
    //     IF�׶�
   ///////////////////////
    // PC 

    ProgramCounter PC (
        .clk   (cpu_clk),
        .rst   (cpu_rst),
        .jmp   (is_jump),           //  �Ƿ����ת�������ת��ʹ��imm_pc ���ź���Ϊ�µ�pc�����jmp�ź�����EX�׶� npcģ��
        .stall (pipeline_stop),
        .imm_pc(EX_npc),
        
        
        .pc    (IF_pc)
    );
    
    // pc �ͳ���ַ
        // inst_addr  �ź� ��Ϊ���cpu��IROM��ѡַ�źţ� �������14λ����16λ
        // Interface between CPU and IROM
    `ifdef RUN_TRACE
    //wire [15:0]  inst_addr,
       assign inst_addr = IF_pc[17:2] ;
    `else
       assign inst_addr = IF_pc[15:2];
    `endif
    
    // IF/ID �Ĵ���
    reg [63:0]  IF_ID_REG;        //if/id�Ĵ���������64λ���洢pc��inst�����С�31��0���洢IF_pc, ��63��32���洢IF_inst
    //IF/ID �Ĵ����ڿ���ð�յ�ʱ��Ҫ���
    always @(posedge cpu_clk or posedge cpu_rst) begin
        if(cpu_rst)        IF_ID_REG <= 0;
        else if(pipeline_flush)    IF_ID_REG <= 0;
        else if(pipeline_stop)     IF_ID_REG <= IF_ID_REG;
        else                       IF_ID_REG <= {IF_inst, IF_pc};
    end
    assign ID_inst = IF_ID_REG[63:32];
    assign ID_pc = IF_ID_REG[31:0];
    
    
    // �Ĵ�����
    RegisterFile RF (
        .rs1           (ID_inst[19:15]),
        .rs2           (ID_inst[24:20]),        // rs1 rs2 ����ID�׶ε� inst
        .rd            (WB_rd),            // rd ����WB�׶�
        .wen           (WB_RegWEn),                       //����WB�׶εĿ����ź�
        .wdata         (WB_d2RF),             //����WB�׶ε�д���ź� һ���ĸ���Դ
        .rst           (cpu_rst),
        .clk           (cpu_clk),   
        
        .data1         (ID_regdata1),                                
        .data2         (ID_regdata2)                             
    
    
    );
    
     // ������������
    ImmGen ImmGenerator (
        .din          (ID_inst[31:7]),
        .immsel       (ID_ImmSel),            // ����ģ�����������������ѡ��
        
        .imm          (ID_imm)             //���������ź�
    
    );
        // �����߼�
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
    
    reg [154:0] ID_EX_REG;        // ID/EX�Ĵ���  ��31��0����pc  ��63��32����ID_regdata1 [95:64]��ID_regdata2 ��127��96����ID_imm    ��132��128���洢rs1 ��137��133�� �洢rs2
                                  //  [140:138] �洢npc_op   ��141���洢RegWEn�� ��145��142���洢ALU_Sel. ��146�� �洢MemWEn�� ��147�� �洢 aluD2Sel, [149:148] WBSel  [154:150] rd
    
    // ID/EX�ڿ���ð�յ�ʱ����Ҫ���, ������ð��Ҳ������ͣ��ʱ��Ҳ���

    
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
//    assign EX_rs2              = ID_EX_REG[137:133];������
    assign EX_npc_op           = ID_EX_REG[140:138];
    assign EX_RegWEn           = ID_EX_REG[141];
    assign EX_ALU_Sel          = ID_EX_REG[145:142];
    assign EX_MemWEn           = ID_EX_REG[146];
    assign EX_aluD2Sel         = ID_EX_REG[147];
    assign EX_WBSel            = ID_EX_REG[149:148];
    assign EX_rd               = ID_EX_REG[154:150];
    
    ////////
//    EX ����  
    /////// 
    

    
    wire [31:0] aludata1;
    wire [31:0] aludata2;
    
      // ALU�����ֵ��ѡ��
    assign aludata1 = EX_regdata1;
    assign aludata2 = (EX_aluD2Sel == `AluD2Sel_REG)? EX_regdata2: EX_imm;
    // ALUģ��
    Module_ALU alu (
        .dataA              (aludata1),         // ��RF�ų�����data1
        .dataB              (aludata2),         // RF.data2����ImmGen.imm,���ݿ����ź�ѡ��
        .ALU_Sel            (EX_ALU_Sel),         // �����ź������ѡ��
        .result             (EX_ALUres),         // ��DRAM����ѡ���ַ��Ҳ����Ҫ���(��Bus_addr)������RF��д�����ݶˣ���Ҫ����NPC.regpc����jalrָ�����pc
        .bool               (EX_ALUbool)          // ��NPC.br����B��ָ���Ƿ���ת
    );
     // NPCģ��
    Module_NPC NPC (
        .pc           (EX_pc),
        .offset       (EX_imm),          //��������
        .br           (EX_ALUbool),             
        .regpc        (EX_ALUres),
        .op           (EX_npc_op),
        
        .npc          (EX_npc),
        .pc4          (EX_pc4)            //������Ҫnpc��pc4���ȥ��һ����ת�����ж�
    );
    
    /////////////////////////////////////
    //   ����ð�յļ��
    //////////////////////////////////////
    assign is_jump = (EX_npc!=EX_pc4);           // ���EX�׶������npc��pc4�ǲ�һ���ģ���˵�����ָ��Ҫ��ת  
    assign pipeline_flush = is_jump;            // ��EX�׶η���npc��pc4��һ��ʱ����˵�������˿���ð�գ�������������֧Ҳ����������������ת�� isjump��flush��ͬһ���źţ�flush��ǰ�����Ĵ�����is_jump��pc
    
    
    ///////////////////////////////////////////
    // ����ð�յļ��
    ////////////////////////////////////////////
    wire rs1_ID_EX_hazard = (EX_rd == ID_rs1) & EX_RegWEn & EX_rd != 0;
    wire rs2_ID_EX_hazard = (EX_rd == ID_rs2) & EX_RegWEn & EX_rd != 0;
    wire rs1_ID_MEM_hazard = (MEM_rd == ID_rs1) & MEM_RegWEn & MEM_rd != 0;
    wire rs2_ID_MEM_hazard = (MEM_rd == ID_rs2) & MEM_RegWEn & MEM_rd != 0;
    wire rs1_ID_WB_hazard = (WB_rd == ID_rs1) & WB_RegWEn & WB_rd != 0;
    wire rs2_ID_WB_hazard = (WB_rd == ID_rs2) & WB_RegWEn & WB_rd !=0;
    assign  pipeline_stop = rs1_ID_EX_hazard | rs2_ID_EX_hazard | rs1_ID_MEM_hazard | rs2_ID_MEM_hazard |rs1_ID_WB_hazard |rs2_ID_WB_hazard;
    
    

  
    
    
    // EX/MEM �Ĵ�����������ð����ͣ���߿���ð����ն�����Ҫ��һֱ��������
    reg [136:0] EX_MEM_REG;                                   // EX/MEM�Ĵ��� [31:0] �� regdata2�� ��63��32����alu�������� ��95��64����imm�� ��127��96����pc��4����128���� RegWen�� 
                                                                //    ��130��129���洢WBSel  ��131���洢MemWEn       [136:132] rd
                                                                
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
    
    // MEM�׶ηô����
        // DRAM ����  ����������// Interface to Bridge��
    assign  Bus_we = MEM_MemWEn;
    assign  Bus_wdata = MEM_regdata2;
    assign  Bus_addr = MEM_ALUres;
    // Bus_rdata ��������
    
    
    // MEM_WB�Ĵ��� һֱ��������
    reg [135:0] MEM_WB_REG;                                //[31:0] �� �洢������ �� ��63��32����alu�������� ��95��64����imm�� ��127��96����pc��4����128���� RegWen�� 
                                                                //    ��130��129���洢WBSel    [135:131] rd
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
    
        // RF��д�����ݶ� data_W2RF ��ֵ
    always @(*) begin
        case(WB_WBSel)
            `WB_ALU:  WB_data_W2RF = WB_ALUres;
            `WB_MEM:  WB_data_W2RF = WB_Memrdata;  //DRAM�������������
            `WB_PC_4: WB_data_W2RF = WB_pc4;         // pc+4��ֵ
            `WB_IMM:  WB_data_W2RF = WB_imm;       
        endcase
    end
    assign WB_d2RF =  WB_data_W2RF;
    
                               
    
//    // IF ��������pc��IF_pc����
//    IF_Module IF (
//        .clk (),
//        .rst (),
//        .EX_npc (),
//        .is_jmp (),
//        .stop  (),
//        .pc (IF_pc) 
           
    
//    );
    
//    assign inst_addr = IF_pc[15:2];     // pc���14λ��ַ��IROM 
    
//    // IF/ID �Ĵ���
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
