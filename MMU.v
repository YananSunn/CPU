module MMU(
    input wire clk,
    
    input wire if_read,
    input wire if_write,
    input wire[31:0] addr,
    input wire[31:0] input_data,
    input wire bytemode,
    output reg[31:0] output_data,
    
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
reg[31:0] ram_read_data1, ram_read_data2, ram_write_data;
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

reg[15:0] leds = 16'b0;
reg[7:0] dpys = 8'b0;
assign debug_leds   = leds;
assign debug_dpys   = dpys;

wire[31:0] ram_read_data = addr[22] ? ext_ram_data : base_ram_data;

always @(*) begin
    if (!clk) begin
        case (addr)
            32'hBFD00400, 32'hBFD00408: begin
                // LED & DPY
                ce1 <= 1'b1;
                ce2 <= 1'b1;
                rdn <= 1'b1;
                wrn <= 1'b1;
                output_data <= 32'b0;
                ram_write_data <= 32'b0;
            end
            32'hBFD003F8: begin
                ce1 <= 1'b1;
                ce2 <= 1'b1;
                if (if_read) begin
                    rdn <= 1'b0;
                    wrn <= 1'b1;
                    output_data <= {24'b0, base_ram_data[7:0]};
                    ram_write_data <= 32'b0;
                end
                else if (if_write) begin
                    rdn <= 1'b1;
                    wrn <= 1'b0;
                    output_data <= 32'b0;
                    ram_write_data <= input_data;
                end
                else begin
                    rdn <= 1'b1;
                    wrn <= 1'b1;
                    output_data <= 32'b0;
                    ram_write_data <= 32'b0;
                end
            end
            32'hBFD003FC: begin
                ce1 <= 1'b1;
                ce2 <= 1'b1;
                if (if_read) begin
                    rdn <= 1'b0;
                    wrn <= 1'b1;
                    output_data <= {30'b0, uart_dataready, uart_tsre};
                    ram_write_data <= 32'b0;
                end
                else begin
                    rdn <= 1'b1;
                    wrn <= 1'b1;
                    output_data <= 32'b0;
                    ram_write_data <= 32'b0;
                end
            end
            default: begin
                ram_write_data <= 32'b0;
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
                            2'b00: begin
                                output_data <= {{24{ram_read_data[31]}}, ram_read_data[31:24]};
                                be <= 4'b0111;
                            end
                            2'b01: begin
                                output_data <= {{24{ram_read_data[23]}}, ram_read_data[23:16]};
                                be <= 4'b1011;
                            end
                            2'b10: begin
                                output_data <= {{24{ram_read_data[15]}}, ram_read_data[15:8]};
                                be <= 4'b1101;
                            end
                            2'b11: begin
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
                        case (addr)
                        32'h80000000: output_data <= 32'h3c068000;
                        32'h80000004: output_data <= 32'h24c63000;
                        32'h80000008: output_data <= 32'h40867801;
                        32'h8000000C: output_data <= 32'h40806000;
                        32'h80000010: output_data <= 32'h40806800;
                        32'h80000014: output_data <= 32'h34070000;
                        32'h80000018: output_data <= 32'h00e00013;
                        32'h8000001C: output_data <= 32'h34180000;
                        32'h80000020: output_data <= 32'h03000011;
                        32'h80000024: output_data <= 32'h0800000b;
                        32'h80000028: output_data <= 32'h00000000;
                        32'h8000002C: output_data <= 32'h3409ffff;
                        32'h80000030: output_data <= 32'h3c17bfd0;
                        32'h80000034: output_data <= 32'h36f70400;
                        32'h80000038: output_data <= 32'haee90000;
                        32'h8000003C: output_data <= 32'h3c11bfd0;
                        32'h80000040: output_data <= 32'h36310408;
                        32'h80000044: output_data <= 32'h3c130000;
                        32'h80000048: output_data <= 32'hae330000;
                        32'h8000004C: output_data <= 32'h0c000028;
                        32'h80000050: output_data <= 32'h00000000;
                        32'h80000054: output_data <= 32'h0c000021;
                        32'h80000058: output_data <= 32'h00000000;
                        32'h8000005C: output_data <= 32'h2404005d;
                        32'h80000060: output_data <= 32'h10930003;
                        32'h80000064: output_data <= 32'h00000000;
                        32'h80000068: output_data <= 32'h10000004;
                        32'h8000006C: output_data <= 32'h00000000;
                        32'h80000070: output_data <= 32'h3c08bfd0;
                        32'h80000074: output_data <= 32'h35080400;
                        32'h80000078: output_data <= 32'had000000;
                        32'h8000007C: output_data <= 32'h1000ffff;
                        32'h80000080: output_data <= 32'h00000000;
                        32'h80000084: output_data <= 32'h24080005;
                        32'h80000088: output_data <= 32'h2508ffff;
                        32'h8000008C: output_data <= 32'h1500fffe;
                        32'h80000090: output_data <= 32'h00000000;
                        32'h80000094: output_data <= 32'h03e00008;
                        32'h80000098: output_data <= 32'h00000000;
                        32'h8000009C: output_data <= 32'h00000000;
                        32'h800000A0: output_data <= 32'h24040003;
                        32'h800000A4: output_data <= 32'h24020000;
                        32'h800000A8: output_data <= 32'h3c081ade;
                        32'h800000AC: output_data <= 32'h3508f300;
                        32'h800000B0: output_data <= 32'h3c0951dd;
                        32'h800000B4: output_data <= 32'h352958de;
                        32'h800000B8: output_data <= 32'h01098021;
                        32'h800000BC: output_data <= 32'h3c126cbc;
                        32'h800000C0: output_data <= 32'h36524bde;
                        32'h800000C4: output_data <= 32'h16120a29;
                        32'h800000C8: output_data <= 32'h00000000;
                        32'h800000CC: output_data <= 32'h3c089674;
                        32'h8000296C: output_data <= 32'haef30000;
                        32'h80002970: output_data <= 32'hae240000;
                        32'h80002974: output_data <= 32'h03e00008;
                        32'h80002978: output_data <= 32'h00000000;
                        32'h8000297C: output_data <= 32'h00000000;
                        default:
                        
                        output_data <= ram_read_data;
                        
                        endcase
                        
                        be <= 4'b0000;
                    end
                end
                else if (if_write) begin
                    output_data <= 32'b0;
                    if (bytemode) begin
                        case (addr[1:0])
                            2'b00: begin
                                ram_write_data <= {input_data[7:0], 24'b0};
                                be <= 4'b0111;
                            end
                            2'b01: begin
                                ram_write_data <= {8'b0, input_data[7:0], 16'b0};
                                be <= 4'b1011;
                            end
                            2'b10: begin
                                ram_write_data <= {16'b0, input_data[7:0], 8'b0};
                                be <= 4'b1101;
                            end
                            2'b11: begin
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
                    output_data <= 32'b0;
                    ram_write_data <= 32'b0;
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
        output_data <= 32'b0;
        ram_write_data <= 32'b0;
    end
end

always@ (posedge clk) begin
    if (if_write) begin
        case (addr)
        32'hBFD00400: leds = input_data[15:0];
        32'hBFD00408: dpys = input_data[7:0];
        endcase
    end
end

endmodule
