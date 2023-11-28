	adds r1,r2,r3
	mov r1, #1
L1:	add r1, r1, #1
	cmple r2, #100
	ble L1
	ldr r3, [r1, #10]
	str r5, [r2], #6
	
	
	

    
    