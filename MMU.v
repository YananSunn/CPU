module MMU(
    // ����
    input wire if_read, // ��ʹ�ܣ�����Ч 
    input wire if_write, // дʹ�ܣ�����Ч 
    input wire[31:0] addr, // MMUͨ�õ�ַ 
    input wire[31:0] input_data, // д������
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
    output wire ext_ram_we_n        //ExtRAMдʹ�ܣ�����Ч
    
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
