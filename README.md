# CORDIC
1 Introduction
The CORDIC (COordinate Rotation DIgital Computer) algorithm is an iterative technique
used to compute trigonometric, hyperbolic, and other transcendental functions using only shift
and-add operations, making it highly suitable for hardware implementation where multipliers
are expensive or unavailable. This project implements a fully pipelined, 16-stage CORDIC
processor in Verilog HDL, operating in two modes:
Rotation Mode: Given an input angle, computes its sine and cosine values.
Vectoring Mode: Given a vector (x,y), computes its magnitude and phase angle.
2 CORDIC Algorithm: Theoretical Background
2.1 Basic Principle
The CORDIC algorithm rotates a vector (xi,yi) by a sequence of progressively smaller angles
θi = tan−1(2−i), such that each rotation can be implemented using only a binary shift and an
addition/subtraction. The iterative equations are:
xi+1 = xi −di ·yi ·2−i
yi+1 = yi +di ·xi ·2−i
zi+1 = zi −di ·θi
(1)
(2)
(3)
where di = ±1 is the direction of rotation at iteration i, and θi = tan−1(2−i) is pre-computed
and stored in a lookup table (LUT).
2.2 Rotation Mode
In rotation mode, the goal is to rotate the input vector until the residual angle zi converges to
zero. The decision variable is chosen as:
di = −1 if zi <0
+1 otherwise
(4)
After n iterations, with initial vector (x0,y0) = (1/K,0) and z0 = θ (target angle), the outputs
converge to:
xn ≈cos(θ),
yn ≈ sin(θ)
(5)
where K ≈ 1.6468 is the CORDIC gain that must be pre-compensated in the initial value of
x0.
1
2.3 Vectoring Mode
In vectoring mode, the goal is to rotate the input vector (x0,y0) until yi converges to zero, while
accumulating the total angle traversed in zi. The decision variable is:
di = +1 if yi <0
−1 otherwise
After n iterations, the outputs converge to:
xn ≈K
x2
0 + y2
0,
zn ≈ tan−1 y0
giving the magnitude (scaled by gain K) and phase of the input vector.
2.4 Fixed-Point Representation
(6)
x0
(7)
All quantities are represented in a Q2.14 fixed-point format using a 16-bit signed word: 2 integer
bits and 14 fractional bits, giving a resolution of 2−14 ≈ 6.1×10−5. Angles are scaled such that
90◦ corresponds to 16384 (i.e. a scale factor of 16384/90), which keeps the angle accumulator
within the same word width as the data path.
2.5 Pipelining
Since each CORDIC iteration depends only on the result of the previous iteration, the algorithm
is naturally suited to a fully pipelined hardware architecture. Each of the 16 micro-rotation
stages is implemented as one pipeline stage, with dedicated x, y, z, and valid registers propa
gating through the pipeline on every clock edge. This allows a new input sample to be accepted
every clock cycle, yielding a throughput of one result per clock cycle after an initial latency of
16 cycles, at the cost of increased register/area usage compared to an iterative (non-pipelined)
implementation
