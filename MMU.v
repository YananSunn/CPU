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
    input wire uart_tsre
    );

reg oe1 = 1'b1, we1 = 1'b1, ce1 = 1'b1;
reg oe2 = 1'b1, we2 = 1'b1, ce2 = 1'b1;
reg[3:0] be1=4'b1, be2=4'b1;
reg[19:0] ram_addr, ram_addr2;
reg[31:0] ram_data, ram_data2;
reg wrn=1'b1, rdn=1'b1;

assign base_ram_addr = ram_addr;
assign base_ram_data = ram_data;
assign base_ram_ce_n = ce1;
assign base_ram_oe_n = oe1;
assign base_ram_we_n = we1;
assign base_ram_be_n = be1;
assign ext_ram_addr = ram_addr2;
assign ext_ram_data = ram_data2;
assign ext_ram_ce_n = ce2;
assign ext_ram_oe_n = oe2;
assign ext_ram_we_n = we2;
assign ext_ram_be_n = be2;
assign uart_wrn     = wrn;
assign uart_rdn     = rdn;

always @(posedge clk) begin
    if (if_read) begin
        ram_data <= 32'bz;
        ram_data2 <= 32'bz;
    end
    else if (if_write) begin
        if (addr[29]) begin
            ram_data <= {24'b0,input_data[7:0]};
        end
        else begin
            if (~addr[22]) begin
                if (bytemode) begin
                    ram_data={input_data[7:0],input_data[7:0],input_data[7:0],input_data[7:0]};
                end
                else begin
                    ram_data <= input_data;
                end
            end
            else begin
                if (bytemode) begin
                    ram_data2={input_data[7:0],input_data[7:0],input_data[7:0],input_data[7:0]};
                end
                else begin
                    ram_data2 <= input_data; 
                end
            end
        end
    end
end

always @(*) begin
    if (clk) begin
        if (if_read) begin
            if (addr[29]) begin
                if (addr[2]) begin
                    output_data <= {30'b0, uart_dataready, uart_tbre};
                    rdn <= 1'b1;
                end
                else begin
                    output_data <= {24'b0, ram_data[7:0]};
                    rdn <= 1'b0;
                end
            end
            else begin
                if (~addr[22]) begin
                    ce1 <= 1'b0;
                    ce2 <= 1'b1;
                    oe1 <= 1'b0;
                    we1 <= 1'b1;
                    if (bytemode) begin
                        case (addr[1:0])
                        2'b00: begin
                            output_data <= {{24{ram_data[31]}}, ram_data[31:24]};
                            be1 <= 4'b0111;
                        end
                        2'b01: begin
                            output_data <= {{24{ram_data[23]}}, ram_data[23:16]};
                            be1 <= 4'b1011;
                        end
                        2'b10: begin
                            output_data <= {{24{ram_data[15]}}, ram_data[15:8]};
                            be1 <= 4'b1101;
                        end
                        2'b11: begin
                            output_data <= {{24{ram_data[7]}}, ram_data[7:0]};
                            be1 <= 4'b1110;
                        end
                        default: begin
                            output_data <= ram_data;
                            be1 <= 4'b0000; 
                        end   
                        endcase
                    end
                    else begin
                        output_data <= ram_data;
                        be1 <= 4'b0000; 
                    end  
                end
                else begin
                    ce1 <= 1'b1;
                    ce2 <= 1'b0;
                    oe2 <= 1'b0;
                    we2 <= 1'b1;
                    if (bytemode) begin
                        case (addr[1:0])
                        2'b00: begin
                            output_data <= {{24{ram_data2[31]}}, ram_data2[31:24]};
                            be2 <= 4'b0111;
                        end
                        2'b01: begin
                            output_data <= {{24{ram_data2[23]}}, ram_data2[23:16]};
                            be2 <= 4'b1011;
                        end
                        2'b10: begin
                            output_data <= {{24{ram_data2[15]}}, ram_data2[15:8]};
                            be2 <= 4'b1101;
                        end
                        2'b11: begin
                            output_data <= {{24{ram_data2[7]}}, ram_data2[7:0]};
                            be2 <= 4'b1110;
                        end
                        default: begin
                            output_data <= ram_data;
                            be2 <= 4'b0000;  
                        end  
                        endcase
                    end
                    else begin
                        output_data <= ram_data;
                        be2 <= 4'b0000;  
                    end
                end
            end
        end
        else if (if_write) begin
            if (addr[29]) begin
                wrn <= 1'b0;
            end
            else begin
                if (~addr[22]) begin
                    ce1 <= 1'b0;
                    ce2 <= 1'b1;
                    oe1 <= 1'b0;
                    we1 <= 1'b1;
                    if (bytemode) begin
                        case (addr[1:0])
                        2'b00: be1 <= 4'b0111;
                        2'b01: be1 <= 4'b1011;
                        2'b10: be1 <= 4'b1101;
                        2'b11: be1 <= 4'b1110;
                        default: be1 <= 4'b0000;
                        endcase
                    end
                    else begin
                        be1 <= 4'b0000; 
                    end
                end
                else begin
                    ce1 <= 1'b1;
                    ce2 <= 1'b0;
                    oe2 <= 1'b0;
                    we2 <= 1'b1;
                    if (bytemode) begin
                        case (addr[1:0])
                        2'b00: be2 <= 4'b0111;
                        2'b01: be2 <= 4'b1011;
                        2'b10: be2 <= 4'b1101;
                        2'b11: be2 <= 4'b1110;
                        default: be2 <= 4'b0000;
                        endcase
                    end
                    else begin
                        be2 <= 4'b0000; 
                    end
                end
            end
        end
    end
    else begin
        ce1 <= 1'b1;
        ce2 <= 1'b1;
        oe1 <= 1'b1;
        oe2 <= 1'b1;
        we1 <= 1'b1;
        we2 <= 1'b1;
        rdn <= 1'b1;
        wrn <= 1'b1;
    end
end

endmodule
