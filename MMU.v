module MMU(
    input wire clk,
    
    input wire if_read,
    input wire if_write,
    input wire[31:0] addr,
    input wire[31:0] input_data,
    input wire[4:0] bytemode,
    output reg[31:0] output_data = 32'h00000000,
    
    inout wire[31:0] base_ram_data,
    output wire[19:0] base_ram_addr,
    output wire[3:0] base_ram_be_n,
    output wire base_ram_ce_n,
    output wire base_ram_oe_n,
    output wire base_ram_we_n,

    inout wire[31:0] ext_ram_data,
    output wire[19:0] ext_ram_addr,
    output wire[3:0] ext_ram_be_n,
    output wire ext_ram_ce_n,
    output wire ext_ram_oe_n,
    output wire ext_ram_we_n,
    
    output wire uart_rdn,
    output wire uart_wrn,
    input wire uart_dataready,
    input wire uart_tbre,
    input wire uart_tsre,
    
    output wire[15:0] debug_leds,
    output wire[7:0] debug_dpys
    );
    
reg oe1 = 1'b1, we1 = 1'b1, ce1 = 1'b1;
reg oe2 = 1'b1, we2 = 1'b1, ce2 = 1'b1;
wire[3:0] be = ~bytemode[3:0];
reg[31:0] ram_write_data = 32'h00000000;
reg wrn = 1'b1, rdn = 1'b1;

assign base_ram_addr = addr[21:2];
assign ext_ram_addr  = addr[21:2];

assign base_ram_data = if_write ? ram_write_data : 32'bz;
assign ext_ram_data  = if_write ? ram_write_data : 32'bz;

assign base_ram_ce_n = ce1;
assign base_ram_oe_n = oe1;
assign base_ram_we_n = we1;
assign base_ram_be_n = be;

assign ext_ram_ce_n = ce2;
assign ext_ram_oe_n = oe2;
assign ext_ram_we_n = we2;
assign ext_ram_be_n = be;

assign uart_wrn     = wrn;
assign uart_rdn     = rdn;

reg[15:0] leds = 16'h0000;
reg[7:0] dpys = 8'h00;
assign debug_leds   = leds;
assign debug_dpys   = dpys;

wire[31:0] ram_read_data = addr[22] ? ext_ram_data : base_ram_data;

always @(*) begin

    if (!clk) begin
        oe1 <= 1'b1;
        oe2 <= 1'b1;
        we1 <= 1'b1;
        we2 <= 1'b1;
        
        case (addr)
            32'hBFD00400, 32'hBFD00408: begin
                // LED & DPY
                ce1 <= 1'b1;
                ce2 <= 1'b1;
                rdn <= 1'b1;
                wrn <= 1'b1;
                output_data <= 32'h00000000;
                ram_write_data <= 32'h00000000;
            end
            32'hBFD003F8: begin
                ce1 <= 1'b1;
                ce2 <= 1'b1;
                if (if_read) begin
                    rdn <= 1'b0;
                    wrn <= 1'b1;
                    output_data <= {24'b0, base_ram_data[7:0]};
                    ram_write_data <= 32'h00000000;
                end
                else if (if_write) begin
                    rdn <= 1'b1;
                    wrn <= 1'b0;
                    output_data <= 32'h00000000;
                    ram_write_data <= input_data;
                end
                else begin
                    rdn <= 1'b1;
                    wrn <= 1'b1;
                    output_data <= 32'h00000000;
                    ram_write_data <= 32'h00000000;
                end
            end
            32'hBFD003FC: begin
                ce1 <= 1'b1;
                ce2 <= 1'b1;
                if (if_read) begin
                    rdn <= 1'b1;
                    wrn <= 1'b1;
                    output_data <= {30'b0, uart_dataready, uart_tsre};
                    ram_write_data <= 32'h00000000;
                end
                else begin
                    rdn <= 1'b1;
                    wrn <= 1'b1;
                    output_data <= 32'h00000000;
                    ram_write_data <= 32'h00000000;
                end
            end
            default: begin
                ram_write_data <= 32'h00000000;
                // RAM
                ce1 <= addr[22];
                ce2 <= ~addr[22];
                oe1 <= addr[22] | (~if_read);
                oe2 <= (~addr[22]) | (~if_read);
                we1 <= addr[22] | (~if_write);
                we2 <= (~addr[22]) | (~if_write);
                rdn <= 1'b1;
                wrn <= 1'b1;
                if (if_read) begin
                    case (bytemode)
                        5'b01000: output_data <= {{24{ram_read_data[31]}}, ram_read_data[31:24]};
                        5'b11000: output_data <= {24'h000000, ram_read_data[31:24]};
                        5'b00100: output_data <= {{24{ram_read_data[23]}}, ram_read_data[23:16]};
                        5'b10100: output_data <= {24'h000000, ram_read_data[23:16]};
                        5'b00010: output_data <= {{24{ram_read_data[15]}}, ram_read_data[15:8]};
                        5'b10010: output_data <= {24'h000000, ram_read_data[15:8]};
                        5'b00001: output_data <= {{24{ram_read_data[7]}}, ram_read_data[7:0]};
                        5'b10001: output_data <= {24'h000000, ram_read_data[7:0]};
                        
                        5'b01100: output_data <= {{16{ram_read_data[31]}}, ram_read_data[31:16]};
                        5'b11100: output_data <= {16'h0000, ram_read_data[31:16]};
                        5'b00011: output_data <= {{16{ram_read_data[15]}}, ram_read_data[15:0]};
                        5'b10011: output_data <= {16'h0000, ram_read_data[15:0]};

                        default: output_data <= ram_read_data;
                    endcase
                end
                else if (if_write) begin
                    output_data <= 32'h00000000;
                    case (bytemode[3:0])
                        4'b1000: ram_write_data <= {input_data[7:0], 24'h000000};
                        4'b0100: ram_write_data <= {8'h00, input_data[7:0], 16'h0000};
                        4'b0010: ram_write_data <= {16'h0000, input_data[7:0], 8'h00};
                        4'b0001: ram_write_data <= {24'h000000, input_data[7:0]};
                        
                        4'b1100: ram_write_data <= {input_data[15:0], 16'h0000};
                        4'b0011: ram_write_data <= {16'h0000, input_data[15:0]};
                        
                        default: ram_write_data <= input_data;
                    endcase
                end
                else begin
                    output_data <= 32'h00000000;
                    ram_write_data <= 32'h00000000;
                end
            end
        endcase
    end
    else begin
        // ram
        ce1 <= 1'b1;
        ce2 <= 1'b1;
        oe1 <= 1'b1;
        oe2 <= 1'b1;
        we1 <= 1'b1;
        we2 <= 1'b1;
        rdn <= 1'b1;
        wrn <= 1'b1;
        output_data <= 32'h00000000;
        ram_write_data <= 32'h00000000;
    end
end

always@ (posedge clk) begin
    if (if_write) begin
        case (addr)
            32'hBFD00400: leds <= input_data[15:0];
            32'hBFD00408: dpys <= input_data[7:0];
        endcase
    end
end

endmodule
