;****************** main.s ***************
; Program written by: ***Your Names**update this***
; Date Created: 2/4/2017
; Last Modified: 1/17/2020
; Brief description of the program
;   The LED toggles at 2 Hz and a varying duty-cycle
; Hardware connections (External: One button and one LED)
;  PE1 is Button input  (1 means pressed, 0 means not pressed)
;  PE2 is LED output (1 activates external LED on protoboard)
;  PF4 is builtin button SW1 on Launchpad (Internal) 
;        Negative Logic (0 means pressed, 1 means not pressed)
; Overall functionality of this system is to operate like this
;   1) Make PE2 an output and make PE1 and PF4 inputs.
;   2) The system starts with the the LED toggling at 2Hz,
;      which is 2 times per second with a duty-cycle of 30%.
;      Therefore, the LED is ON for 150ms and off for 350 ms.
;   3) When the button (PE1) is pressed-and-released increase
;      the duty cycle by 20% (modulo 100%). Therefore for each
;      press-and-release the duty cycle changes from 30% to 70% to 70%
;      to 90% to 10% to 30% so on
;   4) Implement a "breathing LED" when SW1 (PF4) on the Launchpad is pressed:
;      a) Be creative and play around with what "breathing" means.
;         An example of "breathing" is most computers power LED in sleep mode
;         (e.g., https://www.youtube.com/watch?v=ZT6siXyIjvQ).
;      b) When (PF4) is released while in breathing mode, resume blinking at 2Hz.
;         The duty cycle can either match the most recent duty-
;         cycle or reset to 30%.
;      TIP: debugging the breathing LED algorithm using the real board.
; PortE device registers
GPIO_PORTE_DATA_R  EQU 0x400243FC
GPIO_PORTE_DIR_R   EQU 0x40024400
GPIO_PORTE_AFSEL_R EQU 0x40024420
GPIO_PORTE_DEN_R   EQU 0x4002451C
; PortF device registers
GPIO_PORTF_DATA_R  EQU 0x400253FC
GPIO_PORTF_DIR_R   EQU 0x40025400
GPIO_PORTF_AFSEL_R EQU 0x40025420
GPIO_PORTF_PUR_R   EQU 0x40025510
GPIO_PORTF_DEN_R   EQU 0x4002551C
GPIO_PORTF_LOCK_R  EQU 0x40025520
GPIO_PORTF_CR_R    EQU 0x40025524
GPIO_LOCK_KEY      EQU 0x4C4F434B  ; Unlocks the GPIO_CR register
SYSCTL_RCGCGPIO_R  EQU 0x400FE608

Delay_number	   EQU 0x002DC6C0
Delay_number_Two   EQU 0x006ACFC0
i RN 3 
	
	IMPORT  TExaS_Init
       THUMB
       AREA    DATA, ALIGN=2
;global variables go here


       AREA    |.text|, CODE, READONLY, ALIGN=2
Delay_Array    DCD  20000,180000,70000,130000,100000,100000,130000,70000,180000, 200000, 199999, 1, 8333333, 100000, 12000000, 20000
       THUMB
       EXPORT  Start
Start
 ; TExaS_Init sets bus clock at 80 MHz
     BL  TExaS_Init ; voltmeter, scope on PD3
 ; Initialization goes here
	LDR R0, =SYSCTL_RCGCGPIO_R ;clock cycle
	LDR R1, [R0]
	ORR R1, #0x30
	STR R1, [R0]
	
	NOP
	NOP
	
	LDR R0, =GPIO_PORTE_DIR_R   ; selecting ports
	ORR R1, #0x08
	STR R1, [R0]
	
	LDR R0, =GPIO_PORTE_DEN_R   ; initating ports
	ORR R1, #0x0A
	STR R1, [R0] 
	
	LDR R0, =GPIO_PORTF_LOCK_R
	LDR R1, =GPIO_LOCK_KEY
	STR R1, [R0]

	LDR R0, =GPIO_PORTF_CR_R
	LDR R1, [R0]
	ORR R1, #0xFF
	STR R1, [R0]
	
	LDR R0, =GPIO_PORTF_DIR_R
	LDR R1, [R0]
	AND R1, #0xEF
	STR R1, [R0]
	
	LDR R0, =GPIO_PORTF_DEN_R
	LDR R1, [R0]
	ORR R1, #0x10
	STR R1, [R0]
	
	LDR R0, =GPIO_PORTF_PUR_R
	LDR R1, [R0]
	ORR R1, #0x10
	STR R1, [R0]
	
AA   LDR R3, =5				    ;numbers for loop and freqency
	 LDR R4, =1000000            ;Delay for PE3 High first loop
	 LDR R5, =9000000            ;Delay for PE3 Low first loop
	 
     CPSIE  I    ; TExaS voltmeter, scope runs on interrupts
loop  
     LDR R0, =GPIO_PORTE_DATA_R ;getting input data from port PE1
	 LDR R1, [R0]
	 AND R2, R1, #02
	 CMP R2, #2
	 BEQ EE
	 
	 LDR R0, =GPIO_PORTE_DATA_R ; Setting PE3 High
	 LDR R1, [R0]
	 ORR R1, #0x08
	 STR R1, [R0]
	
				   	 
wait SUBS R4, R4, #0x01 ;Delay 
     BNE wait

     LDR R0, =GPIO_PORTE_DATA_R ;getting input data from port PE1
	 LDR R1, [R0]
	 AND R2, R1, #02
	 CMP R2, #2
	 BEQ EE  
	 
	 LDR R0, =GPIO_PORTE_DATA_R  ;Setting PE3 Low
	 LDR R1, [R0]
	 AND R1, #0xFFFFFFF7
     STR R1, [R0]
	 
wait2 SUBS R5, R5, #0x01 ;Delay
      BNE wait2
	  
	 LDR R0, =GPIO_PORTF_DATA_R; Getting input data from PF4
	 LDR R1, [R0]
	 AND R2, R1, #0x10
	 CMP R2, #0
	 BEQ FA
	  
	 LDR R0, =GPIO_PORTE_DATA_R ;getting input data from port PE1
	 LDR R1, [R0]
	 AND R2, R1, #02
	 CMP R2, #2
	 BEQ EE
	  B EF
	 
	 
; Check what is the current Frequency, and then change it to the next one	  
EE 	  SUB R3, R3, #1; R3 only changes when PE1 is pressed 

EF    CMP R3, #4
	  BEQ DA
	  
	  CMP R3, #3
	  BEQ DB
	  
	  CMP R3, #2
	  BEQ DC
	  
	  CMP R3, #1
	  BEQ DD
	  
	  CMP R3, #5
	  BEQ DF
	  
	  CMP R3, #0  
	  BEQ DE 
	  B EF
	  
DA    LDR R4, =3000000 ;high
      LDR R5, =7000000 ;Low
	  B E1
	  
DB    LDR R4, =5000000
      LDR R5, =5000000
	  B E1

DC   LDR R4, =7000000
     LDR R5, =3000000
     B E1

DD   LDR R4, =9000000
     LDR R5, =1000000
	 B E1
	 
DE   LDR R4, =1000000
     LDR R5, =9000000
	 ADD R3, #5
	 
DF	LDR R4, =1000000
    LDR R5, =9000000
	 B E1
	 
     LDR R0, =GPIO_PORTE_DATA_R ;getting input data from port PE1
	 LDR R1, [R0]
	 AND R2, R1, #02
	 CMP R2, #2
	 BEQ EE
	 
E1   LDR R0, =GPIO_PORTE_DATA_R; Getting input data from port PE1, stays put if the button hasn't been released
     LDR R1, [R0]
	 AND R2, R1, #0x02
	 CMP R2, #0
	 BEQ loop
	 B E1
;Routine when PF4 is pressed	 
     
FA   MOV R6, #0                                 ;Start of Array
     MOV R9, #6                              	; Counter for how many times it has to go through the loop before it reaches the top of the array
FB	 MOV R11, #5                               ; How many times the light flashes at a certain frequency
     MOV R10, #1                               ; If R10 has a 1, it means that its going up the array, if it is 0, it means it is going down the array
GC   LDR R1, =Delay_Array
	 LDR R7, [R1, R6]                          ; R7 is delay for when PE3 is High
	 ADD R6, #4
	 LDR R8, [R1, R6]                          ; r8 is delay for when PE3 is Low
	 ADD R6, #4
	 
HA	 LDR R0, =GPIO_PORTE_DATA_R                ; Setting PE3 High
	 LDR R1, [R0]
	 ORR R1, #0x08
	 STR R1, [R0]
	 
wait3 SUBS R7, R7, #1
	  BNE wait3
	  
	 LDR R0, =GPIO_PORTE_DATA_R               ;Setting PE3 Low
	 LDR R1, [R0]
	 AND R1, #0xFFFFFFF7
     STR R1, [R0]	 

wait4 SUBS R8, R8, #1
      BNE wait4
	  
	  
	 LDR R0, =GPIO_PORTF_DATA_R              ; Checks if the switch has been released, and if it has, it returns to normal loop
	 LDR R1, [R0]
	 AND R2, R1, #0x10
	 CMP R2, #0x10
	 BEQ AA
	 
	 SUB R11, #1
	 CMP R11, #0                            ; Checks whether or not the light is at its last loop on a certain frequency 
	 BNE GA
	 
	 CMP R10, #0                            ; Determines whether or not it is going up the array or not
	 BEQ FD
	 
	 SUB R9, #1
	 CMP R9, #0
     BEQ FC                                ; Branches when it has reached the top of the array 
	 B FB
                                            ;Routine for when it is going down the array
FC   SUBS R10,R10, #1                     ; Sets R10 to zero

FD   MOV R11, #5                          ; R11 is the counter
GD   SUBS R6, R6, #4                      ; Decreases the address of the array
     LDR R1, =Delay_Array 
	 LDR R8, [R1, R6]
	 SUB R6, #4
	 LDR R7, [R1, R6] 
	 CMP R12, #1                          ; If the program is at the end of R11 loop, then reset R12, and increase R9 
	 BEQ GE
	 CMP R11, #1
	 BNE HA
	 MOV R12, #1                         ; R12 sets whether or not the program is at the end of loop R11
	 B HA
GE   MOV R12, #0; 
     ADD R9, #1;
	 CMP R9, #6;
	 BEQ GF                             ; Branches when it has reached the bottom of the array
	 B HA
                                        ; Resets R6, so that it reads the same frequency again	 
GA   CMP R10, #0
     BEQ GB                             ; Determines whether or not it is going down the array or up the array
                                        ;Resets value when it is going up the array	 
	 SUB R6, #8
	 B GC
                                        ;Resets value when it is going down the array	 
GB	 ADD R6, #8
     B GD
                                        ;Resets R6 to zero after going down the array	 
GF  ADD R6, #8
    B FB
	 
     
	  
	 
; main engine goes here

   
     B    AA
	 

      
     ALIGN      ; make sure the end of this section is aligned
     END        ; end of file

