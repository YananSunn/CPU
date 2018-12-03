parameter EX_ADDR_INIT = 32'h80001180;

module EX(
    input wire clk,
    input wire rst,

    input wire[5:0] op,
    input wire[5:0] func,
    input wire ex_stop,
    input wire[31:0] data_a,
    input wire[31:0] data_b,
    input wire[31:0] simm,
    input wire[31:0] zimm,
    input wire[31:0] npc,
    input wire[25:0] jpc,
    
    output reg[31:0] result,
    output reg[31:0] mem_data,
    output reg if_pc_jump,
    output reg[31:0] pc_jumpto,
    output reg[4:0] load_byte,
    
    input wire[2:0] bubble_cnt_last,
    input wire[2:0] ex_stopcnt_last,
    output reg[2:0] bubble_cnt,
    output reg[2:0] ex_stopcnt,
    output wire delay_slot,
    output reg exception,
    output reg[5:0] ex_cause,
    
    output reg if_forward_reg_write,
    
    // pass
    input wire if_reg_write_i,
    output reg if_reg_write_o,
    input wire if_mem_read_i,
    output reg if_mem_read_o,
    input wire if_mem_write_i,
    output reg if_mem_write_o,
    input wire[4:0] data_write_reg_i,
    output reg[4:0] data_write_reg_o,
    
    //ex
    input wire if_dealing_ex,
    input wire[4:0] dealing_ex_cause
    );

reg[2:0] bubble_cnt_dec, ex_stopcnt_dec;
assign delay_slot = if_pc_jump;

parameter BVA = 8;
parameter STATUS = 12;
parameter CAUSE = 13;
parameter EPC = 14;
reg [31:0] hi, lo, cp0[0:31];
wire[31:0] sl_addr = data_a + simm;

reg [31:0] bad_addr;
reg last_ds, after_last_ds;

always @(*) begin
    // passes
    if_reg_write_o <= ex_stop ? 1'b0 : if_reg_write_i;
    if_mem_read_o <= ex_stop ? 1'b0 : if_mem_read_i; // don't R/W if in bubble
    if_mem_write_o <= ex_stop ? 1'b0 : if_mem_write_i;
    data_write_reg_o <= data_write_reg_i;
    
    bubble_cnt_dec = bubble_cnt_last ? bubble_cnt_last - 3'b001 : 3'b000;
    ex_stopcnt_dec = ex_stopcnt_last ? ex_stopcnt_last - 3'b001 : 3'b000;
    
    mem_data <= data_b;
    
    result <= 32'h00000000; // avoid latches
    pc_jumpto <= 32'h00000000; // avoid latches
    load_byte <= 5'b01111;
    
    exception <= 1'b0;
    ex_cause <=  5'b00000;
    bad_addr <= 32'h00000000;
    
    // ALU
    case (op)
    6'b000000: begin
        // SPECIAL
        case (func)
        6'b100000: begin
        // ADD
        // TODO: 算术异常
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
        // TODO: 算术异常
            result <= data_a - data_b;
            bubble_cnt <= bubble_cnt_dec;
            ex_stopcnt <= ex_stopcnt_dec;
            if_forward_reg_write <= ~ex_stop;
            if_pc_jump <= 1'b0;
        end
        
        6'b100011: begin
        // SUBU
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
        
        6'b100111: begin
        // NOR
            result <= ~(data_a | data_b);
            bubble_cnt <= bubble_cnt_dec;
            ex_stopcnt <= ex_stopcnt_dec;
            if_forward_reg_write <= ~ex_stop;
            if_pc_jump <= 1'b0;
        end
        
        6'b000000: begin
        // SLL
            result <= data_b << zimm[10:6];
            bubble_cnt <= bubble_cnt_dec;
            ex_stopcnt <= ex_stopcnt_dec;
            if_forward_reg_write <= ~ex_stop;
            if_pc_jump <= 1'b0;
        end

        6'b000100: begin
        // SLLV
            result <= data_b << data_a[4:0];
            bubble_cnt <= bubble_cnt_dec;
            ex_stopcnt <= ex_stopcnt_dec;
            if_forward_reg_write <= ~ex_stop;
            if_pc_jump <= 1'b0;
        end
        
        6'b000010: begin
        // SRL
            result <= data_b >> zimm[10:6];
            bubble_cnt <= bubble_cnt_dec;
            ex_stopcnt <= ex_stopcnt_dec;
            if_forward_reg_write <= ~ex_stop;
            if_pc_jump <= 1'b0;
        end
        
        6'b000110: begin
        // SRLV
            result <= data_b >> data_a[4:0];
            bubble_cnt <= bubble_cnt_dec;
            ex_stopcnt <= ex_stopcnt_dec;
            if_forward_reg_write <= ~ex_stop;
            if_pc_jump <= 1'b0;
        end
        
        6'b000011: begin
        // SRA
            result <= ($signed(data_b)) >>> zimm[10:6];
            bubble_cnt <= bubble_cnt_dec;
            ex_stopcnt <= ex_stopcnt_dec;
            if_forward_reg_write <= ~ex_stop;
            if_pc_jump <= 1'b0;
        end
        
        6'b000111: begin
        // SRAV
            result <= ($signed(data_b)) >>> data_a[4:0];
            bubble_cnt <= bubble_cnt_dec;
            ex_stopcnt <= ex_stopcnt_dec;
            if_forward_reg_write <= ~ex_stop;
            if_pc_jump <= 1'b0;
        end
        
        6'b101010: begin
        // SLT
            result <= ($signed(data_a) < $signed(data_b));
            bubble_cnt <= bubble_cnt_dec;
            ex_stopcnt <= ex_stopcnt_dec;
            if_forward_reg_write <= ~ex_stop;
            if_pc_jump <= 1'b0;
        end
        
        6'b101011: begin
        // SLTU
            result <= data_a < data_b ? 32'h00000001 : 32'h00000000;
            bubble_cnt <= bubble_cnt_dec;
            ex_stopcnt <= ex_stopcnt_dec;
            if_forward_reg_write <= ~ex_stop;
            if_pc_jump <= 1'b0;
        end
        
        6'b001000: begin
        // JR
            bubble_cnt <= bubble_cnt_dec;
            ex_stopcnt <= ex_stop ? ex_stopcnt_dec : 3'b010;
            pc_jumpto <= data_a;
            if_forward_reg_write <= 1'b0;
            if_pc_jump <= ~ex_stop;
        end
        
        6'b001001: begin
        // JALR
            result <= npc + 32'd4;
            bubble_cnt <= bubble_cnt_dec;
            ex_stopcnt <= ex_stop ? ex_stopcnt_dec : 3'b010;
            pc_jumpto <= data_a;
            if_forward_reg_write <= 1'b1;
            if_pc_jump <= ~ex_stop;
        end
        
        6'b010000: begin
        // MFHI
            result <= hi;
            bubble_cnt <= bubble_cnt_dec;
            ex_stopcnt <= ex_stopcnt_dec;
            if_forward_reg_write <= ~ex_stop;
            if_pc_jump <= 1'b0;
        end
        
        6'b010010: begin
        // MFLO
            result <= lo;
            bubble_cnt <= bubble_cnt_dec;
            ex_stopcnt <= ex_stopcnt_dec;
            if_forward_reg_write <= ~ex_stop;
            if_pc_jump <= 1'b0;
        end
        
        6'b010011, 6'b010001: begin
        // MTLO, MTHI
            bubble_cnt <= bubble_cnt_dec;
            ex_stopcnt <= ex_stopcnt_dec;
            if_forward_reg_write <= 1'b0;
            if_pc_jump <= 1'b0;
        end
        
        6'b001100: begin
        // SYSCALL
            ex_cause <= 5'd8;
            bubble_cnt <= 3'b000;
            ex_stopcnt <= 3'b010;
            if_forward_reg_write <= 1'b0;
            if_pc_jump <= 1'b1;
            exception <= 1'b1;
            pc_jumpto <= EX_ADDR_INIT;
        end
        
        6'b001101: begin
        // BREAK
            ex_cause <= 5'd9;
            bubble_cnt <= 3'b000;
            ex_stopcnt <= 3'b010;
            if_forward_reg_write <= 1'b0;
            if_pc_jump <= 1'b1;
            exception <= 1'b1;
            pc_jumpto <= EX_ADDR_INIT;
        end
        
        default: begin
            // exception
            ex_cause <= 5'd10;
            bubble_cnt <= 3'b000;
            ex_stopcnt <= 3'b010;
            if_forward_reg_write <= 1'b0;
            if_pc_jump <= 1'b1;
            exception <= 1'b1;
            pc_jumpto <= EX_ADDR_INIT;
        end
        endcase
    end
    
    6'b010000: begin
        // COP0
        case (jpc[25:21])
        5'b00100: begin
            // MTC0
            bubble_cnt <= bubble_cnt_dec;
            ex_stopcnt <= ex_stopcnt_dec;
            if_pc_jump <= 1'b0;
            if_forward_reg_write <= 1'b0;
        end
        5'b0000: begin
            // MFC0
            result <= cp0[jpc[15:11]];
            bubble_cnt <= bubble_cnt_dec;
            ex_stopcnt <= ex_stopcnt_dec;
            if_pc_jump <= 1'b0;
            if_forward_reg_write <= ~ex_stop;
        end
        5'b10000: begin
            if (func == 6'b011000) begin
            // ERET
                bubble_cnt <= bubble_cnt_dec;
                ex_stopcnt <= ex_stop ? ex_stopcnt_dec : 3'b010;
                if_pc_jump <= ~ex_stop;
                pc_jumpto <= cp0[EPC]; // <<2
                if_forward_reg_write <= 1'b0;
            end
            else begin
                bubble_cnt <= bubble_cnt_dec;
                ex_stopcnt <= ex_stopcnt_dec;
                if_pc_jump <= 1'b0;
                if_forward_reg_write <= 1'b0;
            end
        end
        default: begin
            bubble_cnt <= bubble_cnt_dec;
            ex_stopcnt <= ex_stopcnt_dec;
            if_pc_jump <= 1'b0;
            if_forward_reg_write <= 1'b0;
        end
        endcase
    end
    
    6'b001000: begin
        // ADDI
        // TODO: 异常
        bubble_cnt <= bubble_cnt_dec;
        ex_stopcnt <= ex_stopcnt_dec;
        if_pc_jump <= 1'b0;
        result <= data_a + simm;
        if_forward_reg_write <= ~ex_stop;
    end
    
    6'b001001: begin
        // ADDIU
        bubble_cnt <= bubble_cnt_dec;
        ex_stopcnt <= ex_stopcnt_dec;
        if_pc_jump <= 1'b0;
        result <= data_a + simm;
        if_forward_reg_write <= ~ex_stop;
    end
    
    6'b001100: begin
        // ANDI
        bubble_cnt <= bubble_cnt_dec;
        ex_stopcnt <= ex_stopcnt_dec;
        if_pc_jump <= 1'b0;
        result <= data_a & zimm;
        if_forward_reg_write <= ~ex_stop;
    end
    
    6'b001101: begin
        // ORI
        bubble_cnt <= bubble_cnt_dec;
        ex_stopcnt <= ex_stopcnt_dec;
        if_pc_jump <= 1'b0;
        result <= data_a | zimm;
        if_forward_reg_write <= ~ex_stop;
    end
    
    6'b001110: begin
        // XORI
        bubble_cnt <= bubble_cnt_dec;
        ex_stopcnt <= ex_stopcnt_dec;
        if_pc_jump <= 1'b0;
        result <= data_a ^ zimm;
        if_forward_reg_write <= ~ex_stop;
    end
    
    6'b001010: begin
        // SLTI
        bubble_cnt <= bubble_cnt_dec;
        ex_stopcnt <= ex_stopcnt_dec;
        if_pc_jump <= 1'b0;
        result <= ($signed(data_a) < $signed(simm));
        if_forward_reg_write <= ~ex_stop;
    end
    
    6'b001011: begin
        // SLTIU
        bubble_cnt <= bubble_cnt_dec;
        ex_stopcnt <= ex_stopcnt_dec;
        if_pc_jump <= 1'b0;
        result <= data_a < simm ? 32'h00000001 : 32'h00000000;
        if_forward_reg_write <= ~ex_stop;
    end
    
    6'b001111: begin
        // LUI
        bubble_cnt <= bubble_cnt_dec;
        ex_stopcnt <= ex_stopcnt_dec;
        if_pc_jump <= 1'b0;
        result <= (zimm << 16);
        if_forward_reg_write <= ~ex_stop;
    end
    
    6'b000010: begin
        // J
        bubble_cnt <= bubble_cnt_dec;
        ex_stopcnt <= ex_stop ? ex_stopcnt_dec : 3'b010;
        if_pc_jump <= ~ex_stop;
        pc_jumpto <= {npc[31:28], jpc, 2'b00}; // <<2
        if_forward_reg_write <= 1'b0;
    end
    
    6'b000011: begin
        // JAL
        result <= npc + 32'd4;
        bubble_cnt <= bubble_cnt_dec;
        ex_stopcnt <= ex_stop ? ex_stopcnt_dec : 3'b010;
        if_pc_jump <= ~ex_stop;
        pc_jumpto <= {npc[31:28], jpc, 2'b00}; // <<2
        if_forward_reg_write <= ~ex_stop;
    end
            
    6'b000100: begin
        // BEQ
        bubble_cnt <= bubble_cnt_dec;
        pc_jumpto <= npc + {simm[29:0], 2'b00};
        if_forward_reg_write <= 1'b0;
        if (data_a == data_b) begin
            ex_stopcnt <= ex_stop ? ex_stopcnt_dec : 3'b010; // clear backward
            if_pc_jump <= ~ex_stop;
        end
        else begin
            ex_stopcnt <= ex_stopcnt_dec; // dont stap
            if_pc_jump <= 1'b0;
        end
    end
    
    6'b000101: begin
        // BNE
        bubble_cnt <= bubble_cnt_dec;
        pc_jumpto <= npc + {simm[29:0], 2'b00};
        if_forward_reg_write <= 1'b0;
        if (data_a != data_b) begin
            ex_stopcnt <= ex_stop ? ex_stopcnt_dec : 3'b010; // clear backward
            if_pc_jump <= ~ex_stop;
        end
        else begin
            ex_stopcnt <= ex_stopcnt_dec; // dont stap
            if_pc_jump <= 1'b0;
        end
    end
    
    6'b000111: begin
        // BGTZ
        bubble_cnt <= bubble_cnt_dec;
        pc_jumpto <= npc + {simm[29:0], 2'b00};
        if_forward_reg_write <= 1'b0;
        if ($signed(data_a) > $signed(data_b)) begin // signed(A) > signed(B)
            ex_stopcnt <= ex_stop ? ex_stopcnt_dec : 3'b010; // clear backward
            if_pc_jump <= ~ex_stop;
        end
        else begin
            ex_stopcnt <= ex_stopcnt_dec; // dont stap
            if_pc_jump <= 1'b0;
        end
    end
    
    6'b000110: begin
        // BLEZ
        bubble_cnt <= bubble_cnt_dec;
        pc_jumpto <= npc + {simm[29:0], 2'b00};
        if_forward_reg_write <= 1'b0;
        if ($signed(data_a) <= $signed(data_b)) begin // signed(A) <= signed(B)
            ex_stopcnt <= ex_stop ? ex_stopcnt_dec : 3'b010; // clear backward
            if_pc_jump <= ~ex_stop;
        end
        else begin
            ex_stopcnt <= ex_stopcnt_dec; // dont stap
            if_pc_jump <= 1'b0;
        end
    end
    
    6'b000001: begin
        // REGIMM
        bubble_cnt <= bubble_cnt_dec;
        pc_jumpto <= npc + {simm[29:0], 2'b00};
        result <= npc + 32'd4;
        case (jpc[20:16]) // ins[20:16]
        5'b00000, 5'b10000: begin
            // BLTZ(AL)
            if_forward_reg_write <= (~ex_stop) & jpc[20];
            if (data_a[31]) begin // signed(A) < 0
                ex_stopcnt <= ex_stop ? ex_stopcnt_dec : 3'b010; // clear backward
                if_pc_jump <= ~ex_stop;
            end
            else begin
                ex_stopcnt <= ex_stopcnt_dec; // dont stap
                if_pc_jump <= 1'b0;
            end
        end
        5'b00001, 5'b10001: begin
            // BGEZ(AL)
            if_forward_reg_write <= (~ex_stop) & jpc[20];
            if (~data_a[31]) begin // signed(A) >= 0
                ex_stopcnt <= ex_stop ? ex_stopcnt_dec : 3'b010; // clear backward
                if_pc_jump <= ~ex_stop;
            end
            else begin
                ex_stopcnt <= ex_stopcnt_dec; // dont stap
                if_pc_jump <= 1'b0;
            end
        end
        default: begin
            // exception
            ex_cause <= 5'd10;
            bubble_cnt <= 3'b000;
            ex_stopcnt <= 3'b010;
            if_forward_reg_write <= 1'b0;
            if_pc_jump <= 1'b1;
            exception <= 1'b1;
            pc_jumpto <= EX_ADDR_INIT;
        end
        endcase
    end
    
    6'b100011: begin
        // LW
        result <= sl_addr;
        bubble_cnt <= ex_stop ? bubble_cnt_dec : 3'b001; // IF/ID/EX stop
        ex_stopcnt <= ex_stop ? ex_stopcnt_dec : 3'b001; // R/W conflict
        if_pc_jump <= 1'b0;
        if_forward_reg_write <= 1'b0;
    end
    
    6'b100001, 6'b100101: begin
        // LH LHU
        load_byte <= {op[2], sl_addr[1], sl_addr[1], ~sl_addr[1], ~sl_addr[1]};
        result <= sl_addr;
        bubble_cnt <= ex_stop ? bubble_cnt_dec : 3'b001; // IF/ID/EX stop
        ex_stopcnt <= ex_stop ? ex_stopcnt_dec : 3'b001; // R/W conflict
        if_pc_jump <= 1'b0;
        if_forward_reg_write <= 1'b0;
    end
    
    6'b100000, 6'b100100: begin
        // LB LBU
        load_byte <= {op[2],
            sl_addr[1] & sl_addr[0], sl_addr[1] & ~sl_addr[0],
            ~sl_addr[1] & sl_addr[0], ~sl_addr[1] & ~sl_addr[0]};
        result <= sl_addr;
        bubble_cnt <= ex_stop ? bubble_cnt_dec : 3'b001; // IF/ID/EX stop
        ex_stopcnt <= ex_stop ? ex_stopcnt_dec : 3'b001; // R/W conflict
        if_pc_jump <= 1'b0;
        if_forward_reg_write <= 1'b0;
    end
    
    6'b101011: begin
        // SW
        result <= sl_addr;
        mem_data <= data_b; // write mem
        bubble_cnt <= ex_stop ? bubble_cnt_dec : 3'b001; // IF/ID/EX stop
        ex_stopcnt <= ex_stop ? ex_stopcnt_dec : 3'b001;
        if_pc_jump <= 1'b0;
        if_forward_reg_write <= 1'b0;
    end
    
    6'b101001: begin
        // SH
        load_byte <= {1'b0, sl_addr[1], sl_addr[1], ~sl_addr[1], ~sl_addr[1]};
        result <= sl_addr;
        mem_data <= data_b; // write mem
        bubble_cnt <= ex_stop ? bubble_cnt_dec : 3'b001; // IF/ID/EX stop
        ex_stopcnt <= ex_stop ? ex_stopcnt_dec : 3'b001;
        if_pc_jump <= 1'b0;
        if_forward_reg_write <= 1'b0;
    end
    
    6'b101000: begin
        // SB
        load_byte <= {1'b0,
            sl_addr[1] & sl_addr[0], sl_addr[1] & ~sl_addr[0],
            ~sl_addr[1] & sl_addr[0], ~sl_addr[1] & ~sl_addr[0]};
        result <= sl_addr;
        mem_data <= data_b; // write mem
        bubble_cnt <= ex_stop ? bubble_cnt_dec : 3'b001; // IF/ID/EX stop
        ex_stopcnt <= ex_stop ? ex_stopcnt_dec : 3'b001;
        if_pc_jump <= 1'b0;
        if_forward_reg_write <= 1'b0;
    end

    default: begin
        // exception 保留指令
        ex_cause <= 5'd10;
        bubble_cnt <= 3'b000;
        ex_stopcnt <= 3'b010;
        if_forward_reg_write <= 1'b0;
        if_pc_jump <= 1'b1;
        exception <= 1'b1;
        pc_jumpto <= EX_ADDR_INIT;
    end
    endcase
end

always@(posedge clk or negedge rst) begin
    if (!rst) begin
        hi <= 32'b0;
        lo <= 32'b0;
        cp0[0] <= 32'b0;
        cp0[1] <= 32'b0;
        cp0[2] <= 32'b0;
        cp0[3] <= 32'b0;
        cp0[4] <= 32'b0;
        cp0[5] <= 32'b0;
        cp0[6] <= 32'b0;
        cp0[7] <= 32'b0;
        cp0[8] <= 32'b0;
        cp0[9] <= 32'b0;
        cp0[10] <= 32'b0;
        cp0[11] <= 32'b0;
        cp0[12] <= 32'h0000FA01; // status
        cp0[13] <= 32'b0; // cause
        cp0[14] <= 32'b0; // epc
        cp0[15] <= 32'h80001000; // ebase
        cp0[16] <= 32'b0;
        cp0[17] <= 32'b0;
        cp0[18] <= 32'b0;
        cp0[19] <= 32'b0;
        cp0[20] <= 32'b0;
        cp0[21] <= 32'b0;
        cp0[22] <= 32'b0;
        cp0[23] <= 32'b0;
        cp0[24] <= 32'b0;
        cp0[25] <= 32'b0;
        cp0[26] <= 32'b0;
        cp0[27] <= 32'b0;
        cp0[28] <= 32'b0;
        cp0[29] <= 32'b0;
        cp0[30] <= 32'b0;
        cp0[31] <= 32'b0;
    end
    else begin
        if (if_dealing_ex) begin
            cp0[CAUSE][6:2] <= dealing_ex_cause; // cause: ExcCode
            cp0[CAUSE][31] <= after_last_ds; // cause:BD
            cp0[STATUS][1] <= 1; // status:EXL
            if (dealing_ex_cause == 5'd4 || dealing_ex_cause == 5'd5)
                cp0[BVA] <= bad_addr; // BVA
            cp0[EPC] <= npc - 32'd4; // EPC
            // TODO cause:IP4
        end
        else case (op)
        6'b000000:
            case (func)
            6'b010001: hi <= data_a;
            6'b010011: lo <= data_a;
            endcase
        6'b010000: begin
            if (jpc[25:21] == 5'b00100)
                cp0[jpc[15:11]] <= data_b;
            if (func == 6'b011000) // ERET
                cp0[STATUS][1] <= 0; // status:EXL
        end
        endcase
        
        last_ds <= delay_slot;
        after_last_ds <= last_ds;
    end
end

endmodule
