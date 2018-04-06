module spi_demo (
	inout spi_miso, spi_mosi, spi_sck
);
	wire clk;

	SB_HFOSC #(.CLKHF_DIV("0b10")) u_SB_HFOSC(.CLKHFPU(1'b1), .CLKHFEN(1'b1), .CLKHF(clk));

	localparam SPICR0		= 4'h8;
	localparam SPICR1		= 4'h9;
	localparam SPICR2		= 4'hA;
	localparam SPIBR		= 4'hB;
	localparam SPITXDR		= 4'hD;
	localparam SPIRXDR		= 4'hE;
	localparam SPICSR		= 4'hF;
	localparam SPISR		= 4'hC;
	localparam SPIINTSR		= 4'h6;
	localparam SPIINTCR		= 4'h7;

	reg [9:0] cnt;

	wire [7:0] spi_read_data;
	reg  [7:0] write_data;
	reg  [7:0] address;
	reg  wstrb;
	wire spi_ack;


	reg [3:0] block = 4'b0000;

	reg [3:0] state = 0;

	reg [7:0] data_counter = 0;

	reg strobe = 0; 
	always @(posedge clk)
	begin
		case (state)
					4'b0000 : // RESET SB_SPI
						begin
							write_data <= 8'h80;
							address    <= { block , SPICR1 };
							wstrb	   <= 1'b1;
							strobe     <= 1'b1;

							state      <= state + 1;
						end
					4'b0001 :
						begin							
							if (spi_ack==0)
								state      <= state;
							else 
							begin
								wstrb	   <= 1'b0;
								strobe     <= 1'b0;
								state      <= state + 1;
							end
						end
					4'b0010 : // SET DIVIDER
						begin
							write_data <= 8'h3f;
							address    <= { block , SPIBR };
							wstrb	   <= 1'b1;
							strobe     <= 1'b1;
							
							state      <= state + 1;
						end
					4'b0011 :
						begin
							if (spi_ack==0)
								state      <= state;
							else 
							begin
								wstrb	   <= 1'b0;
								strobe     <= 1'b0;
								state      <= state + 1;
							end
						end
					4'b0100 : // SET MASTER MODE
						begin
							write_data <= 8'hC0;
							address    <= { block , SPICR2 };
							wstrb	   <= 1'b1;
							strobe     <= 1'b1;

							state      <= state + 1;
						end
					4'b0101 :
						begin
							if (spi_ack==0)
								state      <= state;
							else 
							begin
								wstrb	   <= 1'b0;
								strobe     <= 1'b0;
								state      <= state + 1;
							end
						end
					4'b0110 : // SEND BYTE
						begin
							write_data   <= data_counter;
							data_counter <= data_counter + 1;
							address    <= { block , SPITXDR };
							wstrb	   <= 1'b1;
							strobe     <= 1'b1;

							state     <= state + 1;
						end

					4'b0111 :
						begin
							data_counter <= data_counter;
							if (spi_ack==0)
								state      <= state;
							else 
							begin
								wstrb	   <= 1'b0;
								strobe     <= 1'b0;
								state      <= state + 1;
							end
						end


					4'b1000 : // READ STATUS
						begin
							strobe     <= 1'b1;
							wstrb	   <= 1'b0;
							address    <= { block , SPISR };

							state      <= state + 1;							
						end


					4'b1001 :
						begin
							if (spi_ack==0)
								state      <= state;
							else 
							begin
								wstrb	   <= 1'b0;
								strobe     <= 1'b0;
								state      <= state + 1;
							end
						end


					4'b1010 : // WAIT FOR RRDY
						begin
							cnt <= 0;
							if (spi_read_data[4]==0)
								state      <= 4'b1000;
							else 
								state      <= 4'b1100;
						end

					4'b1100 : // PAUSE - JUST TO DO EASY CHECK WITH ANALYZER
						begin
							if (cnt[9]==1)
							begin								
								state      <= 4'b0110;
							end
							else
							begin
								cnt 	   <= cnt + 1;
								state      <= 4'b1100;								
							end
						end

		endcase
	end


	wire mi;
	wire so;
	wire soe;
	wire si;
	wire mo;
	wire moe;
	wire scki;
	wire scko;
	wire sckoe;

	wire mcsno3,mcsno2,mcsno1,mcsno0;
	wire mcsnoe3,mcsnoe2,mcsnoe1,mcsnoe0;



	SB_SPI #(
		.BUS_ADDR74("0b0000")
	) spi_i (
		.SBCLKI(clk),
		.SBRWI(wstrb),
		.SBSTBI(strobe),
		.SBADRI0(address[0]),
		.SBADRI1(address[1]),
		.SBADRI2(address[2]),
		.SBADRI3(address[3]),
		.SBADRI4(address[4]),
		.SBADRI5(address[5]),
		.SBADRI6(address[6]),
		.SBADRI7(address[7]),
		.SBDATI0(write_data[0]),
		.SBDATI1(write_data[1]),
		.SBDATI2(write_data[2]),
		.SBDATI3(write_data[3]),
		.SBDATI4(write_data[4]),
		.SBDATI5(write_data[5]),
		.SBDATI6(write_data[6]),
		.SBDATI7(write_data[7]),
		.SBDATO0(spi_read_data[0]),
		.SBDATO1(spi_read_data[1]),
		.SBDATO2(spi_read_data[2]),
		.SBDATO3(spi_read_data[3]),
		.SBDATO4(spi_read_data[4]),
		.SBDATO5(spi_read_data[5]),
		.SBDATO6(spi_read_data[6]),
		.SBDATO7(spi_read_data[7]),
		.MI(mi),
		.SO(so),
		.SOE(soe),
		.SI(si),
		.MO(mo),
		.MOE(moe),
		.SCKI(scki),
		.SCKO(scko),
		.SCKOE(sckoe),
		.SCSNI(1'b1),
		.SBACKO(spi_ack),
		.SPIIRQ(),
		.SPIWKUP(),
		.MCSNO3(mcsno3),
		.MCSNO2(mcsno2),
		.MCSNO1(mcsno1),
		.MCSNO0(mcsno0),
		.MCSNOE3(mcsnoe3),
		.MCSNOE2(mcsnoe2),
		.MCSNOE1(mcsnoe1),
		.MCSNOE0(mcsnoe0)
	);

	SB_IO #(
		.PIN_TYPE(6'b101001)
	) miso_io (
		.PACKAGE_PIN(spi_miso),
		.OUTPUT_ENABLE(soe),
		.D_OUT_0(so),
		.D_IN_0(mi)
	);

	SB_IO #(
		.PIN_TYPE(6'b101001)
	) mosi_io (
		.PACKAGE_PIN(spi_mosi),
		.OUTPUT_ENABLE(moe),
		.D_OUT_0(mo),
		.D_IN_0(si)
	);

	SB_IO #(
		.PIN_TYPE(6'b101001),
		.PULLUP(1'b1)
	) sck_io (
		.PACKAGE_PIN(spi_sck),
		.OUTPUT_ENABLE(sckoe),
		.D_OUT_0(scko),
		.D_IN_0(scki)
	);
	
endmodule
