`timescale 1ns / 1ps
`include "defines.vh"

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/12 14:16:29
// Design Name: 
// Module Name: ControlLogic
// 控制模块  输入信号为 32位的指令直接作为输入  输出是定义好的7个控制信号


// 
//////////////////////////////////////////////////////////////////////////////////


module ControlLogic(
    input [31:0]     inst,
    
    output reg [2:0] npc_op,
    output reg      RegWEn,
    output reg [2:0] ImmSel,
    output reg [3:0] ALU_Sel,
    output reg       MemWEn,
    output reg       aluD2Sel,
    output reg [1:0] WBSel 
    );
    wire [6:0] opcode;
    wire [2:0] func3;
    wire [6:0] func7;
    assign opcode = inst[6:0];
    assign func7 = inst[31:25];
    assign func3 = inst[14:12];
    // 不能加一个信号来过渡
    
    // RegWEn

    
    // npc_op
    always @(*) begin
//        npc_op = `NEXTPC_PC_STAY;       // npc选择pc不动， 寄存器不写，存储器也不写，那么这个初始状态实质上就是空指令

//        ImmSel = `ImmSel_I;
//        ALU_Sel = `ALU_ADD;
//        MemWEn = 1'b0;                 // 存储器写使能
//        aluD2Sel = `AluD2Sel_REG;
//        WBSel = `WB_ALU;
        // case语句 根据opcode 和func3和func7 设置控制信号
//        case(opcode)
        case(inst[6:0])
            7'b0110011: begin   //R Type
//                case({func3 , func7})
                case({inst[14:12],inst[31:25]})
                    10'b000_0000000:begin  npc_op = `NEXTPC_PC_4;RegWEn = 1'b1; ImmSel = `ImmSel_I;   ALU_Sel = `ALU_ADD;    MemWEn = 1'b0;    aluD2Sel = `AluD2Sel_REG;    WBSel = `WB_ALU;  end
                    10'b000_0100000:begin  npc_op = `NEXTPC_PC_4;RegWEn = 1'b1; ImmSel = `ImmSel_I;   ALU_Sel = `ALU_SUB;    MemWEn = 1'b0;    aluD2Sel = `AluD2Sel_REG;    WBSel = `WB_ALU;  end
                    10'b111_0000000:begin  npc_op = `NEXTPC_PC_4;RegWEn = 1'b1; ImmSel = `ImmSel_I;   ALU_Sel = `ALU_AND;    MemWEn = 1'b0;    aluD2Sel = `AluD2Sel_REG;    WBSel = `WB_ALU;  end
                    10'b110_0000000:begin  npc_op = `NEXTPC_PC_4;RegWEn = 1'b1; ImmSel = `ImmSel_I;   ALU_Sel = `ALU_OR ;    MemWEn = 1'b0;    aluD2Sel = `AluD2Sel_REG;    WBSel = `WB_ALU;  end
                    10'b100_0000000:begin  npc_op = `NEXTPC_PC_4;RegWEn = 1'b1; ImmSel = `ImmSel_I;   ALU_Sel = `ALU_XOR;    MemWEn = 1'b0;    aluD2Sel = `AluD2Sel_REG;    WBSel = `WB_ALU;  end
                    10'b001_0000000:begin  npc_op = `NEXTPC_PC_4;RegWEn = 1'b1; ImmSel = `ImmSel_I;   ALU_Sel = `ALU_SLL;    MemWEn = 1'b0;    aluD2Sel = `AluD2Sel_REG;    WBSel = `WB_ALU;  end
                    10'b101_0000000:begin  npc_op = `NEXTPC_PC_4;RegWEn = 1'b1; ImmSel = `ImmSel_I;   ALU_Sel = `ALU_SRL;    MemWEn = 1'b0;    aluD2Sel = `AluD2Sel_REG;    WBSel = `WB_ALU;  end
                    10'b101_0100000:begin  npc_op = `NEXTPC_PC_4;RegWEn = 1'b1; ImmSel = `ImmSel_I;   ALU_Sel = `ALU_SRA;    MemWEn = 1'b0;    aluD2Sel = `AluD2Sel_REG;    WBSel = `WB_ALU;  end
                endcase
            end
            7'b0010011:begin  // I Type(lw,jalr excepted)
//                case({func3,func7})
                casez({inst[14:12],inst[31:25]})

                    10'b000_???????: begin  npc_op = `NEXTPC_PC_4; RegWEn = 1'b1;  ImmSel = `ImmSel_I;        ALU_Sel = `ALU_ADD;  MemWEn = 1'b0;  aluD2Sel = `AluD2Sel_IMM; WBSel = `WB_ALU;  end
                    10'b111_???????: begin  npc_op = `NEXTPC_PC_4; RegWEn = 1'b1;  ImmSel = `ImmSel_I;        ALU_Sel = `ALU_AND;  MemWEn = 1'b0;  aluD2Sel = `AluD2Sel_IMM; WBSel = `WB_ALU;  end
                    10'b110_???????: begin  npc_op = `NEXTPC_PC_4; RegWEn = 1'b1;  ImmSel = `ImmSel_I;        ALU_Sel = `ALU_OR ;  MemWEn = 1'b0;  aluD2Sel = `AluD2Sel_IMM; WBSel = `WB_ALU;  end
                    10'b100_???????: begin  npc_op = `NEXTPC_PC_4; RegWEn = 1'b1;  ImmSel = `ImmSel_I;        ALU_Sel = `ALU_XOR;  MemWEn = 1'b0;  aluD2Sel = `AluD2Sel_IMM; WBSel = `WB_ALU;  end
                    10'b001_0000000:begin  npc_op = `NEXTPC_PC_4; RegWEn = 1'b1; ImmSel = `ImmSel_ISHIFT;  ALU_Sel = `ALU_SLL;  MemWEn = 1'b0;  aluD2Sel = `AluD2Sel_IMM; WBSel = `WB_ALU;  end
                    10'b101_0000000:begin  npc_op = `NEXTPC_PC_4; RegWEn = 1'b1; ImmSel = `ImmSel_ISHIFT;  ALU_Sel = `ALU_SRL;  MemWEn = 1'b0;  aluD2Sel = `AluD2Sel_IMM; WBSel = `WB_ALU;  end
                    10'b101_0100000:begin  npc_op = `NEXTPC_PC_4; RegWEn = 1'b1; ImmSel = `ImmSel_ISHIFT;  ALU_Sel = `ALU_SRA;  MemWEn = 1'b0;  aluD2Sel = `AluD2Sel_IMM; WBSel = `WB_ALU;  end
                endcase
                
            end
            7'b0000011: begin //Load
//                case(func3)
                case(inst[14:12])
                    3'b010: begin  npc_op =`NEXTPC_PC_4;  RegWEn = 1'b1;  ImmSel = `ImmSel_I;   ALU_Sel = `ALU_ADD;   MemWEn = 1'b0;  aluD2Sel = `AluD2Sel_IMM;  WBSel = `WB_MEM;   end
                    
                endcase
            end
            7'b1100111: begin  // jalr
//                case(func3)
                case(inst[14:12])
                    3'b000: begin  npc_op = `NEXTPC_REG_PC; RegWEn = 1'b1;   ImmSel = `ImmSel_I;  ALU_Sel = `ALU_ADD;  MemWEn = 1'b0; aluD2Sel = `AluD2Sel_IMM; WBSel =  `WB_PC_4;  end    
                endcase
            end
            7'b0100011: begin  //S Type
//                case(func3)
                case(inst[14:12])
                    3'b010:begin npc_op = `NEXTPC_PC_4; RegWEn = 1'b0;  ImmSel = `ImmSel_S; ALU_Sel = `ALU_ADD; MemWEn = 1'b1;  aluD2Sel = `AluD2Sel_IMM;    WBSel =  `WB_ALU;  end
                endcase
            end
            7'b1100011:begin    //B type
//                case(func3)
                case(inst[14:12])
                    3'b000: begin npc_op = `NEXTPC_BR; RegWEn = 1'b0;   ImmSel = `ImmSel_B;  ALU_Sel = `ALU_BEQ;  MemWEn = 1'b0; aluD2Sel = `AluD2Sel_REG; WBSel =  `WB_PC_4;  end
                    3'b001: begin npc_op = `NEXTPC_BR; RegWEn = 1'b0;   ImmSel = `ImmSel_B;  ALU_Sel = `ALU_BNE;  MemWEn = 1'b0; aluD2Sel = `AluD2Sel_REG; WBSel =  `WB_PC_4;  end
                    3'b100: begin npc_op = `NEXTPC_BR; RegWEn = 1'b0;   ImmSel = `ImmSel_B;  ALU_Sel = `ALU_BLT;  MemWEn = 1'b0; aluD2Sel = `AluD2Sel_REG; WBSel =  `WB_PC_4;  end
                    3'b101: begin npc_op = `NEXTPC_BR; RegWEn = 1'b0;   ImmSel = `ImmSel_B;  ALU_Sel = `ALU_BGE;  MemWEn = 1'b0; aluD2Sel = `AluD2Sel_REG; WBSel =  `WB_PC_4;  end
                endcase
            end
            7'b0110111: begin  //lui 
                npc_op = `NEXTPC_PC_4;  RegWEn = 1'b1;    ImmSel = `ImmSel_U; ALU_Sel = `ALU_ADD;  MemWEn = 1'b0; aluD2Sel = `AluD2Sel_REG;  WBSel = `WB_IMM;
            end
            7'b1101111:begin   // jal
                npc_op = `NEXTPC_PC_OFFSET;  RegWEn = 1'b1;  ImmSel = `ImmSel_J;  ALU_Sel = `ALU_ADD;    MemWEn = 1'b0;   aluD2Sel = `AluD2Sel_REG;  WBSel = `WB_PC_4;
            end
            default: begin
                npc_op = `NEXTPC_PC_STAY;       // npc选择pc不动， 寄存器不写，存储器也不写，那么这个初始状态实质上就是空指令
                RegWEn = 1'b0;
                ImmSel = `ImmSel_I;
                ALU_Sel = `ALU_ADD;
                MemWEn = 1'b0;                 // 存储器写使能
                aluD2Sel = `AluD2Sel_REG;
                WBSel = `WB_ALU;
            end
        endcase
    end
    
endmodule
