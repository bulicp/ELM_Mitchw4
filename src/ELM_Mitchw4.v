
// Calculates P = X*Y = X1*Y*2^14 + X0*Y1*2^14 + X0*Y0
// X1 = x[15:13], X0 = x[13:0]
// Y1 = y[15:13], Y0 = y[13:0]

module ELM_Mitchw4(
    input [15:0] x,
    input [15:0] y,
    output [31:0] p
    );
    
    wire [1:0] sign_factor;
    wire [16:0] PP_2;
    wire [14:0] PP_1;
    wire [27:0] PP_0;
    
// Calculates PP_2 = Y*X1
    PP_2_gen High(
        .x1(x[15:13]),
        .y(y),
        .sign_factor(sign_factor[1]),
        .PP(PP_2)
        );
// Calculates PP_1 = Y1*X0    
    PP_1_gen Middle(
        .x(x[13:0]),
        .y1(y[15:13]),
        .sign_factor(sign_factor[0]),
        .PP(PP_1)
        );
// Calculates PP_0 = X0*YO
    PP_0_gen Low(
        .x0(x[13:0]),
        .y0(y[13:0]),
        .PP(PP_0)
        );

// Partial product addition 

    PP_add Final(
        .sign_factor(sign_factor),
        .PP_2(PP_2),
        .PP_1(PP_1),
        .PP_0(PP_0),
        .p(p)
        );
        
endmodule

// Calculates PP_2 = Y*X1
module PP_2_gen(
    input [2:0] x1,
    input [15:0] y,
    output sign_factor,
    output [16:0] PP
    );
    
    // encode 
    wire one, two, sign;
    
    code encode_block(
        .one(one),
        .two(two),
        .sign(sign),
        .y2(x1[2]),
        .y1(x1[1]),
        .y0(x1[0])
        );
        
    // generation of PP
    wire [16:0] tmp1_pp; 
    assign tmp1_pp = {y[15],y}; // This variable is introduced because pp has 17 bits
    
    wire [17:0] out1;
    assign out1[0] = sign;
    
    genvar i;
    generate
        for ( i = 0; i < 17; i = i+1 )
            begin : pp_rad4_first 
            product pp_pr(tmp1_pp[i],out1[i],one,two,sign,PP[i],out1[i+1]);
            end
    endgenerate
    
    //sign factor generate
    sgn_gen sign_gen(one,two,sign,sign_factor);
       

endmodule

// Calculates PP_1 = Y1*X0
module PP_1_gen(
    input [13:0] x,
    input [2:0] y1,
    output sign_factor,
    output [14:0] PP
    );
    
    // encode 
    wire one, two, sign;
    
    code encode_block(
        .one(one),
        .two(two),
        .sign(sign),
        .y2(y1[2]),
        .y1(y1[1]),
        .y0(y1[0])
        );
        
    // generation of PP
    wire [14:0] tmp1_pp; 
    assign tmp1_pp = {x[13],x}; // This variable is introduced because pp has 17 bits
    
    wire [15:0] out1;
    assign out1[0] = sign;
    
    genvar i;
    generate
        for ( i = 0; i < 15; i = i+1 )
            begin : pp_rad4_first 
            product pp_pr(tmp1_pp[i],out1[i],one,two,sign,PP[i],out1[i+1]);
            end
    endgenerate
    
    //sign factor generate
    sgn_gen sign_gen(one,two,sign,sign_factor);
       

endmodule   

//encoding


module code(one,two,sign,y2,y1,y0);  
	input y2,y1,y0;                     
	output one,two,sign;                
	wire [1:0]k;                        
	xor x1(one,y0,y1);                  
	xor x2(k[1],y2,y1);                 
	not n1(k[0],one);                   
	and a1(two,k[0],k[1]);              
	assign sign=y2;                     
endmodule       
    
//generation of inner products

module product(x1,x0,one,two,sign,p,i);
	input x1,x0,sign,one,two;
	output p,i;
	wire [1:0] k;
	xor xo1(i,x1,sign);
	and a1(k[1],i,one);
	and a0(k[0],x0,two);
	or o1(p,k[1],k[0]);
endmodule

//sign_factor generate

module sgn_gen(one,two,sign,sign_factor);
    input sign,one,two;
    output sign_factor;
    wire k;
    or o1(k,one,two);
    and a1(sign_factor,sign,k);
endmodule



// Calculates PP_0 = Y0*X0    
module PP_0_gen(
    input signed [13:0] x0,
    input signed [13:0] y0,
    output signed [27:0] PP
    );
    
    // X branch 

    // First complement 
    wire [13:0] x0_abs;
    assign x0_abs = x0 ^ {14{x0[13]}};
    
    // LOD
    wire [13:0] k_x0;
    wire zero_x0;
    wire [13:0] x0_abs2;
	assign x0_abs2 = x0_abs;

    LOD14 lod_x0(
        .data_i(x0_abs),
        .zero_o(zero_x0),
        .data_o(k_x0));
        
    // PriorityEncoder
    wire [3:0] k_x0_enc;
    
    PriorityEncoder_14v2 PE_x0(
        .data_i(k_x0),
        .code_o(k_x0_enc));
        
    // LBarrel 
    wire [2:0] x_shift;
    
    LBarrel Lshift_x0(
        .data_i(x0_abs2),
        .shift_i(k_x0),
        .data_o(x_shift));
        
    // Y branch 
    
    // First complement 
    wire [13:0] y0_abs;
    assign y0_abs = y0 ^ {14{y0[13]}};
    
    // LOD
    wire [13:0] k_y0;
    wire zero_y0;
    
    LOD14 lod_y0(
        .data_i(y0_abs),
        .zero_o(zero_y0),
        .data_o(k_y0));
      
	wire [13:0] y0_abs2;
	assign y0_abs2 = y0_abs;  
  
    // PriorityEncoder
    wire [3:0] k_y0_enc;
    
    PriorityEncoder_14v2 PE_y0(
        .data_i(k_y0),
        .code_o(k_y0_enc));
        
    // LBarrel 
    wire [2:0] y_shift;
    
    LBarrel Lshift_y0(
        .data_i(y0_abs2),
        .shift_i(k_y0),
        .data_o(y_shift));
        
    
    // Addition 
    wire [7:0] x_log;
    wire [7:0] y_log;
    wire [7:0] p_log;
    
    assign x_log = {1'b0,k_x0_enc,x_shift};
    assign y_log = {1'b0,k_y0_enc,y_shift};

    
    assign p_log = x_log + y_log;
    
    // Antilogarithm 
    
    // L1 barell shifter 
    wire [19:0] p_l1b;
    wire [3:0] l1_input;
    
    assign l1_input = {1'b1,p_log[2:0]};
   
    L1Barrel L1shift_plog(
        .data_i(l1_input),
        .shift_i(p_log[6:3]),
        .data_o(p_l1b));

   
    // Low part 
    // Low part of product 
    wire [12:0] p_low;
    wire not_k_l5 = ~p_log[7];
    
    assign p_low = p_l1b[15:3] & {13{not_k_l5}};
    
    // Medium part of product 
    
    wire [3:0] p_med;
    
    assign p_med = p_log[7] ? p_l1b[3:0] : p_l1b[19:16];
    
    // High part of product 
    
    wire [10:0] p_high;

    assign p_high = p_l1b[14:4] & {11{p_log[7]}};
    // Final product
    
    wire [27:0] PP_abs;
    assign PP_abs = {p_high,p_med,p_low};
    
    // Sign conversion 
    wire p_sign;
    wire [27:0] PP_temp;
    
    
    assign p_sign = x0[13] ^ y0[13];
    assign PP_temp = PP_abs ^ {28{p_sign}};
    
    //Zero mux0
    wire notZeroA, notZeroB, notZeroD;
    assign notZeroA = ~zero_x0 | x0[13] | x0[0];
    assign notZeroB = ~zero_y0 | y0[13] | y0[0];
    assign notZeroD = notZeroA & notZeroB;
    
    
    assign PP = notZeroD? PP_temp : 28'b0;
    
endmodule

module LOD14(
    input [13:0] data_i,
    output zero_o,
    output [13:0] data_o
    );
	
	 wire [13:0] z;
	 wire [3:0] zdet;
	 wire [3:0] select;
	 //*****************************************
	 // Zero detection logic:
	 //*****************************************
	 assign zdet[3] = |(data_i[13:12]);
	 assign zdet[2] = |(data_i[11:8]);
	 assign zdet[1] = |(data_i[7:4]);
	 assign zdet[0] = |(data_i[3:0]);
	 assign zero_o = ~( zdet[0]  | zdet[1] );
	

	 //*****************************************
	 // LODs:
	 //*****************************************
	 LOD4 lod4_1 (
		.data_i(data_i[3:0]), 
		.data_o(z[3:0])
	 );
	 
	  LOD4 lod4_2 (
            .data_i(data_i[7:4]), 
            .data_o(z[7:4])
         );
         
      LOD4 lod4_3 (
           .data_i(data_i[11:8]), 
           .data_o(z[11:8])
        );
	 LOD2 lod2_4 (
                .data_i(data_i[13:12]), 
                .data_o(z[13:12])
             );
	 
	 	LOD4 lod4_5 (
                .data_i(zdet), 
                .data_o(select)
             );
	 
	 //*****************************************
	 // Multiplexers :
	 //*****************************************
	 
	Muxes2in1Array2 Inst_MUX214_3 (
         .data_i(z[13:12]), 
         .select_i(select[3]), 
         .data_o(data_o[13:12])
     );
	 
	Muxes2in1Array4 Inst_MUX214_2 (
        .data_i(z[11:8]), 
        .select_i(select[2]), 
        .data_o(data_o[11:8])
    );

	 
	 Muxes2in1Array4 Inst_MUX214_1 (
        .data_i(z[7:4]), 
        .select_i(select[1]), 
        .data_o(data_o[7:4])
    );

	 Muxes2in1Array4 Inst_MUX214_0 (
		.data_i(z[3:0]), 
		.select_i(select[0]), 
		.data_o(data_o[3:0])
    );

endmodule

module LOD4(
    input [3:0] data_i,
    output [3:0] data_o
    );
	 
	 
	 wire mux0;
	 wire mux1;
	 wire mux2;
	 
	 // multiplexers:
	 assign mux2 = (data_i[3]==1) ? 1'b0 : 1'b1;
	 assign mux1 = (data_i[2]==1) ? 1'b0 : mux2;
	 assign mux0 = (data_i[1]==1) ? 1'b0 : mux1;
	 
	 //gates and IO assignments:
	 assign data_o[3] = data_i[3];
	 assign data_o[2] =(mux2 & data_i[2]);
	 assign data_o[1] =(mux1 & data_i[1]);
	 assign data_o[0] =(mux0 & data_i[0]);
	 

endmodule

module LOD2(
    input [1:0] data_i,
    output [1:0] data_o
    );
	 
	 
	 //gates and IO assignments:
	 assign data_o[1] = data_i[1];
	 assign data_o[0] =(~data_i[1] & data_i[0]);
	 

endmodule

module Muxes2in1Array4(
    input [3:0] data_i,
    input select_i,
    output [3:0] data_o
    );

	assign data_o[3] = select_i ? data_i[3] : 1'b0;
	assign data_o[2] = select_i ? data_i[2] : 1'b0;
	assign data_o[1] = select_i ? data_i[1] : 1'b0;
	assign data_o[0] = select_i ? data_i[0] : 1'b0;
	
endmodule

module Muxes2in1Array2(
    input [1:0] data_i,
    input select_i,
    output [1:0] data_o
    );
    
	assign data_o[1] = select_i ? data_i[1] : 1'b0;
	assign data_o[0] = select_i ? data_i[0] : 1'b0;
	
endmodule

module PriorityEncoder_14(
    input [13:0] data_i,
    output reg [3:0] code_o
    );

	  always @*
		case (data_i)
	     14'b00000000000001 : code_o = 4'b0000;
         14'b00000000000010 : code_o = 4'b0001;
         14'b00000000000100 : code_o = 4'b0010;
         14'b00000000001000 : code_o = 4'b0011;
         14'b00000000010000 : code_o = 4'b0100;
         14'b00000000100000 : code_o = 4'b0101;
         14'b00000001000000 : code_o = 4'b0110;
         14'b00000010000000 : code_o = 4'b0111;
         14'b00000100000000 : code_o = 4'b1000;
         14'b00001000000000 : code_o = 4'b1001;
         14'b00010000000000 : code_o = 4'b1010;
         14'b00100000000000 : code_o = 4'b1011;
        // 14'b01000000000000 : code_o = 4'b1100;
		 default  : code_o = 4'b1100;
		endcase		
endmodule


module PriorityEncoder_14v2(
    input [13:0] data_i,
    output [3:0] code_o
    );
	
	wire tmp10, tmp20,tmp30,tmp40;

	assign tmp10 = ~(~(data_i[1] | data_i[3]) & ~data_i[5]);
	assign tmp20 = ~(~(data_i[7] | data_i[9]) & ~data_i[11]);
	assign code_o[0] = tmp10 | tmp20;

	assign tmp30 = ~(~(data_i[2] | data_i[3]) & ~data_i[6]);
	assign tmp40 = ~(~(data_i[7] | data_i[10]) & ~data_i[11]);
	assign code_o[1] = tmp30 | tmp40;

	wire [1:0] tmp50, tmp60;
	wire tmp70, tmp80;
	assign tmp50 = ~ (data_i[5:4] | data_i[7:6]);
	assign tmp70 = ~&(tmp50);
	assign code_o[2] = tmp70 | data_i[12];

	assign tmp60 = ~ (data_i[9:8] | data_i[11:10]);
	assign tmp80 = ~&(tmp60);
	assign code_o[3] = tmp80 | data_i[12];

endmodule

module LBarrel(
    input [13:0] data_i,
    input [13:0] shift_i,
    output [2:0] data_o);
    
    
    
    //assign data_o[2] = |(data_i[11:0] & shift_i[12:1]);
	wire [11:0] tmp1_l; //a,b
	wire [5:0] tmp2_l;	// c
	wire [2:0] tmp3_l;	//d
	assign tmp1_l = ~(data_i[11:0] & shift_i[12:1]);
	assign tmp2_l = ~(tmp1_l[11:6] & tmp1_l[5:0]);	
    assign tmp3_l = ~(tmp2_l[5:3] | tmp2_l[2:0]);
	assign data_o[2] = 	~&tmp3_l;

	//assign data_o[1] = |(data_i[10:0] & shift_i[12:2]);
	wire [11:0] tmp1_r;
	wire [5:0] tmp2_r;
	wire [2:0] tmp3_r;
	assign tmp1_r[11] = 1'b1;
	assign tmp1_r[10:0] = ~(data_i[10:0] & shift_i[12:2]);
	assign tmp2_r = ~(tmp1_r[11:6] & tmp1_r[5:0]);	
    assign tmp3_r = ~(tmp2_r[5:3] | tmp2_r[2:0]);
	assign data_o[1] = 	~&tmp3_r;
	
	
    //assign data_o[0] = |(data_i[9:0] & shift_i[12:3]);
	wire [11:0] tmp1_u;
	wire [5:0] tmp2_u;
	wire [2:0] tmp3_u;
	assign tmp1_u[11] = 1'b1;
	assign tmp1_u[10] = 1'b1;
	assign tmp1_u[9:0] = ~(data_i[9:0] & shift_i[12:3]);
	assign tmp2_u = ~(tmp1_u[11:6] & tmp1_u[5:0]);	
    assign tmp3_u = ~(tmp2_u[5:3] | tmp2_u[2:0]);
	assign data_o[0] = 	~&tmp3_u;
  
endmodule

module L1Barrel(
    input [3:0] data_i,
    input [3:0] shift_i,
    output reg [19:0] data_o);
    always @*
        case (shift_i)
           4'b0000: data_o = data_i;
           4'b0001: data_o = data_i << 1;
           4'b0010: data_o = data_i << 2;
           4'b0011: data_o = data_i << 3;
           4'b0100: data_o = data_i << 4;
           4'b0101: data_o = data_i << 5;
           4'b0110: data_o = data_i << 6;
           4'b0111: data_o = data_i << 7;
           4'b1000: data_o = data_i << 8;
           4'b1001: data_o = data_i << 9;
           4'b1010: data_o = data_i << 10;
           4'b1011: data_o = data_i << 11;
           4'b1100: data_o = data_i << 12;
           4'b1101: data_o = data_i << 13;
           4'b1110: data_o = data_i << 14;
           default: data_o = data_i << 15;
        endcase
endmodule

module RBarell(
    input data_i,
    input shift_i,
    output [1:0] data_o);

    assign data_o[1] = ~shift_i;
    assign data_o[0] = shift_i | data_i;

endmodule

module PP_add(
    input [1:0] sign_factor,
    input [16:0] PP_2,
    input [14:0] PP_1,
    input [27:0] PP_0,
    output [31:0] p
    );
    
    
    // generate negative MSBs
    wire [2:0] E_MSB;
    assign E_MSB[0] = ~ PP_0[27];
    assign E_MSB[1] = ~ PP_1[14];
    assign E_MSB[2] = ~ PP_2[16];
    
    

    // Reduction 

    // First reduction

    wire [15:0] sum00_FA;
    wire [15:0] carry00_FA;


    wire [15:0] tmp001_FA;
    wire [15:0] tmp002_FA;
    wire [15:0] tmp003_FA;

    assign tmp001_FA = {E_MSB[0],PP_0[27],PP_0[27:14]};
    assign tmp002_FA = {E_MSB[1],PP_1};
    assign tmp003_FA = {PP_2[15:0]};


    genvar i001;
    generate
        for (i001 = 0; i001 < 16; i001 = i001 + 1)
            begin : pp_fad00
            FAd pp_fad(tmp001_FA[i001],tmp002_FA[i001], tmp003_FA[i001], carry00_FA[i001],sum00_FA[i001]);
            end
    endgenerate
    
    wire sum00_HA, carry00_HA;
    assign carry00_HA = PP_2[16]; // E_MSB[2]^1 = PP_2[16]
    assign sum00_HA = E_MSB[2]; // E_MSB[2]^1 = E_MSB[2]
    
    
    // Final addition
    wire [31:0] tmp1_add;
    wire [31:0] tmp2_add;
    
    assign tmp1_add = {E_MSB[2],sum00_HA,sum00_FA,PP_0[13:0]};
    assign tmp2_add = {carry00_HA,carry00_FA,sign_factor[1],{14{sign_factor[0]}}};
    
    assign p = tmp1_add + tmp2_add;
    
endmodule


module FAd(a,b,c,cy,sm);
	input a,b,c;
	output cy,sm;
	wire x,y,z;
	xor x1(x,a,b);
	xor x2(sm,x,c);
	and a1(y,a,b);
	and a2(z,x,c);
	or o1(cy,y,z);
endmodule 

