module ZUBRI
(input clk,				//Тактовый сигнал 50МГц (1 такт = 20нс) 
 input write,			//Признак ЗП
	   parity,			//Признак ПЧ
	   read,			//Признак СЧ
	   out_data,	    //Признак ВЧ
 input [8:0] in_A, 		//Шина адреса на входе
 input [26:0] in_D,		//Шина числа на входе
 output [26:0]out_D,	//Шина числа на выходе
 output [10:0] RAM_A,	//Шина для адреса на схему памяти 
 inout [7:0] RAM_D,		//Шина числа на схему памяти
 output nRAM_CE1, RAM_CE2, nRAM_WE, nRAM_OE,	//Управляющие сигналы схемы памяти
 output adrWrite
 );
//---------------------------------------------- 
reg        [3:0] state;					//Создаём узлы автомата
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
 reg [26:0] reading_data;		//регистр для считанного 27-р числа
 reg [7:0] reading_data_1,reading_data_2, reading_data_3,reading_data_4; 	
 reg [26:0] writing_data_in;	//регистр для хранения полуенного 27-р числа от ВУ
 reg [7:0] writing_data_out;	//регистр для записи числа
 reg [8:0] adress_in;			//регистр для хранения полученного адреса
 reg [10:0] adress_out;			//регистр для формирования отдельного адреса для каждого 8-р числа
 reg CE1, CE2, WE, OE;			//сигналы для управления схемой памяти
 reg signal;					//регист управляющий двунаправленными выводами
 reg [3:0] step;
 reg [7:0] count;
 reg div = 1'b0;
 reg zpa;				
//---------------------------------------------- 
initial		//Инициализируем начальные значения 
	begin
	state <= WAIT;
	signal <= 1'b0;
	end
//---------------------------------------------- 
always @ (posedge clk)			//Делитель частоты 	
begin
	if (count == 2) begin		//1 такт равен 120нс
		count <= 0;
		div <= !div;
		end
	else count <= count + 1;
		
end
//---------------------------------------------- 
always @ (posedge div)
begin
	case(state)
			WAIT:				//Режим ожидания
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
			PREPARE_READ:		//Подготовка к чтению
			begin
				CE1 <= 1'b0;
				CE2 <= 1'b1;
				WE <= 1'b1;
				OE <= 1'b0;
				zpa <= 1'b0;
				adress_out = {adress_in,2'b00};				
				state = READ_1;
			end
			
			READ_1:				//Считывание первых 8-р числа
			begin
				adress_out <= {adress_in,2'b01};
				reading_data_1 <= RAM_D; 
				state <= READ_2;
			end
			READ_2:				//Считывание вторых 8-р числа				
			begin
				zpa <= 1'b0;
				adress_out <= {adress_in,2'b10};
				reading_data_2 <= RAM_D; 
				state <= READ_3;
			end
			READ_3:				//Считывание третьих 8-р числа				
			begin
				adress_out <= {adress_in,2'b11};
				reading_data_3 <= RAM_D; 
				state <= READ_4;
			end
			READ_4:				//Считывание четвертых 8-р числа			
			begin
				adress_out <= 13'b0000_0000_000;
				reading_data_4 <= RAM_D; 
				state <= READ;
			end
			READ:				//Формирование 27-р числа и его вывод
			begin
				if (out_data) begin 
					reading_data <= {reading_data_1,reading_data_2,reading_data_3,reading_data_4[7:5]};
					state <= WAIT;
				end
			end		
//-------------------------------------- 					
			PREPARE_WRITE:		//Подготовка к записи		
			begin
				signal <= 1'b1;
				CE1 <= 1'b0;
				zpa <= 1'b0;
				if (parity) begin
					writing_data_in <= in_D;			
					state <= WRITE_1;
				end					
			end			
			
			WRITE_1:			//Запись первых 8-р числа
			begin
				CE2 <= 1'b0;
				adress_out <= {adress_in,2'b00};
				writing_data_out <= writing_data_in[26:19];
				state <= WRITE;
			end
			WRITE_2:			//Запись вторых 8-р числа
			begin
				CE2 <= 1'b0;
				adress_out <= {adress_in,2'b01};
				writing_data_out <= writing_data_in[18:11];
				state <= WRITE;
			end
			WRITE_3:			//Запись третьих 8-р числа
			begin
				CE2 <= 1'b0;
				adress_out <= {adress_in,2'b10};
				writing_data_out <= writing_data_in[10:3];
				state <= WRITE;
			end
			WRITE_4:			//Запись четвёртых 8-р числа
			begin
				CE2 <= 1'b0;
				adress_out <= {adress_in,2'b11};
				writing_data_out <= {writing_data_in[2:0],5'b00000};
				state <= WRITE;
			end
			
			WRITE:				//Запись в память
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
assign nRAM_CE1 = CE1;		//Вывод необходимых
assign RAM_CE2 = CE2;		//управляющих сигналов
assign nRAM_WE = WE;		//на схему памяти
assign nRAM_OE = OE;

assign RAM_A = adress_out;							//Вывод адреса на схему памяти
assign out_D = reading_data;						//Вывод считаного числа на ВУ
assign RAM_D = (signal) ? writing_data_out : 8'bz;	//Вывод числа на схему памяти для записи

assign adrWrite = zpa;
endmodule 