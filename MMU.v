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
    output wire[7:0] debug_dpys,
    
    // 键盘(伪)
    input wire key_down,
    input wire[7:0] spec_key,
    output reg key_get,
    
    //图像输出信号
    output wire[2:0] video_red,    //红色像素，3位
    output wire[2:0] video_green,  //绿色像素，3位
    output wire[1:0] video_blue,   //蓝色像素，2位
    output wire video_hsync,       //行同步（水平同步）信号
    output wire video_vsync,       //场同步（垂直同步）信号
    output wire video_clk,         //像素时钟输出
    output wire video_de           //行数据有效信号，用于区分消隐区
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
    key_get <= 0;
    
    if (!clk) begin
        oe1 <= 1'b1;
        oe2 <= 1'b1;
        we1 <= 1'b1;
        we2 <= 1'b1;
        if (addr[31:16] == 16'hBFD0) begin
            ce1 <= 1'b1;
            ce2 <= 1'b1;
            rdn <= 1'b1;
            wrn <= 1'b1;
            output_data <= 32'h00000000;
            ram_write_data <= 32'h00000000;
            case (addr[15:0])
            16'h0400, 16'h0408: begin
                // LED & DPY % vga
            end
            16'h03F8: begin
                if (if_read) begin
                    rdn <= 1'b0;
                    wrn <= 1'b1;
                    output_data <= {24'b0, base_ram_data[7:0]};
                end
                else if (if_write) begin
                    rdn <= 1'b1;
                    wrn <= 1'b0;
                    ram_write_data <= input_data;
                end
            end
            16'h03FC: begin
                rdn <= 1'b1;
                wrn <= 1'b1;
                if (if_read) begin
                    output_data <= {30'b0, uart_dataready, uart_tbre & uart_tsre};
                end
            end
            endcase
        end
        else begin
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

reg [63:0] chr_signal_input1;
reg [63:0] chr_signal_input2;

always@(posedge clk) begin
    if (if_write) begin
        case (addr)
            32'hBFD00400: leds <= input_data[15:0];
            32'hBFD00408: dpys <= input_data[7:0];
            
            32'hBFD02000: begin
                chr_signal_input1[63:56] <= input_data[7:0];
            end
            32'hBFD02001: begin
                chr_signal_input1[55:48] <= input_data[7:0];
            end
            32'hBFD02002: begin
                chr_signal_input1[47:40] <= input_data[7:0];
            end
            32'hBFD02003: begin
                chr_signal_input1[39:32] <= input_data[7:0];
            end
            32'hBFD02004: begin
                chr_signal_input1[31:24] <= input_data[7:0];
            end
            32'hBFD02005: begin
                chr_signal_input1[23:16] <= input_data[7:0];
            end
            32'hBFD02006: begin
                chr_signal_input1[15:8] <= input_data[7:0];
            end
            32'hBFD02007: begin
                chr_signal_input1[7:0] <= input_data[7:0];
            end
            32'hBFD02010: begin
                chr_signal_input2[63:56] <= input_data[7:0];
            end
            32'hBFD02011: begin
                chr_signal_input2[55:48] <= input_data[7:0];
            end
            32'hBFD02012: begin
                chr_signal_input2[47:40] <= input_data[7:0];
            end
            32'hBFD02013: begin
                chr_signal_input2[39:32] <= input_data[7:0];
            end
            32'hBFD02014: begin
                chr_signal_input2[31:24] <= input_data[7:0];
            end
            32'hBFD02015: begin
                chr_signal_input2[23:16] <= input_data[7:0];
            end
            32'hBFD02016: begin
                chr_signal_input2[15:8] <= input_data[7:0];
            end
            32'hBFD02017: begin
                chr_signal_input2[7:0] <= input_data[7:0];
            end
        endcase
    end
end

vga #(12, 800, 856, 976, 1040, 600, 637, 643, 666, 1, 1) vga800x600at75 (
    .clk(clk),
    .enable(1'b1),
    .signal_input({chr_signal_input1, chr_signal_input2}),
    .video_red(video_red),
    .video_green(video_green),
    .video_blue(video_blue),
    .video_hsync(video_hsync),
    .video_vsync(video_vsync),
    .video_clk(video_clk),
    .video_de(video_de),
    
    .reset(1'b0)
);

endmodule
