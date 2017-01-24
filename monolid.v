`timescale 1ns / 1ns // `timescale time_unit/time_precision
// Part 2 skeleton

module monolid
(
SW,
KEY,
CLOCK_50,
HEX0,	//	On Board 50 MHz
// Your inputs and outputs here
// The ports below are for the VGA output.  Do not change.
VGA_CLK,   //	VGA Clock
VGA_HS,	//	VGA H_SYNC
VGA_VS,	//	VGA V_SYNC
VGA_BLANK_N,	//	VGA BLANK
VGA_SYNC_N,	//	VGA SYNC
VGA_R,   //	VGA Red[9:0]
VGA_G,	//	VGA Green[9:0]
VGA_B   //	VGA Blue[9:0]
);

input [9:0] SW; //ADDED BY PROGRAMMER @@@@@
input [3:0] KEY;

input	CLOCK_50;	//	50 MHz
// Declare your inputs and outputs here
// Do not change the following outputs
output	VGA_CLK;   //	VGA Clock
output	VGA_HS;	//	VGA H_SYNC
output	VGA_VS;	//	VGA V_SYNC
output	VGA_BLANK_N;	//	VGA BLANK
output	VGA_SYNC_N;	//	VGA SYNC
output	[9:0]	VGA_R;   //	VGA Red[9:0]
output	[9:0]	VGA_G;	//	VGA Green[9:0]
output	[9:0]	VGA_B;   //	VGA Blue[9:0]
output [6:0] HEX0;
wire resetn;	       //ADDED BY PROGRAMMER @@@@@
assign resetn = KEY[0];        //ADDED BY PROGRAMMER @@@@@

// Create the colour, x, y and writeEn wires that are inputs to the controller.

wire [2:0] colour;	//ADDED BY PROGRAMMER @@@@@
wire [7:0] x;	//ADDED BY PROGRAMMER @@@@@
wire [6:0] y;	//ADDED BY PROGRAMMER @@@@@
wire writeEn;	//ADDED BY PROGRAMMER @@@@@

// Create an Instance of a VGA controller - there can be only one!
// Define the number of colours as well as the initial background
// image file (.MIF) for the controller.
vga_adapter VGA(
.resetn(resetn),
.clock(CLOCK_50),
.colour(colour),
.x(x),
.y(y),
.plot(writeEn),
/* Signals for the DAC to drive the monitor. */
.VGA_R(VGA_R),
.VGA_G(VGA_G),
.VGA_B(VGA_B),
.VGA_HS(VGA_HS),
.VGA_VS(VGA_VS),
.VGA_BLANK(VGA_BLANK_N),
.VGA_SYNC(VGA_SYNC_N),
.VGA_CLK(VGA_CLK));
defparam VGA.RESOLUTION = "160x120";
defparam VGA.MONOCHROME = "FALSE";
defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
defparam VGA.BACKGROUND_IMAGE = "black.mif";

// Put your code here. Your code should produce signals x,y,colour and writeEn
// for the VGA controller, in addition to any other functionality your design may require.

wire [1:0] selX, selY;
wire selCol, ldX, ldY, ldCol, choosex, choosey, selectX, selectY, start, enCoord, dirX, dirY;
wire [7:0] xPosition;
wire [2:0] col, score;
wire [6:0] YPosition; 
wire [2:0] angle=SW[2:0];

 hex_decoder H0(
        score, 
        HEX0
        );


control c0(
KEY[1], KEY[2], KEY[3], KEY[0], CLOCK_50, angle,
selX, selY, selCol, start,
ldX, ldY, ldCol, writeEn, xPosition, YPosition, enCoord, dirX, dirY, col, selectX, selectY, choosex, choosey, score
);

data d0(
xPosition, YPosition, col, selX, selY, selCol,
ldX, ldY, ldCol, KEY[0], CLOCK_50, selectX, selectY, choosex, choosey,
x, y, colour
);

endmodule

//Control Path
module control(
k1, k2, k3, resetn, clock, angle,
selX, selY, selCol, start, 
ldX, ldY, ldCol, plot, xPosition, YPosition, enCoord, dirX, dirY,col, selectX, selectY, choosex, choosey, score
);

input k1, k2, k3, resetn, clock;
input [2:0] angle;
output reg [1:0] selX, selY;
output reg selCol, ldX, ldY, ldCol, enCoord, dirX, dirY, plot, choosex, choosey, selectX, selectY, start;
output reg [7:0] xPosition;
output reg [6:0] YPosition;
output reg [2:0] col;
output reg [2:0] score; 

reg [7:0] posX;
reg [6:0] posY;

reg [5:0] current, next; //current is 3:0, same with next
// equivalent to:
// reg [3:0] current;
// reg [3:0] next;
reg [7:0] countX, countY;reg resX, resY, enX, enY;

reg [17:0] counter;
reg resetCounter;
reg newangle;

reg [7:0] trackPlatform, save;
reg initializeTracker, incTracker, decTracker, pulse, pulse60, ldsave;
reg regDirX, regDirY, newslope;

reg [19:0] pulsewidth50, pulsewidth60;

//11001011011100110101

integer xslope, yslope;

always@(posedge clock) begin
	pulse=0;
	if ((pulsewidth50==20'b11110100001001000000)|k1==0) begin
		pulsewidth50<=20'b0000000000000000;
		pulse=1;
		end
	if ((pulsewidth60==20'b11001011011100110101)| k1==0) begin
		pulsewidth60<=20'b0000000000000000;
		pulse60=1;
		end
	else begin pulsewidth50<=pulsewidth50+1;
	pulsewidth60<=pulsewidth60+1;
	end
	end
	

localparam STANDBY = 6'b000000,
USER_INPUT = 6'b000001,

WAIT_BLACK = 6'b000010,
FILL_BLACK = 6'b000011,
BLACK_X = 6'b000100,
BLACK_Y = 6'b000101,

WAIT_PLOT = 6'b000110,
PLOT = 6'b000111,
PLOT_X = 6'b001000,
PLOT_Y = 6'b001001,

PRE_COVER = 6'b001010,
COVER = 6'b001100,

MOVE_X = 6'b001101,

PRE_DRAW = 6'b001111,
DRAW = 6'b010000,

COUNT = 6'b010001,

WAIT_PLOT1 = 6'b010010, //rectangle 1        //@@@@@@@@
	PLOT1 = 6'b010011,                           //@@@@@@@
	PLOT_X1 = 6'b010100,                          //@@@@@@@
	PLOT_Y1 = 6'b010101,                             //@@@@@@@@@@
	
	PLOT2=6'b010110, //rectangle 2 (long rectangle) //@@@@@@@@
	PLOT_WAIT2=6'b010111,                           //@@@@@@@@
	PLOT_X2=6'b011000,                           //@@@@@@@@@
	PLOT_Y2=6'b011001,                             //@@@@@@@@
	
	PLOT3=6'b011010, //rectangle 3                 //@@@@@@@@
	PLOT_X3=6'b011011,                             //@@@@@@@
	PLOT_Y3=6'b011100,                             //@@@@@@@
	PLOT_WAIT3=6'b011101,
	
	//plot the ball
	STANDBY_BALL=6'b100100,
	LOAD_X=6'b011110, 
	WAIT_BALL=6'b011111,
	PLOT_BALL=6'b100001,
	PLOT_BALLX=6'b100010,
	PLOT_BALLY=6'b100011,
	UPDATE_COORD=6'b100100,
	WAIT_END=6'b100000;

//Circuit A - next state
always @ (posedge clock)
begin
case (current)
STANDBY: begin
if(k1 == 0) next = WAIT_BLACK;
else next = STANDBY;
end

			WAIT_PLOT1: next = k1 ? PLOT1 : WAIT_PLOT1;     //@@@@@@@
			PLOT1: begin
				if (countX < 6 & countY <= 2) next = PLOT_X1; //@@@@@@
				else if (countY < 2) next = PLOT_Y1;           //@@@@@@
				else next = PLOT_WAIT2;
			end
			
			PLOT_X1: next = PLOT1;     //@@@@@@
			PLOT_Y1: next = PLOT1;      //@@@@@@
			
			PLOT_WAIT2: begin            //@@@@@@
				next=PLOT2;                //@@@@@@
			end
			PLOT2: begin                    //@@@@@@
			if (countX < 2 & countY <= 20) next = PLOT_X2;     //@@@@@@
			
				else if (countY < 20) next = PLOT_Y2;    //@@@@@@
				else next = PLOT_WAIT3;                    //@@@@@@
			end
			
			
			PLOT_X2: next=PLOT2;                         //@@@@@@
			PLOT_Y2: next=PLOT2;                         //@@@@@@
			
			PLOT_WAIT3: begin                            //@@@@@@
				next=PLOT3;                                 //@@@@@@
			end
			PLOT3: begin                                     //@@@@@@
			if (countX < 6 & countY <= 2) next = PLOT_X3;   //@@@@@@
				else if (countY < 2) next = PLOT_Y3;          //@@@@@@
				else next = WAIT_PLOT;                           //@@@@@@
			end
			PLOT_X3: next=PLOT3;                              //@@@@@@
			PLOT_Y3: next=PLOT3; 

WAIT_BLACK: next = FILL_BLACK;
FILL_BLACK: begin
if (countX < 160 & countY <= 120) next = BLACK_X;
else if (countY < 120) next = BLACK_Y;
else next = WAIT_PLOT1;
end
BLACK_X: next = FILL_BLACK;
BLACK_Y: next = FILL_BLACK;


WAIT_PLOT: next = k1 ? PLOT : WAIT_PLOT; 

PLOT: begin
if (countX < 20 & countY <= 3) next = PLOT_X;
else if (countY < 3) next = PLOT_Y;
else next = WAIT_BALL;
end 

PLOT_X: next = PLOT;
PLOT_Y: next = PLOT;   

WAIT_BALL: next=PLOT_BALL;
PLOT_BALL: begin
	if (countX < 3 & countY <= 3) next = PLOT_BALLX;
				else if (countY < 3) next = PLOT_BALLY;
				else next = WAIT_END;
	end
	
	
PLOT_BALLX: next = PLOT_BALL;
PLOT_BALLY: next = PLOT_BALL;


//countX = 50;
//countY = 50;


WAIT_END: begin
			if (pulse==1) next=WAIT_BLACK;
			else next=WAIT_END;
	end
	default: next = STANDBY;
endcase
end
	
	always @ (posedge clock)
begin
xPosition = 0;
YPosition=0;
col = 0;
selX = 2'b00;
selY = 2'b00;
selCol = 0;
ldX = 0;
ldY = 0;
ldCol = 0;
plot = 0;
resX = 0;
resY = 0;
enX = 0;
enY = 0;
newangle=0;
resetCounter=0;

initializeTracker=0;
incTracker=0;
decTracker=0;

selectX=0;  //@@@@@@
selectY=0;
choosex=0; //@@@@@@
choosey=0; //@@@@@@@
//isBall=0;

start=0;
ldsave=0;

case (current)
STANDBY: begin
initializeTracker = 1;
start=1;
newangle=1;
end

			WAIT_PLOT1: begin //@@@@@@
			
			selX = 2'b00;      //@@@@@@
				ldX = 1;         //@@@@@@
				selY = 2'b00;    //@@@@@@
				selCol = 0;      //@@@@@@
				col=3'b110;      //@@@@@@@@@@@@@@@@@@@@@@@
				ldY = 1;         //@@@@@@
				ldCol = 1;       //@@@@@@
				resX = 1;       //@@@@@@
				resY = 1;       //@@@@@@
				choosex=1;      //@@@@@@@@@@@@@@@@@@@
				choosey=1;      //@@@@@@@@@@@@@@@@@@@@@@@
			end
			
			PLOT1: begin         //@@@@@@
				plot = 1;         //@@@@@@v
				
			end
		
			PLOT_X1: begin            //@@@@@@
				selX = 1;//@@@@@@
				ldX = 1;//@@@@@@
				enX = 1;//@@@@@@
			end
			PLOT_Y1: begin//@@@@@@
				selY = 2'b01;//@@@@@@
				ldY = 1;//@@@@@@
				enY = 1;//@@@@@@
				selX = 2'b11;//@@@@@@
				choosex=1; //@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
				ldX = 1;//@@@@@@
				resX = 1;//@@@@@@
			end	
			
		PLOT_WAIT3: begin     //@@@@@@
				ldCol=1;          //@@@@@@
				  choosex=1;        //@@@@@@
				selCol=0;            //@@@@@@
				col=3'b110;           //@@@@@@@@@@@@@@@@@@@@@@@@@@@
				selY = 2'b01;         //@@@@@@
				//selX = 2'b11;
				ldX = 1;      //@@@@@@
				ldY = 1;        //@@@@@@
				resX = 1;       //@@@@@@
				resY=1;     //@@@@@@
				end
			PLOT3: begin    //@@@@@@
				plot=1;       //@@@@@@
			end
			PLOT_X3: begin   //@@@@@@
				selX=1;       //@@@@@@
				ldX=1;        //@@@@@@
				enX=1;         //@@@@@@
				
			end
			PLOT_Y3: begin   //@@@@@@
				selY = 2'b01;  //@@@@@@
				ldY = 1;       //@@@@@@
				enY = 1;         //@@@@@@
				selX = 2'b11;   //@@@@@@
				choosex=1;       //@@@@@@@@@@@@@@@@@@@@@@@@
				ldX = 1;         //@@@@@@
				resX = 1;         //@@@@@@
			end
			
			PLOT_WAIT2: begin   //@@@@@@
				ldCol=1;         //@@@@@@
				//csel=1;
				selCol=0;        //@@@@@@
				selY = 2'b01;     //@@@@@@
				selX = 2'b11;    //@@@@@@
				col=3'b110;      //@@@@@@@@@@@@@@@@@@@@@@@
				choosex=1;       //@@@@@@@@@@@@@@@@@@@@@@@@@
				ldX = 1;          //@@@@@@
				ldY = 1;         //@@@@@@
				resX = 1;        //@@@@@@
				end
			PLOT2: begin        //@@@@@@
				plot=1;          //@@@@@@
			end
			PLOT_X2: begin //need a plot pause to load the new colour  //@@@@@@
				selX=1;           //@@@@@@
				ldX=1;             //@@@@@@
				enX=1;            //@@@@@@
				ldCol=1;           //@@@@@@
				selCol=0;           //@@@@@@
				col=3'b110;
				
				end
			
			PLOT_Y2: begin         //@@@@@@
				ldCol=1;             //@@@@@@
				selCol=0;              //@@@@@@
				col=3'b110;
				selY = 2'b01;           //@@@@@@
				ldY = 1;                  //@@@@@@
				enY = 1;               //@@@@@@
				choosex=1;               //@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
				selX = 2'b11;            //@@@@@@
				ldX = 1;                //@@@@@@
				resX = 1;                //@@@@@@
				selectX=1;                //@@@@@@
				end
			

WAIT_BLACK: begin	
selX = 2'b10;
selY = 2'b10;
selCol = 1;
ldX = 1;
ldY = 1;
ldCol = 1;
resX = 1;
resY = 1;
end

FILL_BLACK: begin
plot = 1;
end

BLACK_X: begin
selX = 1;
ldX = 1;
enX = 1;
end

BLACK_Y: begin
selY = 1;
ldY = 1;
enY = 1;
selX = 2'b10;
ldX = 1;
resX = 1;
end

WAIT_PLOT: begin
xPosition = trackPlatform;

//xPosition=8'b01000110;
col = 3'b001;
selX = 2'b00;
selY = 2'b00;
selCol = 0;

ldX = 1;
ldY = 1;
ldCol = 1;

resX = 1;
resY = 1;
end

PLOT: begin
plot = 1;
end

PLOT_X: begin
selX = 1;
ldX = 1;
enX = 1;
end

PLOT_Y: begin
selY = 2'b01;
ldY = 1;
enY = 1;
selX = 2'b11;
ldX = 1;
resX = 1;
end

WAIT_BALL: begin
xPosition=posX;
YPosition=posY;
col=3'b111;
selX = 2'b00;
selY = 2'b00;
selCol = 0;
selectY=1;
ldX = 1;
ldY = 1;
ldCol = 1;

resX = 1;
resY = 1;
end

PLOT_BALL: begin
plot=1;
end

PLOT_BALLX: begin
selX=1;
ldX=1;
enX=1;
end

PLOT_BALLY: begin
selectY=1;
selY=2'b01;
ldY=1;
enY=1;
selX=2'b11;
ldX=1;
resX=1;
end

WAIT_END: begin
	if (k2==0) incTracker=1;
	else if (k3==0) decTracker=1;
end
endcase
end


always @ (posedge clock)
begin
if (resetn == 0)
current <= STANDBY;
else
current <= next;
end

always @ (posedge clock) begin
if (newslope==1) begin
case (angle) 
	3'b001: begin
		xslope<=2;
		yslope<=1;
		end
	3'b010: begin
		xslope<=0;
		yslope<=1;
		end
	3'b100: begin
		xslope<=1;
		yslope<=2;
		end
	default: begin
		xslope<=1;
		yslope<=1;
		end
	endcase
	end
	
	if (posY>=114) begin
		xslope<=0;
		yslope<=0;
		end
	
end


//Counters
always @ (posedge clock)
begin
if (resetn == 0) begin
countX <= 0;
countY <= 0;
end
else begin
if (resX == 1)
countX <= 0;
else if (enX == 1)
countX <= countX + 1;

if (resY == 1)
countY <= 0;
else if (enY == 1)
countY <= countY + 1;
end
end

//Timing counter
always @ (posedge clock) begin
if (resetn == 0 | resetCounter == 1)
counter <= 0;
else if (counter < 19'b110010110111001101)
counter <= counter + 1;
else
counter <= 0;
end


//Keep track of platform position
always @ (posedge pulse) begin
if (resetn == 0)
trackPlatform <= 0;
else if (initializeTracker == 1) begin
trackPlatform <= 8'b01000110;

end
else if (incTracker == 1)
trackPlatform <= trackPlatform + 3;
else if (decTracker == 1)
trackPlatform<=trackPlatform-3;

end


always @ (posedge clock)	
	begin
	newslope=0;
		if (resetn == 0) begin
			regDirX = 1;
			regDirY = 1;
			newslope=0;
		//	score<=0;
		end
		else begin
			if (start==1) newslope=1;
			
			if (posX > xPosition && posX < xPosition + 20 && posY >= 107)   //bounce off platform
			begin 
				newslope=1;
	        regDirY = 0; 						
			end   ////
			
			
			if((posX < xPosition || posX > xPosition + 20) && posY >= 7'b1110010)
			begin
		
			regDirX=0;
			regDirY=0;
			newslope = 0;
			end
			
			
//			if (posX>= 8'b10011001 && posY>=7'b0010100 && posY<=7'b0101100) begin
//				regDirX=0;
//				
//				end
			
			if (posX <= 1) regDirX = 1;
			else if (posX >= 155) regDirX = 0;
			
			if (posY <= 3) regDirY = 1;
			else if (posY >= 114) regDirY = 0;
		end
	end
	
	always@(posedge clock) begin
	if (start==1) score=0;
	if (posX == 155 && posY > 20 && posY<  45) score<=score+1;
	if (posY>=114) score<=0;
	end
	
always @ (posedge pulse) 
		begin
				if (start==1) begin
					posX=0;
					posY=0;
					//score=0;
				end
				else begin
				
			//if (posX <= 0) posX=posX+xslope;
			//else if (posX >= 156) posX=posX-xslope;
			
			//if (posY <= 0) posY=posY+yslope;
			//else if (posY >= 114) posY=posY-yslope;
				
				if (regDirX==1) posX=posX+xslope;
				else if (regDirX==0) posX=posX-xslope;
				
				if (regDirY==1) posY=posY+yslope;
				else if (regDirY==0) posY=posY-yslope;
				
				//if (posX > xPosition && posX < xPosition + 20 && posY >= 110) score<=score+1;
				//if (posY>=116) score<=0;
				end
			end
	
endmodule


//Data path
module data(
inX, inY, inCol, selX, selY, selCol,
ldX, ldY, ldCol, resetn, clock, selectX, selectY, choosex, choosey,
outX, outY, outCol
);

input [7:0] inX;
input [6:0] inY;
input [2:0] inCol;
input [1:0] selX, selY;
input selCol, ldX, ldY, ldCol, resetn, clock, selectX, selectY, choosex, choosey;

output [7:0] outX;
output [6:0] outY;
output [2:0] outCol;

reg [7:0] regX;
reg [6:0] regY;
reg [2:0] regCol;

assign outX = regX; //NOT CONST
assign outY = regY; //NOT CONST
assign outCol = regCol;



//regX
always @ (posedge clock) begin
if (resetn == 0)
regX <= 0;
else if (ldX == 1) begin
case (selX)
2'b00: regX <= choosex? 8'b10011001: inX;//should be <= inX
2'b01: regX <= regX + 1;
2'b10: regX <= 0;
2'b11: regX <= selectY? (regX-3) :(choosex? (selectX? (regX-2):(regX - 6)):(regX - 20));
default: regX <= 0;
endcase
end
end

//regY
always @ (posedge clock) begin
if (resetn == 0)
regY <= 0;
else if (ldY == 1) begin
case (selY)
2'b00: regY <= selectY? inY: (choosey? 7'b0010100 : 7'b1110000);//should be <= inY
2'b01: regY <= regY + 1;
2'b10: regY <= 0;
2'b11: regY <= regY - 3;
default: regY <= 0;
endcase
end
end

//regCol
always @ (posedge clock) begin
if (resetn == 0)
regCol <= 3'b000;
else if (ldCol == 1) begin
case (selCol)
1'b0: regCol <= inCol;
1'b1: regCol <= 3'b000;
default: regCol <= 3'b000;
endcase
end
end

endmodule

module hex_decoder(hex_digit, segments);
    input [3:0] hex_digit;
    output reg [6:0] segments;
   
    always @(*)
        case (hex_digit)
            4'h0: segments = 7'b100_0000;
            4'h1: segments = 7'b111_1001;
            4'h2: segments = 7'b010_0100;
            4'h3: segments = 7'b011_0000;
            4'h4: segments = 7'b001_1001;
            4'h5: segments = 7'b001_0010;
            4'h6: segments = 7'b000_0010;
            4'h7: segments = 7'b111_1000;
            4'h8: segments = 7'b000_0000;
            4'h9: segments = 7'b001_1000;
            4'hA: segments = 7'b000_1000;
            4'hB: segments = 7'b000_0011;
            4'hC: segments = 7'b100_0110;
            4'hD: segments = 7'b010_0001;
            4'hE: segments = 7'b000_0110;
            4'hF: segments = 7'b000_1110;   
            default: segments = 7'h7f;
        endcase
endmodule
