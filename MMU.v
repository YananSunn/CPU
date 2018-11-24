module MMU(
    // 输入
    input wire if_read, // 读使能，高有效 
    input wire if_write, // 写使能，高有效 
    input wire[31:0] addr, // MMU通用地址 
    input wire[31:0] input_data, // 写入数据
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
    output wire ext_ram_we_n        //ExtRAM写使能，低有效
    
    // ...
    );

always @(*) begin
    // W/L here
    if (if_read) begin
        case (addr)
        // calc fib
        32'd000: output_data <= 32'b00100100000000010000000000000001;
        32'd004: output_data <= 32'b00100100000000100000000000000001;
        32'd008: output_data <= 32'b00100100000001000000000000000101;
        32'd012: output_data <= 32'b00000000001000100000100000100001;
        32'd016: output_data <= 32'b00000000001000100001000000100001;
        32'd020: output_data <= 32'b00100100100001001111111111111111;
        32'd024: output_data <= 32'b00010100100000001111111111111100;
        32'd028: output_data <= 32'b00000000001000010000100000100001;
        32'd032: output_data <= 32'b00000000001000010000100000100001;
        32'd036: output_data <= 32'b00000000001000010000100000100001;
        default: output_data <= 32'b00000000000000000000000000000000;
        endcase
    end
    if (if_write) begin
    end
end
    
endmodule
