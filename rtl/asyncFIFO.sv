`timescale 1ns/1ps

module asyncFIFO
#(
    parameter WIDTH = 32
)
(
input wire i_wr,
input wire i_rd,
input wire [WIDTH - 1:0]i_data,
input wire wr_clk,
input wire rd_clk,
input wire rst,

output logic [WIDTH - 1:0]o_data,
output logic full,
output logic empty
);

logic [WIDTH - 1:0]ram[7:0]; //memory used

//these will increment using gray encoded counting
logic [3:0] wpointer, rpointer; //extra bit for full/empty logic, 3 bit address

initial wpointer = 0;
initial rpointer = 0;

//converting binary to gray
wire [3:0]wpointergraynext;
wire [3:0]rpointergraynext;

logic [3:0]wpointergray;
logic [3:0]rpointergray;


assign wpointergraynext = wpointer ^ (wpointer >> 1);
assign rpointergraynext = rpointer ^ (rpointer >> 1);


//sychronized gray pointers
logic [3:0]wpointerg1, wpointerg2;
logic [3:0]rpointerg1, rpointerg2;

//write stuff and synchronizing reads
always @(posedge wr_clk or negedge rst)
begin
    if(!rst) //negedge reset
    begin
        wpointer <= 0;
        wpointergray <= 0;
        rpointerg1 <= 0;
        rpointerg2 <= 0;
        wpointergray <= 0;
    end
    else
    begin
        wpointergray <= wpointergraynext;
        rpointerg1 <= rpointergray; //2 flip-flop syncrhonizer
        rpointerg2 <= rpointerg1; 
        if(i_wr && !full)//writing
        begin
            ram[wpointer[2:0]] <= i_data; //write data
            wpointer <= wpointer + 1; //increment addr
        end
    end
end

//read stuff and sychcronizing writes
always @(posedge rd_clk or negedge rst)
begin
    if(!rst)
    begin
        o_data <= 0;
        wpointerg1 <= 0;
        wpointerg2 <= 0;
        rpointergray <= 0;
        rpointer <= 0;
    end
    else
    begin
        //other 2 flip flop sychronizer
        rpointergray <= rpointergraynext;
        wpointerg1 <= wpointergray;
        wpointerg2 <= wpointerg1;

        if(i_rd && !empty)
        begin
            o_data <= ram[rpointer[2:0]];
            rpointer <= rpointer + 1;
        end
    end
end
    //gray to binary convertor from vlsiverify
  //assign binary[0] = gray[3] ^ gray[2] ^ gray[1] ^ gray[0];
  //assign binary[1] = gray[3] ^ gray[2] ^ gray[1];
  //assign binary[2] = gray[3] ^ gray[2];
  //assign binary[3] = gray[3];
  //read gray to binary and write gray to binary
wire [3:0]rgtob;
wire [3:0]wgtob;

//binary read pointer in the write domain
assign rgtob[0] = rpointerg2[3] ^ rpointerg2[2] ^ rpointerg2[1] ^ rpointerg2[0];
assign rgtob[1] = rpointerg2[3] ^ rpointerg2[2] ^ rpointerg2[1];
assign rgtob[2] = rpointerg2[3] ^ rpointerg2[2];
assign rgtob[3] = rpointerg2[3];

//binary write pointer in the read domain
assign wgtob[0] = wpointerg2[3] ^ wpointerg2[2] ^ wpointerg2[1] ^ wpointerg2[0];
assign wgtob[1] = wpointerg2[3] ^ wpointerg2[2] ^ wpointerg2[1];
assign wgtob[2] = wpointerg2[3] ^ wpointerg2[2];
assign wgtob[3] = wpointerg2[3];

assign full = (wpointer[3] != rgtob[3]) && (wpointer[2:0] == rgtob[2:0]);
assign empty = (wgtob == rpointer);

endmodule