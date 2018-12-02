`define pc im_addr

module IF(
    input wire clk,
    input wire rst,
    
    input wire[31:0] jpc,
    input wire if_pc_jump,
    
    input wire if_bubble,
    // for exception
    // jpc = npc - 4
    
    input wire[31:0] im_data,
    output reg[31:0] im_addr,
    
    output reg[31:0] npc = 32'h80000000, // pc_inital
    output reg[31:0] ins
    );

// ��ȡָ��
always @(*) begin
    ins <= im_data;
end

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        npc <= 32'h80000000;
        `pc <= 32'h7FFFFFFC;
    end
    else if (!if_bubble) begin
        if (if_pc_jump) begin
            `pc <= jpc;
            npc <= jpc + 32'd4;
        end
        else begin
            `pc <= npc;
            npc <= npc + 32'd4;
        end
    end
end

endmodule
