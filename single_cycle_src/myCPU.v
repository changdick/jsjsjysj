`timescale 1ns / 1ps

`include "defines.vh"

module myCPU (
    input  wire         cpu_rst,
    input  wire         cpu_clk,

    // Interface to IROM  if RUN_TRACE     if REAL 14bit   ��ΪIROMģ�����õ�Ѱַ��λ��32λ��������ߵ�ַ��ģ���ʱ���ǰ�BѰַ������ʵ����ROM��ʱ�����ֱ�Ӱ�4BѰַ
`ifdef RUN_TRACE
    output wire [15:0]  inst_addr,
`else
    output wire [13:0]  inst_addr,
`endif
    input  wire [31:0]  inst,
    
    // Interface to Bridge
    output wire [31:0]  Bus_addr,            // ������ѡַ�ź�
    input  wire [31:0]  Bus_rdata,           // д�������
    output wire         Bus_we,               // �������źŵ� MemWEn
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

    // TODO: 完成你自己的单周期CPU设计 ������Լ��ĵ�����CPU���
    wire [31:0] pc;
    wire [31:0] npc;                // npcģ��  ->  PCģ��
    wire [31:0] pc4;           //PC + 4   ��NPC.pc4�˿ڣ���RF
    wire [31:0] imm;
   
    // ALU����������ź�
    wire aluD2Sel; // ����ǿ����ź�
    wire [31:0] aludata1;
    wire [31:0] aludata2;
    wire [31:0] alu_result;
    wire        alu_bool;
    
    // �����ź�   
    

    wire [2:0] npc_op;
    wire       RegWEn;
    wire [2:0] ImmSel;
    wire [3:0] ALU_Sel;
    wire       MemWEn;
    // aluD2Sel ���涨����
    wire [1:0] WBSel;
    
    // PCģ��
    ProgramCounter PC(
        .din   (npc),
        .rst   (cpu_rst),
        .clk   (cpu_clk),
        
        .pc    (pc)
    );
    // NPCģ��
    Module_NPC NPC (
        .pc           (pc),
        .offset       (imm),          //��������
        .br           (alu_bool),             
        .regpc        (alu_result),
        .op           (npc_op),
        
        .npc          (npc),
        .pc4          (pc4)
    );
    
    // inst_addr  �ź� ��Ϊ���cpu��IROM��ѡַ�źţ� �������14λ����16λ
        // Interface between CPU and IROM
`ifdef RUN_TRACE
//wire [15:0]  inst_addr,
   assign inst_addr = pc[17:2] ;
`else
   assign inst_addr = pc[15:2];
`endif
    
    // ������������
    ImmGenerator ImmGen (
        .din          (inst[31:7]),
        .immsel       (ImmSel),            // ����ģ�����������������ѡ��
        
        .imm          (imm)             //���������ź�
    
    );
    
    wire [31:0] regdata1;
    wire [31:0] regdata2; 
    reg  [31:0] data_W2RF;
    
    // RF��д�����ݶ� data_W2RF ��ֵ
    always @(*) begin
        case(WBSel)
            `WB_ALU:  data_W2RF = alu_result;
            `WB_MEM:  data_W2RF = Bus_rdata;  //DRAM�������������
            `WB_PC_4: data_W2RF = pc4;         // pc+4��ֵ
            `WB_IMM:  data_W2RF = imm;       
        endcase
    end
    
    // �Ĵ�����
    RegisterFile RF (
        .rs1           (inst[19:15]),
        .rs2           (inst[24:20]),       
        .rd            (inst[11:7]),
        .wen           (RegWEn),                       //��������������дʹ���ź�
        .wdata         (data_W2RF),             //WB�׶ε�д���ź� һ���ĸ���Դ
        .rst           (cpu_rst),
        .clk           (cpu_clk),   
        
        .data1         (regdata1),                                //��alu�����1
        .data2         (regdata2)                                // ��alu�����2��Ҫ��������ѡ    ��Ҫ�͵�DRAMͨ��������(Bus_wdata = ����ӳ���)
    
    
    );
   
    // ALU�����ֵ��ѡ��
    assign aludata1 = regdata1;
    assign aludata2 = (aluD2Sel == `AluD2Sel_REG)? regdata2: imm;
    // ALUģ��
    Module_ALU alu (
        .dataA              (aludata1),         // ��RF�ų�����data1
        .dataB              (aludata2),         // RF.data2����ImmGen.imm,���ݿ����ź�ѡ��
        .ALU_Sel            (ALU_Sel),         // �����ź������ѡ��
        .result             (alu_result),         // ��DRAM����ѡ���ַ��Ҳ����Ҫ���(��Bus_addr)������RF��д�����ݶˣ���Ҫ����NPC.regpc����jalrָ�����pc
        .bool               (alu_bool)          // ��NPC.br����B��ָ���Ƿ���ת
    );
    
    // DRAM ����  ����������// Interface to Bridge��
    assign  Bus_we = MemWEn;
    assign  Bus_wdata = regdata2;
    assign  Bus_addr = alu_result;
    
    
    
    // �����߼�
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


// TRace���Ե�ʱ��ȡָ����ȷ�ˣ���������ָ�����1�����ڣ����Ե����ź�ȫ����һ���Ĵ������ӻ�һ������

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
    assign debug_wb_pc        = PC0;              // �˽׶ε�pc
    assign debug_wb_ena       = RegWEn0;
    assign debug_wb_reg       = rd0;
    assign debug_wb_value     = data0;
`endif

endmodule
