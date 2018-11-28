module MMU(
    // 输入
    input wire clk,
    
    input wire if_read, // 读使能，高有效 
    input wire if_write, // 写使能，高有效 
    input wire[31:0] addr, // MMU通用地址 
    input wire[31:0] input_data, // 写入数据
    input wire bytemode,
    // 保证不同时读写
    
    // 输出
    output reg[31:0] output_data, // 输出数据
    
    // top.v 接口 待扩充
    //BaseRAM信号
    inout wire[31:0] base_ram_data,  //BaseRAM数据，低8位与CPLD串口控制器共享
    output wire[19:0] base_ram_addr, //BaseRAM地址
    output wire[3:0] base_ram_be_n,  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire base_ram_ce_n,       //BaseRAM片选，低有效
    output wire base_ram_oe_n,       //BaseRAM读使能，低有效
    output wire base_ram_we_n,       //BaseRAM写使能，低有效

    //ExtRAM信号
    inout wire[31:0] ext_ram_data,  //ExtRAM数据
    output wire[19:0] ext_ram_addr, //ExtRAM地址
    output wire[3:0] ext_ram_be_n,  //ExtRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output wire ext_ram_ce_n,       //ExtRAM片选，低有效
    output wire ext_ram_oe_n,       //ExtRAM读使能，低有效
    output wire ext_ram_we_n,        //ExtRAM写使能，低有效
    
    output wire uart_rdn,         //读串口信号，低有效
    output wire uart_wrn,         //写串口信号，低有效
    input wire uart_dataready,    //串口数据准备好
    input wire uart_tbre,         //发送数据标志
    input wire uart_tsre          //数据发送完毕标志
    );

reg w_oe1 = 1'b1, w_we1 = 1'b1, w_ce1 = 1'b1, w_be1;
reg w_oe2 = 1'b1, w_we2 = 1'b1, w_ce2 = 1'b1, w_be2;
reg[19:0] ram_addr, ram_addr2;
reg[31:0] ram_data, ram_data2;
reg wrn=1'b1, rdn=1'b1;

assign base_ram_ce_n = w_ce1;
assign base_ram_oe_n = w_oe1;
assign base_ram_we_n = w_we1;
assign base_ram_addr = ram_addr;
assign base_ram_data = ram_data;
assign base_ram_be_n = w_be1;
assign ext_ram_ce_n = w_ce2;
assign ext_ram_oe_n = w_oe2;
assign ext_ram_we_n = w_we2;
assign ext_ram_addr = ram_addr2;
assign ext_ram_data = ram_data2;
assign ext_ram_be_n = w_be2;
assign uart_wrn     = wrn;
assign uart_rdn     = rdn;

always @(posedge clk or negedge clk) begin
    if (clk) begin
        // W/L here
        if (if_read) begin
            if (addr[29]) begin
                if (addr[2]) begin
                    output_data <= {30'b0, uart_dataready, uart_tbre};
                end
                else begin
                    rdn <= 1'b0;
                    ram_data <= 32'bz;
                    output_data <= {24'b0, ram_data[7:0]};
                end
            end
            else begin
                if (~addr[20]) begin
                    w_ce1 <= 1'b0;
                    w_ce2 <= 1'b1;
                    w_oe1 <= 1'b0;
                    w_we1 <= 1'b1;
                    ram_addr <= addr[19:0];
                    ram_data <= 32'bz;
                    if (bytemode) begin
                        w_be1 <= 4'b1110;
                        output_data <= {{24{ram_data[7]}}, ram_data[7:0]};
                    end
                    else begin
                        w_be1 <= 4'b0000;
                        output_data <= ram_data;
                    end
                end
                if (addr[20]) begin
                    w_ce1 <= 1'b1;
                    w_ce2 <= 1'b0;
                    w_oe2 <= 1'b0;
                    w_we2 <= 1'b1;
                    ram_addr2 <= addr[19:0];
                    ram_data2 <= 32'bz;
                    if (bytemode) begin
                        w_be2 <= 4'b1110;
                        output_data <= {{24{ram_data2[7]}}, ram_data2[7:0]};
                    end
                    else begin
                        w_be2 <= 4'b0000;
                        output_data <= ram_data2;
                    end
                end
            end
        end
        if (if_write) begin
            if (addr[29]) begin
                wrn <= 1'b0;
                ram_data <= input_data;
            end
            else begin
                if (~addr[20]) begin
                    w_ce1 <= 1'b0;
                    w_ce2 <= 1'b1;
                    w_oe1 <= 1'b1;
                    w_we1 <= 1'b0;
                    if (bytemode)
                        w_be1 <= 4'b1110;
                    else
                        w_be1 <= 4'b0000;
                    ram_addr <= addr[19:0];
                    ram_data <= input_data;
                end
                if (addr[20]) begin
                    w_ce1 <= 1'b1;
                    w_ce2 <= 1'b0;
                    w_oe2 <= 1'b1;
                    w_we2 <= 1'b0;
                    if (bytemode)
                        w_be2 <= 4'b1110;
                    else
                        w_be2 <= 4'b0000;
                    ram_addr2 <= addr[19:0];
                    ram_data2 <= input_data;
                end
            end
        end
    end
    else begin
        w_ce1 <= 1'b1;
        w_ce2 <= 1'b1;
        w_oe1 <= 1'b1;
        w_oe2 <= 1'b1;
        w_we1 <= 1'b1;
        w_we2 <= 1'b1;
        rdn <= 1'b1;
        wrn <= 1'b1;
    end
end

endmodule
