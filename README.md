# Arithmetic-Logic-Unit
This is one of the most important component of any processor that performs arithmetic and logic operations based on the instruction given. To make this ALU time efficient and area efficient, the ALU has been designed using the following circuits:

a) Carry Look Ahead Adder : This circuit is time efficient for word sizes like 32-bits. This adder is more time efficient that Ripple Carry adder as the output carry in every stage is dependant only on input carry. This circuit is used to carry out both addition and subtraction. When input carry is given logic-0 the CLA performs addition and when input carry is logic-1 then the CLA performs subtraction.

b) Booth's Multiplier : Booth's multiplication algorithm is used to implement binary multiplication with high time efficiency by skipping addition when zeros appear in multiplicand and it performs very less number of additions which also results in area efficiency.

c) Non-restoring division algorithm : This algorithm is used to implement time efficient and area efficient binary divider.

Other logic operations like logic AND, OR, XOR, NOT, shift left & right, equal or not equal, greater that or less than etc.
