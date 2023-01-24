module gayle_fifo
(
	input 	clk,		    		// bus clock
  input clk7_en,
	input 	reset,			   		// reset 
	input	[15:0] data_in,			// data in
	output	reg [15:0] data_out,	// data out
	input	rd,						// read from fifo
	input	wr,						// write to fifo
	input [1:0] packet_state,
	output	full,					// fifo is full
	output	empty,					// fifo is empty
	output	last_out,				// the last word of a sector is being read
	output	last_in					// the last word of a sector is being written
);

localparam PACKET_IDLE       = 0;
localparam PACKET_WAITCMD    = 1;
localparam PACKET_PROCESSCMD = 2;

// local signals and registers
reg 	[15:0] mem [4095:0];		// 16 bit wide fifo memory
reg		[12:0] inptr;				// fifo input pointer
reg		[12:0] outptr;				// fifo output pointer
wire	empty_rd;					// fifo empty flag (set immediately after reading the last word)
reg		empty_wr;					// fifo empty flag (set one clock after writting the empty fifo)
reg   [1:0] packet_state_last;

// main fifo memory (implemented using synchronous block ram)
always @(posedge clk)
  if (clk7_en) begin
  	if (wr)
  		mem[inptr[11:0]] <= data_in;
  end
		
always @(posedge clk)
  if (clk7_en) begin
  	data_out <= mem[outptr[11:0]];
  end

always @(posedge clk)
	if (clk7_en) packet_state_last <= packet_state;

// fifo write pointer control
always @(posedge clk)
	if (clk7_en) begin
		if (reset || packet_state != packet_state_last)
			inptr <= 0;
		else if (wr)
			inptr <= inptr + 1'd1;
	end

// fifo read pointer control
always @(posedge clk)
	if (clk7_en) begin
		if (reset || packet_state != packet_state_last)
			outptr <= 0;
		else if (rd)
			outptr <= outptr + 1'd1;
  end

// the empty flag is set immediately after reading the last word from the fifo
assign empty_rd = inptr==outptr ? 1'b1 : 1'b0;

// after writting empty fifo the empty flag is delayed by one clock to handle ram write delay
always @(posedge clk)
  if (clk7_en) begin
  	empty_wr <= empty_rd;
  end

assign empty = empty_rd | empty_wr;

// at least 512 bytes are in FIFO 
// this signal is activated when 512th byte is written to the empty fifo
// then it's deactivated when 512th byte is read from the fifo (hysteresis)
// special handlig of packet commands
assign full = (inptr[12:8] != outptr[12:8] || packet_state == PACKET_WAITCMD && inptr == 6) ? 1'b1 : 1'b0;

assign last_out = outptr[7:0] == 8'hFF ? 1'b1 : 1'b0;
assign last_in  = inptr [7:0] == 8'hFF ? 1'b1 : 1'b0;


endmodule
