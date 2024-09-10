`include "alu.v"
module tb;
wire [31:0]result;
wire BT;
reg [31:0]i1,i2,imms,immi;
reg [1:0]irmux;
reg [3:0]cnt_in;

ALU DUT(result,BT,i1,i2,imms,immi,irmux,cnt_in);

initial begin
    $monitor("t=%g A=%d rs2=%d imms=%d immi=%d irmux=%b op_code=%b result=%d BT=%b",$time,i1,i2,imms,immi,irmux,cnt_in,result,BT);
    i1=32'd687; i2=32'd1684168; cnt_in=4'b1111; immi=32'd12; imms=32'd12;
    #5 cnt_in=4'd2; irmux=2'd0;
    #5 cnt_in=4'd3; irmux=2'd1;
    #5 cnt_in=4'd4; irmux=2'd2;
    #5 cnt_in=4'd5;
    //repeat(5) #5 cnt_in=($urandom)%19;
    #5 $finish;
end
endmodule
