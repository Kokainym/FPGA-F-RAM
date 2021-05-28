module ZUBRI
(input clk,				//�������� ������ 50��� (1 ���� = 20��) 
 input write,			//������� ��
	   parity,			//������� ��
	   read,			//������� ��
	   out_data,	    //������� ��
 input [8:0] in_A, 		//���� ������ �� �����
 input [26:0] in_D,		//���� ����� �� �����
 output [26:0]out_D,	//���� ����� �� ������
 output [10:0] RAM_A,	//���� ��� ������ �� ����� ������ 
 inout [7:0] RAM_D,		//���� ����� �� ����� ������
 output nRAM_CE1, RAM_CE2, nRAM_WE, nRAM_OE,	//����������� ������� ����� ������
 output adrWrite
 );
//---------------------------------------------- 
reg        [3:0] state;					//������ ���� ��������
localparam [3:0] WAIT          = 0;		
localparam [3:0] PREPARE_READ  = 1;
localparam [3:0] READ_1        = 2;
localparam [3:0] READ_2        = 3;
localparam [3:0] READ_3        = 4;
localparam [3:0] READ_4        = 5;
localparam [3:0] READ          = 6;
localparam [3:0] PREPARE_WRITE = 7;
localparam [3:0] WRITE_1       = 8;
localparam [3:0] WRITE_2       = 9;
localparam [3:0] WRITE_3       = 10;
localparam [3:0] WRITE_4       = 11;
localparam [3:0] WRITE         = 12;
//---------------------------------------------- 
 reg [26:0] reading_data;		//������� ��� ���������� 27-� �����
 reg [7:0] reading_data_1,reading_data_2, reading_data_3,reading_data_4; 	
 reg [26:0] writing_data_in;	//������� ��� �������� ���������� 27-� ����� �� ��
 reg [7:0] writing_data_out;	//������� ��� ������ �����
 reg [8:0] adress_in;			//������� ��� �������� ����������� ������
 reg [10:0] adress_out;			//������� ��� ������������ ���������� ������ ��� ������� 8-� �����
 reg CE1, CE2, WE, OE;			//������� ��� ���������� ������ ������
 reg signal;					//������ ����������� ���������������� ��������
 reg [3:0] step;
 reg [7:0] count;
 reg div = 1'b0;
 reg zpa;				
//---------------------------------------------- 
initial		//�������������� ��������� �������� 
	begin
	state <= WAIT;
	signal <= 1'b0;
	end
//---------------------------------------------- 
always @ (posedge clk)			//�������� ������� 	
begin
	if (count == 2) begin		//1 ���� ����� 120��
		count <= 0;
		div <= !div;
		end
	else count <= count + 1;
		
end
//---------------------------------------------- 
always @ (posedge div)
begin
	case(state)
			WAIT:				//����� ��������
			begin
				CE1 <= 1'b1;
				CE2 <= 1'b0;
				WE <= 1'b0;
				OE <= 1'b0;
				signal <= 1'b0;
				
				if (read) begin 
					state <= PREPARE_READ;
					adress_in <= in_A;
					zpa <= 1'b1;
					end
				if (write) begin
					state <= PREPARE_WRITE;
					adress_in <= in_A;
					zpa <= 1'b1;
					end			
			end
//-------------------------------------- 		
			PREPARE_READ:		//���������� � ������
			begin
				CE1 <= 1'b0;
				CE2 <= 1'b1;
				WE <= 1'b1;
				OE <= 1'b0;
				zpa <= 1'b0;
				adress_out = {adress_in,2'b00};				
				state = READ_1;
			end
			
			READ_1:				//���������� ������ 8-� �����
			begin
				adress_out <= {adress_in,2'b01};
				reading_data_1 <= RAM_D; 
				state <= READ_2;
			end
			READ_2:				//���������� ������ 8-� �����				
			begin
				zpa <= 1'b0;
				adress_out <= {adress_in,2'b10};
				reading_data_2 <= RAM_D; 
				state <= READ_3;
			end
			READ_3:				//���������� ������� 8-� �����				
			begin
				adress_out <= {adress_in,2'b11};
				reading_data_3 <= RAM_D; 
				state <= READ_4;
			end
			READ_4:				//���������� ��������� 8-� �����			
			begin
				adress_out <= 13'b0000_0000_000;
				reading_data_4 <= RAM_D; 
				state <= READ;
			end
			READ:				//������������ 27-� ����� � ��� �����
			begin
				if (out_data) begin 
					reading_data <= {reading_data_1,reading_data_2,reading_data_3,reading_data_4[7:5]};
					state <= WAIT;
				end
			end		
//-------------------------------------- 					
			PREPARE_WRITE:		//���������� � ������		
			begin
				signal <= 1'b1;
				CE1 <= 1'b0;
				zpa <= 1'b0;
				if (parity) begin
					writing_data_in <= in_D;			
					state <= WRITE_1;
				end					
			end			
			
			WRITE_1:			//������ ������ 8-� �����
			begin
				CE2 <= 1'b0;
				adress_out <= {adress_in,2'b00};
				writing_data_out <= writing_data_in[26:19];
				state <= WRITE;
			end
			WRITE_2:			//������ ������ 8-� �����
			begin
				CE2 <= 1'b0;
				adress_out <= {adress_in,2'b01};
				writing_data_out <= writing_data_in[18:11];
				state <= WRITE;
			end
			WRITE_3:			//������ ������� 8-� �����
			begin
				CE2 <= 1'b0;
				adress_out <= {adress_in,2'b10};
				writing_data_out <= writing_data_in[10:3];
				state <= WRITE;
			end
			WRITE_4:			//������ �������� 8-� �����
			begin
				CE2 <= 1'b0;
				adress_out <= {adress_in,2'b11};
				writing_data_out <= {writing_data_in[2:0],5'b00000};
				state <= WRITE;
			end
			
			WRITE:				//������ � ������
			begin
				
				CE1 <= 1'b0;
				CE2 <= 1'b1;
				WE <= 1'b0;
				OE <= 1'b0;
				step = step + 1;
				case (step)
					1: state = WRITE_2;
					2: state = WRITE_3;
					3: state = WRITE_4;
					4: state = WAIT;
				endcase		
			end
	endcase	
end	
//---------------------------------------------- 	
assign nRAM_CE1 = CE1;		//����� �����������
assign RAM_CE2 = CE2;		//����������� ��������
assign nRAM_WE = WE;		//�� ����� ������
assign nRAM_OE = OE;

assign RAM_A = adress_out;							//����� ������ �� ����� ������
assign out_D = reading_data;						//����� ��������� ����� �� ��
assign RAM_D = (signal) ? writing_data_out : 8'bz;	//����� ����� �� ����� ������ ��� ������

assign adrWrite = zpa;
endmodule 