// Annotate this macro before synthesis
// `define RUN_TRACE

// TODO: 鍦ㄦ澶勫畾涔変綘鐨勫畯  在此处定义你的宏
//
// NPC OP
`define NEXTPC_PC_STAY       3'b000
`define NEXTPC_PC_4          3'b001
`define NEXTPC_BR            3'b010
`define NEXTPC_PC_OFFSET     3'b011
`define NEXTPC_REG_PC        3'b100
// ImmGen ImmSel
`define ImmSel_I         3'b000
`define ImmSel_B         3'b001
`define ImmSel_U         3'b010
`define ImmSel_J         3'b011
`define ImmSel_S         3'b100 
`define ImmSel_ISHIFT    3'b101 

// ALU_Sel
`define ALU_ADD         4'b0000
`define ALU_SUB         4'b0001
`define ALU_AND         4'b0010
`define ALU_OR          4'b0011
`define ALU_XOR         4'b0100
`define ALU_SLL         4'b0101
`define ALU_SRL         4'b0110
`define ALU_SRA         4'b0111
`define ALU_BEQ         4'b1000
`define ALU_BNE         4'b1001
`define ALU_BGE         4'b1010
`define ALU_BLT         4'b1011

// alu第二个数据输入的选择
`define AluD2Sel_REG    1'b0
`define AluD2Sel_IMM    1'b1

// WBSel
`define WB_ALU          2'b00
`define WB_MEM          2'b01
`define WB_PC_4         2'b10
`define WB_IMM          2'b11

// 澶栬I/O鎺ュ彛鐢佃矾鐨勭鍙ｅ湴鍧? 外设I/O接口电路的端口地址
`define PERI_ADDR_DIG   32'hFFFF_F000
`define PERI_ADDR_LED   32'hFFFF_F060
`define PERI_ADDR_SW    32'hFFFF_F070
`define PERI_ADDR_BTN   32'hFFFF_F078
