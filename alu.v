module ALU(
    output reg [31:0]ALU_out,
    output BT, // Branch Target
    input [31:0]A,rs2, // RS1,RS2
    input [31:0]immS,immI,
    input [1:0]IRMUX, // taken from controller
    input [3:0]op_code); // From instruction decoder

    wire [31:0]add_sub,mult_HB,mult_LB,div_R,div_Q;
    wire signed [31:0]A_Sign=A;
    wire signed [31:0]B_Sign=B;
    reg [31:0]B;
    reg c_in;
    wire mult_rst=(((~op_code[3])&(~op_code[2])&op_code[1]&(~op_code[0])) || ((~op_code[3])&(~op_code[2])&op_code[1]&op_code[0]));
    wire div_rst=(((~op_code[3])&op_code[2]&(~op_code[1])&(~op_code[0])) || ((~op_code[3])&op_code[2]&(~op_code[1])&op_code[0]));
    assign BT=ALU_out[0];

    carry_look_ahead ADD(add_sub,A,B,c_in);
    Booths_mult MULT({mult_HB,mult_LB},mult_rst,A,B);
    non_rest_div DIV(div_R,div_Q,A,B,div_rst);

    // logic to select among immediate values and rs2
    always@(*) begin
        case (IRMUX)
            2'b00 : B=immS;
            2'b01 : B=immI;
            2'b10 : B=rs2;
            default: B=rs2;
        endcase
    end

    always@(*) begin
        ALU_out=32'd0; // default assignment 
        c_in=1'b0;     // to avoid latch
        case (op_code)
            4'b0000 : begin
                c_in = 1'b0;
                ALU_out = add_sub; // Addition
            end 
            4'b0001 : begin
                c_in = 1'b1;
                ALU_out = add_sub; // Subtraction
            end
            4'b0010 : ALU_out = mult_HB; // Upper half bits of multiplication result.
            4'b0011 : ALU_out = mult_LB; // Lower half bits of multiplication result.
            4'b0100 : ALU_out = div_Q; // Quotient 
            4'b0101 : ALU_out = div_R; // Reminder
            4'b0110 : ALU_out = A & B; // AND
            4'b0111 : ALU_out = A | B; // OR
            4'b1000 : ALU_out = A ^ B; // XOR
            4'b1001 : ALU_out = A << B; // Left Shift
            4'b1010 : ALU_out = A >> B; // Right shift Logical
            4'b1011 : ALU_out = A >>> B_Sign; // Right Shift Arithmetic
            4'b1100 : begin // Set Less Than Signed
                ALU_out[31:1] = 31'd0;
                ALU_out[0] = (A_Sign<B_Sign)?1'b1:1'b0;
            end 
            4'b1101 : begin // Set Less Than Unsigned  
                ALU_out[31:1] = 31'd0;
                ALU_out[0] = (A<B)?1'b1:1'b0;
            end
            4'b1110 : begin // Equal or not
                ALU_out[31:1] = 31'd0;
                ALU_out[0] = (A==B)?1'b1:1'b0;
            end
            default :;
        endcase
    end
endmodule

// Carry Look Ahead Adder/Subtractor
module carry_look_ahead(
    output reg [31:0]result,
    input [31:0]a,b,
    input cin);

    reg [31:0]p,g,r,y,c_o,B,temp1,temp2;

    integer i,j,k;
    always@(*) begin
        if(cin) begin
            if(a>b) begin
                temp1=a;
                temp2=b;
            end
            else begin
                temp1=b;
                temp2=a;
            end
        end
        else begin
            temp1=a;
            temp2=b;
        end

        for(k=0;k<32;k=k+1) begin
            // 2's complement of b.
            B[k]=temp2[k]^cin; // cin = 0 --> addition  cin = 1 --> subtraction
            // carry generate and propogation generate.
            p[k]=temp1[k]^B[k];
            g[k]=temp1[k]&B[k];
        end
        r={g[30:0],cin};
        // Logic for carry generator.
        for(k=0;k<=31;k=k+1) begin
            c_o[k]=g[k];
            for(i=0;i<=k;i=i+1) begin
                y[i]=r[i];
                for(j=i;j<=k;j=j+1) begin
                    y[i]=y[i]&p[j];
                end
                c_o[k]=c_o[k]|y[i];
            end
        end
        // iteration for sum signal.
        result[0]=p[0]^cin;
        for(k=1;k<32;k=k+1) result[k]=p[k]^c_o[k-1];
    end
endmodule

// Booth's Algorithm Multiplier
module Booths_mult(
    output reg [63:0]mult,
  input enb,
  input [31:0]M,Q);  // M-->Multiplicand Q-->Multiplier
  
  reg [5:0]cnt1,cnt2;
  reg [63:0]temp1,temp2;
  reg [31:0]m;
  reg [32:0]q;
  integer i;

  always@(*) m=(~M)+1'b1;

  always@(*) begin
    q={1'b0,{Q}};
    temp1=64'd0;
    mult=64'd0;
    if(!enb) begin
      {cnt1,cnt2}=0;
      {temp1,temp2}=0;
    end
    else begin
      for(i=32;i>=0;i=i-1) begin
        if(i==0) begin
          if((q[i]^1'b0)==1) temp1={{32{m[31]}},m};
          else temp1=temp1;
          temp2=temp2+temp1;
          {cnt1,cnt2}=0;
        end
        else begin
          if((q[i]^q[i-1])==1'b1) begin
            cnt2=i;
            cnt1=cnt1 + 1;
            if( (cnt1>0) && (cnt1%2==1)) temp1={32'b00000000,M}<<cnt2;
            else if( (cnt1>0) && (cnt1%2==0)) temp1={{32{m[31]}},m}<<cnt2;
            temp2=temp2+temp1;
          end
          else begin
            cnt1=cnt1;
            cnt2=cnt2;
            temp2=temp2;
          end
        end
        if((Q[0]==1'b1) && (i==0)) mult=temp2;
        else if((Q[0]==1'b0) && (i==1)) mult=temp2;
      end
    end
  end
endmodule

// Non-Restoring Division Algorithm
module non_rest_div(
    output reg [31:0]R,Q,
    input [31:0]a,b, // a--> Dividend b--> Divisor
    input rst);

    reg [32:0]acc;  // Accumulator
    reg [31:0]reg1,reg2,B,q;
    integer n;

    always@(*) begin
        if(a>b) begin
            reg1=a;
            reg2=b;
        end
        else begin
            reg1=b;
            reg2=a;
        end
        B=(~reg2)+1'b1;
        if(!rst) begin
            acc=0;
            q=reg1;
            {R,Q}=64'bz;
        end
        else begin
            for(n=32;n>=0;n=n-1) begin
                if(n!=0) begin
                    {acc,q}={acc,q}<<1;
                    if(acc[32]==0) acc=acc+{B[31],B};
                    else acc=acc+{1'b0,reg2};
                    if(acc[32]==0) q[0]=1'b1;
                    else q[0]=1'b0;
                end
                else begin
                    if(acc[32]==1) acc=acc+{1'b0,reg2};
                    else acc=acc;
                    R=acc[31:0];
                    Q=q;
                end
            end
        end
    end
endmodule
