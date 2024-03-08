# Introduction

**This project is for self-learning purpose.**

- To compile the project, you need to ensure that you have an `ARM` environment.
- Personally, I use `rasbian` with `qemu` to emulate the `ARM` environment.
  - if you are using `M1 Mac` and struggling with the environment, check out this [repo](https://github.com/faf0/macos-qemu-rpi?fbclid=PAAaacdvE4MdBGAm8d-_IlLwFcOuZbpe2QE2RzZT_Twhao-iFRzDMAVrNDg-Y_aem_ATXTn-yxP3uwm9b51D58dhV7sqLVThDjJO-vpQ0ro-GHMgMnu_K_gaYHuq0ziTPxBf0)

## How to compile the project

- To see the result of the project, compile the project with `make`.

### Example

- you have the following `arm` code in `test.s`:

```arm
	adds r1,r2,r3
	mov r1, #1
L1:	add r1, r1, #1
	cmple r2, #100
	ble L1
	ldr r3, [r1, #10]
	str r5, [r2], #6
```

- After you run `make`, you will see the following output in the `test` file:

```
PC	condition	instruction
0	AL		ADD
4	AL		MOV
8	AL		ADD
12	LE		CMP
16	LE		B	8
20	AL		LDR
24	GT		STR
```

> **NOTE**:
> If you want to test out some custom **arm code**, modify `test.s` and recompile the project again.
