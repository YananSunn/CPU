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
    output reg[31:0] im_addr = 32'hFFFFFFFF,
    
    output reg[31:0] npc = 32'd0,
    output wire[31:0] ins
    );

// ∂¡»°÷∏¡Ó
assign ins = im_data;

always @(posedge clk) begin
    if (!if_bubble) begin
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
