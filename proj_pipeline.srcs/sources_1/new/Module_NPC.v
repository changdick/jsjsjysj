`timescale 1ns / 1ps
`include "defines.vh"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// author:220110430 
// 
// Create Date: 2024/07/10 09:53:58
// Design Name: 
// Module Name: Module_NPC
// �����ź�Ϊ  32λpc ��cpu���inst_addr����PC.pc����    |  32λ������ƫ��offset������������ģ�����ɵ�������imm     |  1bit ����ֵbr   |    32λ regpc   |    ����op ���Կ���ģ��
// ����ź�Ϊ  32λnpc�� ����PC.din     |    32λpc4    PC+4 д�ؼĴ��� ����jal��jalr
// ���ݿ����źŵĲ�ͬ��������߼����ɲ�ͬ��npc�źš���PC�������У� 1 ˳��ִ��ָ�� PC+4    2 ��������ת��B��ָ�   ��������op��ѡ��������֧Branch����ʱҪͨ��Alu������br�ź��ж�ʹ��PC+Offset����PC+4
// 3 ��������ת��jalָ�� PC���Ѱַ�� op������ѡ��PC_Offset, PC+Offset          4  ��������ת��jalrָ�� ��ַѰַ op����ѡ��Reg_PC, ֱ��ʹ��regpc��Ϊnpc
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
//    ����pc+4
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

