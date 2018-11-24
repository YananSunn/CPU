`default_nettype none
module thinpad_top(
    input wire clk_50M,           //50MHz ʱ������
    input wire clk_11M0592,       //11.0592MHz ʱ������

    input wire clock_btn,         //BTN5�ֶ�ʱ�Ӱ�ť���أ���������·������ʱΪ1
    input wire reset_btn,         //BTN6�ֶ���λ��ť���أ���������·������ʱΪ1

    input  wire[3:0]  touch_btn,  //BTN1~BTN4����ť���أ�����ʱΪ1
    input  wire[31:0] dip_sw,     //32λ���뿪�أ�����"ON"ʱΪ1
    output wire[15:0] leds,       //16λLED�����ʱ1����
    output wire[7:0]  dpy0,       //����ܵ�λ�źţ�����С���㣬���1����
    output wire[7:0]  dpy1,       //����ܸ�λ�źţ�����С���㣬���1����

    //CPLD���ڿ������ź�
    output wire uart_rdn,         //�������źţ�����Ч
    output wire uart_wrn,         //д�����źţ�����Ч
    input wire uart_dataready,    //��������׼����
    input wire uart_tbre,         //�������ݱ�־
    input wire uart_tsre,         //���ݷ�����ϱ�־

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
    output wire ext_ram_we_n,       //ExtRAMдʹ�ܣ�����Ч

    //ֱ�������ź�
    output wire txd,  //ֱ�����ڷ��Ͷ�
    input  wire rxd,  //ֱ�����ڽ��ն�

    //Flash�洢���źţ��ο� JS28F640 оƬ�ֲ�
    output wire [22:0]flash_a,      //Flash��ַ��a0����8bitģʽ��Ч��16bitģʽ������
    inout  wire [15:0]flash_d,      //Flash����
    output wire flash_rp_n,         //Flash��λ�źţ�����Ч
    output wire flash_vpen,         //Flashд�����źţ��͵�ƽʱ���ܲ�������д
    output wire flash_ce_n,         //FlashƬѡ�źţ�����Ч
    output wire flash_oe_n,         //Flash��ʹ���źţ�����Ч
    output wire flash_we_n,         //Flashдʹ���źţ�����Ч
    output wire flash_byte_n,       //Flash 8bitģʽѡ�񣬵���Ч����ʹ��flash��16λģʽʱ����Ϊ1

    //USB �������źţ��ο� SL811 оƬ�ֲ�
    output wire sl811_a0,
    //inout  wire[7:0] sl811_d,     //USB�������������������dm9k_sd[7:0]����
    output wire sl811_wr_n,
    output wire sl811_rd_n,
    output wire sl811_cs_n,
    output wire sl811_rst_n,
    output wire sl811_dack_n,
    input  wire sl811_intrq,
    input  wire sl811_drq_n,

    //����������źţ��ο� DM9000A оƬ�ֲ�
    output wire dm9k_cmd,
    inout  wire[15:0] dm9k_sd,
    output wire dm9k_iow_n,
    output wire dm9k_ior_n,
    output wire dm9k_cs_n,
    output wire dm9k_pwrst_n,
    input  wire dm9k_int,

    //ͼ������ź�
    output wire[2:0] video_red,    //��ɫ���أ�3λ
    output wire[2:0] video_green,  //��ɫ���أ�3λ
    output wire[1:0] video_blue,   //��ɫ���أ�2λ
    output wire video_hsync,       //��ͬ����ˮƽͬ�����ź�
    output wire video_vsync,       //��ͬ������ֱͬ�����ź�
    output wire video_clk,         //����ʱ�����
    output wire video_de           //��������Ч�źţ���������������
);

wire clk, rst;
assign clk = clock_btn;
assign rst = reset_btn;

// MMU �ź�
wire mmu_read_wire, mmu_write_wire;
wire[31:0] mmu_addr_wire, mmu_out_data, mmu_in_data;
reg [31:0] mmu_addr; // MMU��ַ/����

// ���򴫵��ź�
wire ex_ifid_bubble, ex_idex_bubble, ex_if_ifpcjump;
wire[2:0] ex_ex_i_bubblecnt         , ex_ex_i_stopcnt         ;
reg [2:0] ex_ex_o_bubblecnt = 3'b000, ex_ex_o_stopcnt = 3'b011; // stop the inital commands
wire[31:0] ex_if_pcjumpto;

// ��·�ź�
wire ex_id_f_ifregwrite;
wire id_ifregwrite;
wire[4:0] id_regwrite;
wire[31:0] id_regdata;

// IF/ID �ź�
wire[31:0] if_id_i_ins, if_id_i_npc;
reg[31:0]  if_id_o_ins, if_id_o_npc;
// IM �ź�
wire[31:0] if_imdata, if_imaddr;

IF if_instance(
    // input
    .clk(clk),
    .rst(rst),
    .jpc(ex_if_pcjumpto),
    .if_pc_jump(ex_if_ifpcjump),
    .if_bubble(ex_ifid_bubble),
    .im_data(if_imdata),
    
    // output
    .im_addr(if_imaddr),
    
    .npc(if_id_i_npc),
    .ins(if_id_i_ins)
);

// IF/ID registers
always@(posedge clk) begin
    if (!ex_ifid_bubble) begin
        if_id_o_npc <= if_id_i_npc;
        if_id_o_ins <= if_id_i_ins;
    end
end

// ID/EX �ź�
wire id_ex_i_ifregwrite    , id_ex_i_ifmemread    , id_ex_i_ifmemwrite    ;
reg  id_ex_o_ifregwrite = 0, id_ex_o_ifmemread = 0, id_ex_o_ifmemwrite = 0;
wire[5:0] id_ex_i_op, id_ex_i_func;
reg [5:0] id_ex_o_op, id_ex_o_func;
wire[4:0] id_ex_i_regwrite;
reg [4:0] id_ex_o_regwrite;
wire[25:0] id_ex_i_jpc;
reg [25:0] id_ex_o_jpc;
wire[31:0] id_ex_i_data1, id_ex_i_data2, id_ex_i_data2imm, id_ex_i_npc;
reg [31:0] id_ex_o_data1, id_ex_o_data2, id_ex_o_data2imm, id_ex_o_npc;

ID id_instance(
    // input
    .clk(clk),
    
    .ins(if_id_o_ins),
    .reg_write(id_ifregwrite),
    .write_reg(id_regwrite),
    .write_data(id_regdata),
    
    .npc_i(if_id_o_npc),
    
    // output
    .if_reg_write(id_ex_i_ifregwrite),
    .if_mem_read(id_ex_i_ifmemread),
    .if_mem_write(id_ex_i_ifmemwrite),
    .op(id_ex_i_op),
    .func(id_ex_i_func),
    .data_a(id_ex_i_data1),
    .data_b(id_ex_i_data2),
    .data_write_reg(id_ex_i_regwrite),
    .imm(id_ex_i_data2imm),
    .jpc(id_ex_i_jpc),
    
    .npc_o(id_ex_i_npc)
);

reg id_ex_exstop;
assign ex_idex_bubble = (ex_ex_i_bubblecnt != 0);
assign ex_ifid_bubble = (ex_ex_i_bubblecnt != 0);

// ID/EX registers
always@(posedge clk) begin
    ex_ex_o_bubblecnt <= ex_ex_i_bubblecnt;
    ex_ex_o_stopcnt <= ex_ex_i_stopcnt;

    if (!ex_idex_bubble) begin
        id_ex_exstop <= (ex_ex_i_stopcnt != 0);
        id_ex_o_npc <= id_ex_i_npc;
        id_ex_o_ifregwrite <= id_ex_i_ifregwrite;
        id_ex_o_ifmemread <= id_ex_i_ifmemread;
        id_ex_o_ifmemwrite <= id_ex_i_ifmemwrite;
        id_ex_o_op <= id_ex_i_op;
        id_ex_o_func <= id_ex_i_func;
        id_ex_o_regwrite <= id_ex_i_regwrite;
        id_ex_o_data1 <= id_ex_i_data1;
        id_ex_o_data2 <= id_ex_i_data2;
        id_ex_o_data2imm <= id_ex_i_data2imm;
        id_ex_o_jpc <= id_ex_i_jpc;
    end
    else begin
        id_ex_exstop <= 1'b1;
    end
end

// EX/MEM �ź�
wire ex_mem_i_ifregwrite    , ex_mem_i_ifmemread    , ex_mem_i_ifmemwrite    , ex_mem_i_loadbyte;
reg  ex_mem_o_ifregwrite = 0, ex_mem_o_ifmemread = 0, ex_mem_o_ifmemwrite = 0, ex_mem_o_loadbyte;
wire[4:0] ex_mem_i_regwrite;
reg [4:0] ex_mem_o_regwrite;
wire[31:0] ex_mem_i_res, ex_mem_i_memwrite;
reg [31:0] ex_mem_o_res, ex_mem_o_memwrite;
/*
wire ex_if_s_ifpcjump;
wire[31:0] ex_if_s_pcjumpto;
*/

EX ex_instance(
    // input
    .op(id_ex_o_op),
    .func(id_ex_o_func),
    .ex_stop(id_ex_exstop),
    .data_a(id_ex_o_data1),
    .data_b(id_ex_o_data2),
    .imm(id_ex_o_data2imm),
    .jpc(id_ex_o_jpc),
    .npc(id_ex_o_npc),
    
    .if_reg_write_i(id_ex_o_ifregwrite),
    .if_mem_read_i(id_ex_o_ifmemread),
    .if_mem_write_i(id_ex_o_ifmemwrite),
    .data_write_reg_i(id_ex_o_regwrite),
    
    // foobar
    .bubble_cnt_last(ex_ex_o_bubblecnt),
    .ex_stopcnt_last(ex_ex_o_stopcnt),
    .bubble_cnt(ex_ex_i_bubblecnt),
    .ex_stopcnt(ex_ex_i_stopcnt),
        
    // output
    .result(ex_mem_i_res),
    .mem_data(ex_mem_i_memwrite),
    .if_pc_jump(ex_if_ifpcjump),
    .pc_jumpto(ex_if_pcjumpto),
    .load_byte(ex_mem_i_loadbyte),
    
    .if_reg_write_o(ex_mem_i_ifregwrite),
    .if_mem_read_o(ex_mem_i_ifmemread),
    .if_mem_write_o(ex_mem_i_ifmemwrite),
    
    .if_forward_reg_write(ex_id_f_ifregwrite),
    
    .data_write_reg_o(ex_mem_i_regwrite)
);

// EX/MEM registers
always@(posedge clk) begin
    ex_mem_o_ifregwrite <= ex_mem_i_ifregwrite;
    ex_mem_o_ifmemread <= ex_mem_i_ifmemread;
    ex_mem_o_ifmemwrite <= ex_mem_i_ifmemwrite;
    ex_mem_o_regwrite <= ex_mem_i_regwrite;
    ex_mem_o_res <= ex_mem_i_res;
    ex_mem_o_loadbyte <= ex_mem_i_loadbyte;
    ex_mem_o_memwrite <= ex_mem_i_memwrite;
end

// MEM/WB �ź�
wire mem_wb_i_ifregwrite, mem_wb_i_ifmemread;
wire[4:0] mem_wb_i_regwrite;
wire[31:0] mem_wb_i_res, mem_wb_i_memread;

// forwarding unit
assign id_ifregwrite = mem_wb_i_ifregwrite || ex_id_f_ifregwrite;
assign id_regwrite = mem_wb_i_ifregwrite ? mem_wb_i_regwrite : ex_mem_i_regwrite;
assign id_regdata = mem_wb_i_ifregwrite ? (mem_wb_i_ifmemread ? mem_wb_i_memread : mem_wb_i_res) : ex_mem_i_res;

MEM mem_instance(
    //input
    .mem_read(ex_mem_o_ifmemread),
    .mem_write(ex_mem_o_ifmemwrite),
    
    .ex_res_i(ex_mem_o_res),
    .if_reg_write_i(ex_mem_o_ifregwrite),
    .data_write_reg_i(ex_mem_o_regwrite),
    
    // output
    .mem_read_o(mem_wb_i_ifmemread),
    
    .ex_res_o(mem_wb_i_res),
    .if_reg_write_o(mem_wb_i_ifregwrite),
    .data_write_reg_o(mem_wb_i_regwrite)
);

// MMU MUX
wire mmu_ifmem = ex_mem_o_ifmemread | ex_mem_o_ifmemwrite;
wire mmu_bytemode = mmu_ifmem ? ex_mem_o_loadbyte : 1'b0;
assign mmu_read_wire = mmu_ifmem ? ex_mem_o_ifmemread : 1'b1;
assign mmu_write_wire = mmu_ifmem ? ex_mem_o_ifmemwrite : 1'b0;
assign mmu_addr_wire = mmu_ifmem ? ex_mem_o_res : if_imaddr;
assign if_imdata = mmu_out_data;
assign mem_wb_i_memread = mmu_out_data;
assign mmu_in_data = ex_mem_o_memwrite;

// MMU
MMU mmu_instance(
    .clk(clk_50M),
    .if_read(mmu_read_wire),
    .if_write(mmu_write_wire),
    .addr(mmu_addr_wire),
    .input_data(mmu_in_data),
    .bytemode(mmu_bytemode),
    
    .output_data(mmu_out_data),
    
    // pass ports
    
    // base_ram
    .base_ram_data(base_ram_data),
    .base_ram_addr(base_ram_addr),
    .base_ram_be_n(base_ram_be_n),
    .base_ram_ce_n(base_ram_ce_n),
    .base_ram_oe_n(base_ram_oe_n),
    .base_ram_we_n(base_ram_we_n),
    // ext_ram
    .ext_ram_data(ext_ram_data),
    .ext_ram_addr(ext_ram_addr),
    .ext_ram_be_n(ext_ram_be_n),
    .ext_ram_ce_n(ext_ram_ce_n),
    .ext_ram_oe_n(ext_ram_oe_n),
    .ext_ram_we_n(ext_ram_we_n)
);

endmodule
