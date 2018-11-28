module MMU(
    input wire clk,
    // ����
    input wire if_read, // ��ʹ�ܣ�����Ч 
    input wire if_write, // дʹ�ܣ�����Ч 
    input wire[31:0] addr, // MMUͨ�õ�ַ 
    input wire[31:0] input_data, // д������
    input wire bytemode,
    // ��֤��ͬʱ��д
    
    // ���?
    output reg[31:0] output_data, // �������?
    
    // top.v �ӿ� ������
    //BaseRAM�ź�
    inout wire[31:0] base_ram_data,  //BaseRAM���ݣ���8λ��CPLD���ڿ���������
    output wire[19:0] base_ram_addr, //BaseRAM��ַ
    output wire[3:0] base_ram_be_n,  //BaseRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣���?0
    output wire base_ram_ce_n,       //BaseRAMƬѡ������Ч
    output wire base_ram_oe_n,       //BaseRAM��ʹ�ܣ�����Ч
    output wire base_ram_we_n,       //BaseRAMдʹ�ܣ�����Ч

    //ExtRAM�ź�
    inout wire[31:0] ext_ram_data,  //ExtRAM����
    output wire[19:0] ext_ram_addr, //ExtRAM��ַ
    output wire[3:0] ext_ram_be_n,  //ExtRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣���?0
    output wire ext_ram_ce_n,       //ExtRAMƬѡ������Ч
    output wire ext_ram_oe_n,       //ExtRAM��ʹ�ܣ�����Ч
    output wire ext_ram_we_n        //ExtRAMдʹ�ܣ�����Ч
    
    // ...
    );

reg w_oe1, w_we1, w_ce1, w_be1;
reg w_oe2, w_we2, w_ce2, w_be2;
reg[19:0] ram_addr, ram_addr2;
reg[31:0] ram_data, ram_data2;

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

always @(clk) begin
    // W/L here
    if (if_read) begin
        // for ID simulation
        // output_data <= 32'b00100000000000010000000000000001; // ADDI $0 $1 1 --> $1=$0+1
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
    if (if_write) begin
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
    
endmodule
