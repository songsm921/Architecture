# 2022 Computer Architecture Homework 1 
## 컴퓨터공학과 20180085 송수민 
## Question 1.
- Answer:
 <br>
 ```
    sub x30, x28, x29 // i-j index 값을 계산한다. GPR[x30]을 사용한 이유는 조사 결과 temporal value를 담는 register = x30 존재
    slli x30, x30, 2 // 32bit system을 가정하므로 single word allignment를 위해 4를 곱한다. 4*(i-j)
    add x30, x10, x30 // load하기 전에 A[i-j] 주소 값을 계산한다. Address = A + 4*(i-j)
    lw x30, (x30) // 위에서 계산 주소값의 value를 x30에 load한다.
    sw x30, 32(x11) // x30에 들어있는 value를 B[8]에 store한다. 4byte * 8th = 32 -> 32(x11) <B+32> .
```
## Question 2.
- Answer:
 <br>
```cpp
    A[2] = &A;
    f = &A + &A;
```
> |----|----|----|----|<br>
> A   A[1] A[2] <br>
> 1. x30 = A[2]의 주소값을 저장 <br>
> 2. x31 = A[0]의 주소값을 저장 <br>
> 3. A[2]에 &A[0]의 주소값을 저장 (첫번째 코드 -> A[2] = &A;) <br>
> 4. x30에 x30이 가리키고 있던 값을 저장 -> (x30 -> A[2] = &A) <br>
> 5. x5 = x30 + x31 -> f = &A + &A;
## Question 3.
- Answer:
 <br>
```
   a. S type 
   b. 0x25F2023
```
> sw instruction structure <br>
> imm[11:5] 7bits / src 5bits / base 5bits / func3 3bits / imm[4:0] 5bits / opcode 7bits / <br>
> [0000001] / [00101] / [11110] / [010] / [00000] / [0100011] <br>
> 위의 이진수 값은 PPT & Textbook을 참고하였다. 4-bit씩 끊어서 16진수로 읽으면 위의 답과 같다.
## Question 4.
- Answer:
 <br>
```
   a. R type 
   b. sub x6, x7, x5 
   c. 0100 0000 0101 0011 1000 0011 0011 0011
```
> 문제와 부합하는 형태를 가지는 instruction type은 R type이다 (PPT 참고) <br>
> funct7[11:5] 7bits / rs2 5bits / rs1 5bits / funct3 3bits / rd 5bits / opcode 7bits / <br>
> [0100000] / [00101] / [00111] / [000] / [00110] / [0110011] <br>
> 문제에서 부여한 조건을 이진수로 옮기면 위와 같다. sub로 판별한 기준은 funct7에서 sub / sra로 범위를 줄이고, funct3을 통해 sub로 판별하였다.
## Question 5.
- Answer:
 <br>
```
    xori x5, x6, -1
```
> -1을 two's complement로 나타내기 위해 1을 1의 보수를 취하고 1를 더해준다. <br>
> 00000...1 -> 1111111....0 + 1 -> 11111....111111 <br>
> x6에 있는 bit들과 xor 연산을 취해주면 모두 1과 연산을 하므로 0 xor 1 = 1 / 1 xor 1 = 0이므로 not 연산과 동일한 결과를 낼 수 있다.
## Question 6.
- Answer:
 <br>
```
    lw x6, 0(x17)
    slli x6, x6, 4
```
> 다음과 같은 순서로 처리 할 수 있다. <br>
> 1. C[0]를 A에 load.
> 2. A를 shift operation 실시 <br>
- 위와 같이 처리하면 temporal value를 담을 register를 절약하고, temporal value를 담는 과정을 생략할 수 있어 효율적이다.
## Question 7.
- Answer:
 <br>
```
    a. 0x11
    b. 0x44
```
- 어셈블리어의 동작은 다음과 같다. 
- 1. 가장 앞에 content를 load한다.
- 2. 가장 앞에서 두번째 뒤의 칸에 store한다.
> [Big endian] MSB가 가장 낮은 address byte로 넣어진다. <br>
> 32bit system을 가정하므로 한 칸을 single word라 하자. 그러면 16진수 기준 두개의 글자가 들어간다. <br>
> 11 / 22 / 33 / 44 -> 11 / 22 / 11 / 44 -> 0x11 <br>
> [Little endian] LSB가 가장 낮은 address byte로 넣어진다. <br>
> 44 / 33 / 22 / 11 -> 44 / 33 / 44 / 11 -> 0x44
