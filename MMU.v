module MMU(
    // ����
    input wire clk,
    
    input wire if_read, // ��ʹ�ܣ�����Ч 
    input wire if_write, // дʹ�ܣ�����Ч 
    input wire[31:0] addr, // MMUͨ�õ�ַ 
    input wire[31:0] input_data, // д������ 
    input wire bytemode,
    // ��֤��ͬʱ��д
    
    // ���
    output reg[31:0] output_data, // �������
    
    // top.v �ӿ� ������
    //BaseRAM�ź�
    inout wire[31:0] base_ram_data,  //BaseRAM���ݣ���8λ��CPLD���ڿ���������
    output wire[19:0] base_ram_addr, //BaseRAM��ַ
    output wire[3:0] base_ram_be_n,  //BaseRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
    output wire base_ram_ce_n,       //BaseRAMƬѡ������Ч
    output wire base_ram_oe_n,       //BaseRAM��ʹ�ܣ�����Ч
    output wire base_ram_we_n,       //BaseRAMдʹ�ܣ�����Ч

    //ExtRAM�ź�
    inout wire[31:0] ext_ram_data,  //ExtRAM����
    output wire[19:0] ext_ram_addr, //ExtRAM��ַ
    output wire[3:0] ext_ram_be_n,  //ExtRAM�ֽ�ʹ�ܣ�����Ч�������ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
    output wire ext_ram_ce_n,       //ExtRAMƬѡ������Ч
    output wire ext_ram_oe_n,       //ExtRAM��ʹ�ܣ�����Ч
    output wire ext_ram_we_n,        //ExtRAMдʹ�ܣ�����Ч
    
    output wire uart_rdn,         //�������źţ�����Ч
    output wire uart_wrn,         //д�����źţ�����Ч
    input wire uart_dataready,    //��������׼����
    input wire uart_tbre,         //�������ݱ�־
    input wire uart_tsre          //���ݷ�����ϱ�־
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

always @(*) begin
    // W/L here
    if (if_read) begin
        case (addr)
        32'd000:output_data <= 32'b00001000000000000000000000000011;
        32'd004:output_data <= 32'b00100100000000010000000000001111;
        32'd008:output_data <= 32'b00110000001000100000000000001100;
        32'd012:output_data <= 32'b00100100000000110000000000010111;
        32'd016:output_data <= 32'b00011100011000001111111111111101;
        
        default: output_data <= 32'b00000000000000000000000000000000;
        endcase
    end
    if (if_write) begin
    end
end

endmodule