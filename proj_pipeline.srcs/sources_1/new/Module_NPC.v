`timescale 1ns / 1ps
`include "defines.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// author:220110430 
// 
// Create Date: 2024/07/10 09:53:58
// Design Name: 
// Module Name: Module_NPC
// 输入信号为  32位pc 接cpu里的inst_addr，由PC.pc发出    |  32位立即数偏移offset，立即数生成模块生成的立即数imm     |  1bit 布尔值br   |    32位 regpc   |    操作op 来自控制模块
// 输出信号为  32位npc， 接入PC.din     |    32位pc4    PC+4 写回寄存器 用于jal和jalr
// 根据控制信号的不同，用组合逻辑生成不同的npc信号。新PC的生成有： 1 顺序执行指令 PC+4    2 有条件跳转（B型指令）   操作类型op会选择条件分支Branch，此时要通过Alu发来的br信号判断使用PC+Offset或者PC+4
// 3 无条件跳转的jal指令 PC相对寻址， op操作会选择PC_Offset, PC+Offset          4  无条件跳转的jalr指令 基址寻址 op操作选择Reg_PC, 直接使用regpc作为npc
// 
//////////////////////////////////////////////////////////////////////////////////


module Module_NPC(
    input [31:0] pc,
    input [31:0] offset,
    input br,
    input [31:0] regpc,
    input [2:0] op,
    output reg  [31:0] npc,
    output wire [31:0] pc4
    
    );
//    计算pc+4
    assign pc4 = pc + 4;
//     generate npc
    always@(*) begin
        case (op)
            `NEXTPC_PC_4: npc = pc4;
            `NEXTPC_BR:   begin
                if(br) npc = pc + offset;
                else   npc = pc4;
            end
            `NEXTPC_PC_OFFSET: npc = pc + offset;
            `NEXTPC_REG_PC:     npc = regpc;
            default:           npc = pc4;
         endcase
    end




endmodule

