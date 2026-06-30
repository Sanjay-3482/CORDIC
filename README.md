# CORDIC Processor (16-Stage Pipelined Verilog Implementation)

## Introduction

The **CORDIC (COordinate Rotation DIgital Computer)** algorithm is an iterative technique used to compute trigonometric, hyperbolic, and other transcendental functions using only **shift-and-add operations**, making it highly suitable for hardware implementation where multipliers are expensive or unavailable.

This project implements a **fully pipelined 16-stage CORDIC processor** in **Verilog HDL**, supporting two operating modes:

- **Rotation Mode:** Computes the sine and cosine of a given input angle.
- **Vectoring Mode:** Computes the magnitude and phase angle of an input vector.

---

# CORDIC Algorithm

## Basic Principle

The CORDIC algorithm rotates a vector \((x_i, y_i)\) by a sequence of progressively smaller angles

\[
\theta_i = \tan^{-1}(2^{-i})
\]

Each iteration requires only shift and add/subtract operations.

The iterative equations are

```
x(i+1) = x(i) - d(i) × y(i) × 2^(-i)

y(i+1) = y(i) + d(i) × x(i) × 2^(-i)

z(i+1) = z(i) - d(i) × atan(2^(-i))
```

where

- **d(i) = ±1** is the rotation direction
- **atan(2⁻ⁱ)** values are stored in a Lookup Table (LUT)

---

# Rotation Mode

In Rotation Mode, the objective is to rotate the input vector until the residual angle becomes zero.

Decision variable:

```
d(i) = -1   if z(i) < 0
d(i) = +1   otherwise
```

Initial values:

```
x0 = 1/K
y0 = 0
z0 = Input Angle
```

After 16 iterations,

```
x ≈ cos(θ)

y ≈ sin(θ)
```

where

```
K ≈ 1.6468
```

is the CORDIC gain, compensated by initializing

```
x0 = 1/K ≈ 0.60725
```

---

# Vectoring Mode

In Vectoring Mode, the objective is to rotate the vector until the y-component becomes zero.

Decision variable:

```
d(i) = +1   if y(i) < 0
d(i) = -1   otherwise
```

After convergence,

```
Magnitude ≈ K × √(x² + y²)

Phase ≈ atan(y/x)
```

The magnitude is scaled by the CORDIC gain.

---

# Fixed-Point Representation

All computations are performed using **Q2.14 fixed-point format**.

- **Word Length:** 16 bits
- **Integer Bits:** 2
- **Fractional Bits:** 14
- **Resolution:** 2⁻¹⁴ ≈ 6.1 × 10⁻⁵

Angles are represented using the scaling

```
90° = 16384
```

which corresponds to

```
Scale Factor = 16384 / 90
```

This keeps the angle accumulator within the same 16-bit datapath.

---

# Pipeline Architecture

The processor is implemented as a **fully pipelined 16-stage architecture**.

Each stage performs one CORDIC micro-rotation and contains dedicated pipeline registers for

- X
- Y
- Z
- Valid signal

A new input sample can be accepted **every clock cycle**.

### Performance

- Pipeline Stages : **16**
- Latency : **16 clock cycles**
- Throughput : **1 output per clock cycle** (after pipeline fill)

The pipelined implementation provides significantly higher throughput than an iterative CORDIC architecture at the expense of additional registers and hardware area.

---

# Features

- 16-stage fully pipelined architecture
- Rotation Mode (Sine/Cosine computation)
- Vectoring Mode (Magnitude/Phase computation)
- Shift-and-add implementation (No multipliers)
- Q2.14 fixed-point arithmetic
- Angle Lookup Table (LUT)
- Valid-bit propagation through pipeline
- Synthesizable Verilog HDL design

---

# Applications

- Digital Signal Processing (DSP)
- Software Defined Radio (SDR)
- FFT implementations
- Motor Control
- Robotics
- Navigation Systems
- FPGA and ASIC designs
- Embedded Digital Systems
