module MMU(
    input wire clk,
    
    input wire if_read,
    input wire if_write,
    input wire[31:0] addr,
    input wire[31:0] input_data,
    input wire bytemode,
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
reg[3:0] be = 4'b0000;
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
                be <= 1'h0;
                output_data <= 32'h00000000;
                ram_write_data <= 32'h00000000;
            end
            32'hBFD003F8: begin
                ce1 <= 1'b1;
                ce2 <= 1'b1;
                be <= 1'h0;
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
                be <= 1'h0;
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
                    if (bytemode) begin
                        case (addr[1:0])
                            2'b11: begin
                                output_data <= {{24{ram_read_data[31]}}, ram_read_data[31:24]};
                                be <= 4'b0111;
                            end
                            2'b10: begin
                                output_data <= {{24{ram_read_data[23]}}, ram_read_data[23:16]};
                                be <= 4'b1011;
                            end
                            2'b01: begin
                                output_data <= {{24{ram_read_data[15]}}, ram_read_data[15:8]};
                                be <= 4'b1101;
                            end
                            2'b00: begin
                                output_data <= {{24{ram_read_data[7]}}, ram_read_data[7:0]};
                                be <= 4'b1110;
                            end
                            default: begin
                                output_data <= ram_read_data;
                                be <= 4'b0000;
                            end
                        endcase
                    end
                    else begin
                        output_data <= ram_read_data;
                        be <= 4'b0000;
                    end
                end
                else if (if_write) begin
                    output_data <= 32'h00000000;
                    if (bytemode) begin
                        case (addr[1:0])
                            2'b11: begin
                                ram_write_data <= {input_data[7:0], 24'b0};
                                be <= 4'b0111;
                            end
                            2'b10: begin
                                ram_write_data <= {8'b0, input_data[7:0], 16'b0};
                                be <= 4'b1011;
                            end
                            2'b01: begin
                                ram_write_data <= {16'b0, input_data[7:0], 8'b0};
                                be <= 4'b1101;
                            end
                            2'b00: begin
                                ram_write_data <= {24'b0, input_data[7:0]};
                                be <= 4'b1110;
                            end
                            default: begin
                                ram_write_data <= input_data;
                                be <= 4'b0000;
                            end
                        endcase
                    end
                    else begin
                        ram_write_data <= input_data;
                        be <= 4'b0000; 
                    end
                end
                else begin
                    output_data <= 32'h00000000;
                    ram_write_data <= 32'h00000000;
                    be <= 4'b0000;
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
        be <= 4'b0000;
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
