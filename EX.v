// ADD, ADDI, ADDU, ADDUI, AND, ANDI, BEQ, BGTZ, BNE, J, JAL, JR, LB, LUI, LW, OR, ORI, SB, SLL, SRL, SW, SUB, XOR, XORI

module EX(
    input wire[5:0] op,
    input wire[5:0] func,
    input wire ex_stop,
    input wire[31:0] data_a,
    input wire[31:0] data_b,
    input wire[31:0] imm,
    input wire[31:0] npc,
    input wire[25:0] jpc,
    
    output reg[31:0] result,
    output reg[31:0] mem_data,
    output reg if_pc_jump,
    output reg[31:0] pc_jumpto,
    output reg load_byte,
    
    input wire[2:0] bubble_cnt_last,
    input wire[2:0] ex_stopcnt_last,
    output reg[2:0] bubble_cnt,
    output reg[2:0] ex_stopcnt,
    output wire delay_slot,
    
    output reg if_forward_reg_write,
    
    // pass
    input wire if_reg_write_i,
    output reg if_reg_write_o,
    input wire if_mem_read_i,
    output reg if_mem_read_o,
    input wire if_mem_write_i,
    output reg if_mem_write_o,
    input wire[4:0] data_write_reg_i,
    output reg[4:0] data_write_reg_o
    );

reg[2:0] bubble_cnt_dec, ex_stopcnt_dec;
assign delay_slot = (~ex_stop) & if_pc_jump;

always @(*) begin
    // passes
    if_reg_write_o <= ex_stop ? 1'b0 : if_reg_write_i;
    if_mem_read_o <= ex_stop ? 1'b0 : if_mem_read_i; // don't R/W if in bubble
    if_mem_write_o <= ex_stop ? 1'b0 : if_mem_write_i;
    data_write_reg_o <= data_write_reg_i;
    
    bubble_cnt_dec = bubble_cnt_last ? bubble_cnt_last - 3'b001 : 3'b000;
    ex_stopcnt_dec = ex_stopcnt_last ? ex_stopcnt_last - 3'b001 : 3'b000;
    
    mem_data <= data_b;
    /*
    find conflicts and pause
    */
    
    // ALU
    case (op)
        6'b000000: begin
            // SPECIAL
            case (func)
            6'b100000: begin
            // ADD
            // TODO: Òì³£
                result <= data_a + data_b;
                bubble_cnt <= bubble_cnt_dec;
                ex_stopcnt <= ex_stopcnt_dec;
                if_forward_reg_write <= ~ex_stop;
                if_pc_jump <= 1'b0;
            end
            
            6'b100001: begin
            // ADDU
              result <= data_a + data_b;
              bubble_cnt <= bubble_cnt_dec;
              ex_stopcnt <= ex_stopcnt_dec;
              if_forward_reg_write <= ~ex_stop;
              if_pc_jump <= 1'b0;
            end
            
            6'b100010: begin
            // SUB
                result <= data_a - data_b;
                bubble_cnt <= bubble_cnt_dec;
                ex_stopcnt <= ex_stopcnt_dec;
                if_forward_reg_write <= ~ex_stop;
                if_pc_jump <= 1'b0;
            end
            
            6'b100100: begin
            // AND
                result <= data_a & data_b;
                bubble_cnt <= bubble_cnt_dec;
                ex_stopcnt <= ex_stopcnt_dec;
                if_forward_reg_write <= ~ex_stop;
                if_pc_jump <= 1'b0;
            end
            
            6'b100101: begin
            // OR
                result <= data_a | data_b;
                bubble_cnt <= bubble_cnt_dec;
                ex_stopcnt <= ex_stopcnt_dec;
                if_forward_reg_write <= ~ex_stop;
                if_pc_jump <= 1'b0;
            end
            
            6'b100110: begin
            // XOR
                result <= data_a ^ data_b;
                bubble_cnt <= bubble_cnt_dec;
                ex_stopcnt <= ex_stopcnt_dec;
                if_forward_reg_write <= ~ex_stop;
                if_pc_jump <= 1'b0;
            end
            
            6'b000000: begin
            // SLL
                result <= data_b << imm[10:6];
                bubble_cnt <= bubble_cnt_dec;
                ex_stopcnt <= ex_stopcnt_dec;
                if_forward_reg_write <= ~ex_stop;
                if_pc_jump <= 1'b0;
            end
            
            6'b000010: begin
            // SRL
                result <= data_b >> imm[10:6];
                bubble_cnt <= bubble_cnt_dec;
                ex_stopcnt <= ex_stopcnt_dec;
                if_forward_reg_write <= ~ex_stop;
                if_pc_jump <= 1'b0;
            end
            
            6'b001000: begin
            // JR
                bubble_cnt <= bubble_cnt_dec;
                ex_stopcnt <= ex_stop ? ex_stopcnt_dec : 3'b010;
                if_pc_jump <= 1'b1;
                pc_jumpto <= data_a; // <<2
                if_forward_reg_write <= 1'b0;
                if_pc_jump <= 1'b0;
            end
            
            default: begin
                bubble_cnt <= bubble_cnt_dec;
                ex_stopcnt <= ex_stopcnt_dec;
                if_forward_reg_write <= 1'b0;
                if_pc_jump <= 1'b0;
                // TODO: exception
            end
            endcase
        end
        
        6'b001000: begin
            // ADDI
            // TODO: Òì³£
            bubble_cnt <= bubble_cnt_dec;
            ex_stopcnt <= ex_stopcnt_dec;
            if_pc_jump <= 1'b0;
            result <= data_a + imm;
            if_forward_reg_write <= ~ex_stop;
        end
        
        6'b001001: begin
            // ADDIU
            bubble_cnt <= bubble_cnt_dec;
            ex_stopcnt <= ex_stopcnt_dec;
            if_pc_jump <= 1'b0;
            result <= data_a + imm;
            if_forward_reg_write <= ~ex_stop;
        end
        
        6'b001100: begin
            // ANDI
            bubble_cnt <= bubble_cnt_dec;
            ex_stopcnt <= ex_stopcnt_dec;
            if_pc_jump <= 1'b0;
            result <= data_a & imm;
            if_forward_reg_write <= ~ex_stop;
        end
        
        6'b001101: begin
            // ORI
            bubble_cnt <= bubble_cnt_dec;
            ex_stopcnt <= ex_stopcnt_dec;
            if_pc_jump <= 1'b0;
            result <= data_a | imm;
            if_forward_reg_write <= ~ex_stop;
        end
        
        6'b001110: begin
            // XORI
            bubble_cnt <= bubble_cnt_dec;
            ex_stopcnt <= ex_stopcnt_dec;
            if_pc_jump <= 1'b0;
            result <= data_a ^ imm;
            if_forward_reg_write <= ~ex_stop;
        end
        
        6'b001111: begin
            // LUI
            bubble_cnt <= bubble_cnt_dec;
            ex_stopcnt <= ex_stopcnt_dec;
            if_pc_jump <= 1'b0;
            result <= (imm << 16);
            if_forward_reg_write <= ~ex_stop;
        end
        
        6'b000100: begin
            // BEQ
            bubble_cnt <= bubble_cnt_dec;
            pc_jumpto <= npc + {imm[29:0], 2'b00};
            if_forward_reg_write <= 1'b0;
            if (data_a == data_b) begin
                ex_stopcnt <= ex_stop ? ex_stopcnt_dec : 3'b010; // clear backward
                if_pc_jump <= 1'b1;
            end
            else begin
                ex_stopcnt <= ex_stopcnt_dec; // dont stap
                if_pc_jump <= 1'b0;
            end
        end
        
        6'b000101: begin
            // BNE
            bubble_cnt <= bubble_cnt_dec;
            pc_jumpto <= npc + {imm[29:0], 2'b00};
            if_forward_reg_write <= 1'b0;
            if (data_a != data_b) begin
                ex_stopcnt <= ex_stop ? ex_stopcnt_dec : 3'b010; // clear backward
                if_pc_jump <= 1'b1;
            end
            else begin
                ex_stopcnt <= ex_stopcnt_dec; // dont stap
                if_pc_jump <= 1'b0;
            end
        end
        
        6'b000111: begin
            // BGTZ
            bubble_cnt <= bubble_cnt_dec;
            pc_jumpto <= npc + {imm[29:0], 2'b00};
            if_forward_reg_write <= 1'b0;
            if (((data_b - data_a)>>31) == 32'b1) begin // signed(A) > signed(B)
                ex_stopcnt <= ex_stop ? ex_stopcnt_dec : 3'b010; // clear backward
                if_pc_jump <= 1'b1;
            end
            else begin
                ex_stopcnt <= ex_stopcnt_dec; // dont stap
                if_pc_jump <= 1'b0;
            end
        end
        
        6'b100011: begin
            // LW
            load_byte <= 1'b0;
            result <= data_a + imm;
            bubble_cnt <= ex_stop ? bubble_cnt_dec : 3'b010; // IF/ID/EX stop
            ex_stopcnt <= ex_stop ? ex_stopcnt_dec : 3'b010; // R/W conflict
            if_pc_jump <= 1'b0;
            if_forward_reg_write <= 1'b0;
        end
        
        6'b100000: begin
            // LB
            load_byte <= 1'b1;
            result <= data_a + imm;
            bubble_cnt <= ex_stop ? bubble_cnt_dec : 3'b010; // IF/ID/EX stop
            ex_stopcnt <= ex_stop ? ex_stopcnt_dec : 3'b010; // R/W conflict
            if_pc_jump <= 1'b0;
            if_forward_reg_write <= 1'b0;
        end
        
        6'b101011: begin
            // SW
            load_byte <= 1'b0;
            result <= data_a + imm;
            mem_data <= data_b; // write mem
            bubble_cnt <= ex_stop ? bubble_cnt_dec : 3'b001; // IF/ID/EX stop
            ex_stopcnt <= ex_stopcnt_dec;
            if_pc_jump <= 1'b0;
            if_forward_reg_write <= 1'b0;
        end
        
        6'b101000: begin
            // SB
            load_byte <= 1'b1;
            result <= data_a + imm;
            mem_data <= data_b; // write mem
            bubble_cnt <= ex_stop ? bubble_cnt_dec : 3'b001; // IF/ID/EX stop
            ex_stopcnt <= ex_stopcnt_dec;
            if_pc_jump <= 1'b0;
            if_forward_reg_write <= 1'b0;
        end
        
        6'b000010: begin
            // J
            bubble_cnt <= bubble_cnt_dec;
            ex_stopcnt <= ex_stop ? ex_stopcnt_dec : 3'b010;
            if_pc_jump <= 1'b1;
            pc_jumpto <= {4'b0000, jpc, 2'b00}; // <<2
            if_forward_reg_write <= 1'b0;
        end
        
        6'b000011: begin
            // JAL
            result <= npc + 32'd4;
            bubble_cnt <= bubble_cnt_dec;
            ex_stopcnt <= ex_stop ? ex_stopcnt_dec : 3'b010;
            if_pc_jump <= 1'b1;
            pc_jumpto <= {4'b0000, jpc, 2'b00}; // <<2
            if_forward_reg_write <= 1'b0;
        end
        
        default: begin
            // unknown
            bubble_cnt <= bubble_cnt_dec;
            ex_stopcnt <= ex_stopcnt_dec;
            if_pc_jump <= 1'b0;
            if_forward_reg_write <= 1'b0;
            // TODO: exception
        end
    endcase
end

endmodule
