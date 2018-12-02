module ID(
    input wire clk,
    input wire rst,

    input wire[31:0] ins,
    
    input wire reg_write,
    input wire[4:0] write_reg,
    input wire[31:0] write_data,
    
    output reg if_reg_write,
    output reg if_mem_read,
    output reg if_mem_write,
    output reg[5:0] op,
    output reg[5:0] func,
    
    output reg[31:0] data_a,
    output reg[31:0] data_b,
    output reg[4:0] data_write_reg,
    output reg[31:0] imm,
    output reg[25:0] jpc,
    
    // pass
    input wire[31:0] npc_i,
    output reg[31:0] npc_o
    );

reg[31:0] registers[0:31];

// ID
always@(*) begin
    npc_o <= npc_i;
    
    op <= ins[31:26];
    func <= ins[5:0];
    jpc <= ins[25:0];
    
    data_a <= (reg_write && (write_reg == ins[25:21])) ? write_data : registers[ins[25:21]];
    data_b <= (reg_write && (write_reg == ins[20:16])) ? write_data : registers[ins[20:16]];
    
    // 符号扩展
    imm <= ins[15] ? {16'hffff, ins[15:0]} : {16'h0000, ins[15:0]};
    
    case (ins[31:26])
        // list all operations        
        // R型
        6'b000000: begin
        // SPECAL (ADD, SUB, ..., JR)
            if_reg_write <= 1'b0; // 在旁路单元中写回
            if_mem_read <= 1'b0;
            if_mem_write <= 1'b0;
            data_write_reg <= ins[15:11];
        end
        
        // I型
        6'b001000: begin
        // ADDI
            if_reg_write <= 1'b0; // 在旁路单元中写回
            if_mem_read <= 1'b0;
            if_mem_write <= 1'b0;
            data_write_reg <= ins[20:16];
        end
        6'b001001: begin
        // ADDIU
            if_reg_write <= 1'b0; // 在旁路单元中写回
            if_mem_read <= 1'b0;
            if_mem_write <= 1'b0;
            data_write_reg <= ins[20:16];
        end
        6'b001100: begin
        // ANDI
            if_reg_write <= 1'b0; // 在旁路单元中写回
            if_mem_read <= 1'b0;
            if_mem_write <= 1'b0;
            data_write_reg <= ins[20:16];
        end
        6'b001101: begin
        // ORI
            if_reg_write <= 1'b0; // 在旁路单元中写回
            if_mem_read <= 1'b0;
            if_mem_write <= 1'b0;
            data_write_reg <= ins[20:16];
        end
        6'b001110: begin
        // XORI
            if_reg_write <= 1'b0; // 在旁路单元中写回
            if_mem_read <= 1'b0;
            if_mem_write <= 1'b0;
            data_write_reg <= ins[20:16];
        end
        6'b001111: begin
        // LUI
            if_reg_write <= 1'b0; // 在旁路单元中写回
            if_mem_read <= 1'b0;
            if_mem_write <= 1'b0;
            data_write_reg <= ins[20:16];
        end
        6'b000100: begin
        // BEQ
            if_reg_write <= 1'b0;
            if_mem_read <= 1'b0;
            if_mem_write <= 1'b0;
        end
        6'b000101: begin
        // BNE
            if_reg_write <= 1'b0;
            if_mem_read <= 1'b0;
            if_mem_write <= 1'b0;
        end
        6'b000111: begin
        // BGTZ
            if_reg_write <= 1'b0;
            if_mem_read <= 1'b0;
            if_mem_write <= 1'b0;
        end
        6'b100011: begin
        // LW
            if_reg_write <= 1'b1;
            if_mem_read <= 1'b1;
            if_mem_write <= 1'b0;
            data_write_reg <= ins[20:16];
        end
        6'b100000: begin
        // LB
            if_reg_write <= 1'b1;
            if_mem_read <= 1'b1;
            if_mem_write <= 1'b0;
            data_write_reg <= ins[20:16];
        end
        6'b101011: begin
        // SW
            if_reg_write <= 1'b0;
            if_mem_read <= 1'b0;
            if_mem_write <= 1'b1;
        end
        6'b101000: begin
        // SB
            if_reg_write <= 1'b0;
            if_mem_read <= 1'b0;
            if_mem_write <= 1'b1;
        end
        
        // J型
        6'b000010: begin
        // J
            if_reg_write <= 1'b0;
            if_mem_read <= 1'b0;
            if_mem_write <= 1'b0;
        end
        6'b000011: begin
        // JAL
            if_reg_write <= 1'b0; // 在旁路单元中写回
            if_mem_read <= 1'b0;
            if_mem_write <= 1'b0;
            data_write_reg <= 5'b11111;
        end
        
        default: begin
        // unknown/init
            if_reg_write <= 1'b0;
            if_mem_read <= 1'b0;
            if_mem_write <= 1'b0;
        end
    endcase
end

// reg Write
always@(posedge clk or negedge rst) begin
    if (!rst) begin
        registers[0] <= 32'b0;
        registers[1] <= 32'b0;
        registers[2] <= 32'b0;
        registers[3] <= 32'b0;
        registers[4] <= 32'b0;
        registers[5] <= 32'b0;
        registers[6] <= 32'b0;
        registers[7] <= 32'b0;
        registers[8] <= 32'b0;
        registers[9] <= 32'b0;
        registers[10] <= 32'b0;
        registers[11] <= 32'b0;
        registers[12] <= 32'b0;
        registers[13] <= 32'b0;
        registers[14] <= 32'b0;
        registers[15] <= 32'b0;
        registers[16] <= 32'b0;
        registers[17] <= 32'b0;
        registers[18] <= 32'b0;
        registers[19] <= 32'b0;
        registers[20] <= 32'b0;
        registers[21] <= 32'b0;
        registers[22] <= 32'b0;
        registers[23] <= 32'b0;
        registers[24] <= 32'b0;
        registers[25] <= 32'b0;
        registers[26] <= 32'b0;
        registers[27] <= 32'b0;
        registers[28] <= 32'b0;
        registers[29] <= 32'b0;
        registers[30] <= 32'b0;
        registers[31] <= 32'b0;
    end
    else if (reg_write && (write_reg != 0)) begin
        registers[write_reg] <= write_data;
        registers[0] <= 32'b0;
    end
    else registers[0] <= 32'b0;
end

endmodule
