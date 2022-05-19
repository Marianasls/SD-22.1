/*
 * Simple 8-bit UART realization.
 * Combine receiver, transmitter and baud rate generator.
 * Able to operate 8 bits of serial data, one start bit, one stop bit
 * ordem do pinplanner RX TX GND 
 */
module Uart8  #(
    parameter CLOCK_RATE = 50000000, // board internal clock - 50 Mhz
    parameter BAUD_RATE = 9600
)(
    input wire clk,

    // rx interface
    input wire rx,
    //input wire rxEn ,
    //output wire [7:0] out,
    //output wire rxDone,
    output wire rxBusy,
    output wire rxErr,

    // tx interface
    output wire tx,
    //input wire txEn,
    //input wire txStart,
    //input wire [7:0] in,
    output wire txDone,
    output wire txBusy
	 
);
wire rxClk;
wire txClk;
wire txEn = 1;
wire rxEn = 1;

//parameter wire [7:0] in = 0;
wire [7:0] out;
wire rxDone;
reg txStart = 0;

BaudRateGenerator #(
    .CLOCK_RATE(CLOCK_RATE),
    .BAUD_RATE(BAUD_RATE)
) generatorInst (
    .clk(clk),
    .rxClk(rxClk),
    .txClk(txClk)
);

Uart8Receiver rxInst (
    .clk(rxClk),
    .en(rxEn),
    .in(rx),
    .out(out),
    .done(rxDone),
    .busy(rxBusy),
    .err(rxErr)
);

Uart8Transmitter txInst (
    .clk(txClk),
    .en(txEn),
    .start(txStart),
    .in(out),
    .out(tx),
    .done(txDone),
    .busy(txBusy)
);

always @(posedge clk)
	begin
		txStart <= rxDone;
	end

endmodule
