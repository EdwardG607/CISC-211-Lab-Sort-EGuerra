/*** asmSort.s   ***/
#include <xc.h>
.syntax unified

@ Declare the following to be in data memory
.data
.align    

@ Define the globals so that the C code can access them
/* define and initialize global variables that C can access */
/* create a string */
.global nameStr
.type nameStr,%gnu_unique_object
    
/*** STUDENTS: Change the next line to your name!  **/
nameStr: .asciz "Edward Guerra Ramirez"  

.align   /* realign so that next mem allocations are on word boundaries */
 
/* initialize a global variable that C can access to print the nameStr */
.global nameStrPtr
.type nameStrPtr,%gnu_unique_object
nameStrPtr: .word nameStr   /* Assign the mem loc of nameStr to nameStrPtr */

@ Tell the assembler that what follows is in instruction memory    
.text
.align

/********************************************************************
function name: asmSwap(inpAddr,signed,elementSize)
function description:
    Checks magnitude of each of two input values 
    v1 and v2 that are stored in adjacent in 32bit memory words.
    v1 is located in memory location (inpAddr)
    v2 is located at mem location (inpAddr + M4 word size)
    
    If v1 or v2 is 0, this function immediately
    places -1 in r0 and returns to the caller.
    
    Else, if v1 <= v2, this function 
    does not modify memory, and returns 0 in r0. 

    Else, if v1 > v2, this function 
    swaps the values and returns 1 in r0

Inputs: r0: inpAddr: Address of v1 to be examined. 
	             Address of v2 is: inpAddr + M4 word size
	r1: signed: 1 indicates values are signed, 
	            0 indicates values are unsigned
	r2: size: number of bytes for each input value.
                  Valid values: 1, 2, 4
                  The values v1 and v2 are stored in
                  the least significant bits at locations
                  inpAddr and (inpAddr + M4 word size).
                  Any bits not used in the word may be
                  set to random values. They should be ignored
                  and must not be modified.
Outputs: r0 returns: -1 If either v1 or v2 is 0
                      0 If neither v1 or v2 is 0, 
                        and a swap WAS NOT made
                      1 If neither v1 or v2 is 0, 
                        and a swap WAS made             
             
         Memory: if v1>v2:
			swap v1 and v2.
                 Else, if v1 == 0 OR v2 == 0 OR if v1 <= v2:
			DO NOT swap values in memory.

NOTE: definitions: "greater than" means most positive number
********************************************************************/     
.global asmSwap
.type asmSwap,%function     
asmSwap:

    /* YOUR asmSwap CODE BELOW THIS LINE! VVVVVVVVVVVVVVVVVVVVV  */

/* r0 = inpAddr (points to v1), r1 = signed flag, and r2 = element size in bytes (1, 2, or 4) */

    /* Preserves v1's and v2's addresses for later use */
    MOV     r3, r0          /* r3 holds the address of v1 */
    ADD     r4, r0, #4      /* r4 holds the address of v2, assuming the values are placed contiguously in memory */

    /* Loads the values from memory into registers according to size and signedness */
    CMP     r2, #1
    BEQ     load_byte       /* If size is 1 byte, handle byte loading */
    CMP     r2, #2
    BEQ     load_half       /* If size is 2 bytes, handle halfword loading */

    /* Default: load full 4-byte words */
    LDR     r5, [r3]        /* Loads v1 */
    LDR     r6, [r4]        /* Loads v2 */
    B       check_zero      /* Proceed to zero check */

load_byte:
    CMP     r1, #0
    BEQ     load_byte_unsigned  /* If not signed, loads as unsigned bytes */
    LDRSB   r5, [r3]        /* Signed byte loads v1 */
    LDRSB   r6, [r4]        /* Signed byte loads v2 */
    B       check_zero

load_byte_unsigned:
    LDRB    r5, [r3]        /* Unsigned byte loads v1 */
    LDRB    r6, [r4]        /* Unsigned byte loads v2 */
    B       check_zero

load_half:
    CMP     r1, #0
    BEQ     load_half_unsigned  /* If not signed, loads as unsigned halfwords */
    LDRSH   r5, [r3]        /* Signed halfword loads v1 */
    LDRSH   r6, [r4]        /* Signed halfword loads v2 */
    B       check_zero

load_half_unsigned:
    LDRH    r5, [r3]        /* Unsigned halfword loads v1 */
    LDRH    r6, [r4]        /* Unsigned halfword loads v2 */
    B       check_zero

check_zero:
    /* If either input is zero, swap is not performed it returns -1 to signal this special case */
    CMP     r5, #0
    BEQ     return_neg1
    CMP     r6, #0
    BEQ     return_neg1

    /* Choose comparison type: signed or unsigned based on r1 */
    CMP     r1, #0
    BEQ     cmp_unsigned    /* If unsigned flag is set, uses unsigned comparison */

    /* Signed comparison: only swap if v1 > v2 */
    CMP     r5, r6
    BLE     return_0        /* No need to swap if v1 <= v2 */
    B       do_swap         /* Swaps if v1 > v2 */

cmp_unsigned:
    CMP     r5, r6
    BLS     return_0        /* No need to swap if v1 <= v2 */
    
do_swap:
    /* Performs the swap in memory based on element size */
    CMP     r2, #1
    BEQ     store_byte      /* Byte-sized store */
    CMP     r2, #2
    BEQ     store_half      /* Halfword-sized store */

    /* Word-sized swap */
    STR     r6, [r3]        /* Stores v2 into v1's original location */
    STR     r5, [r4]        /* Stores v1 into v2's original location */
    MOV     r0, #1          /* Returns 1 to signal that a swap was made */
    BX      lr

store_byte:
    STRB    r6, [r3]        /* Stores v2 as byte */
    STRB    r5, [r4]        /* Stores v1 as byte */
    MOV     r0, #1
    BX      lr

store_half:
    STRH    r6, [r3]        /* Stores v2 as halfword */
    STRH    r5, [r4]        /* Stores v1 as halfword */
    MOV     r0, #1
    BX      lr

return_neg1:
    /* Special case: a zero value blocks the swap */
    MOV     r0, #-1
    BX      lr

return_0:
    /* Values were in correct order; no swap needed */
    MOV     r0, #0
    BX      lr

    /* YOUR asmSwap CODE ABOVE THIS LINE! ^^^^^^^^^^^^^^^^^^^^^  */
    
    
/********************************************************************
function name: asmSort(startAddr,signed,elementSize)
function description:
    Sorts value in an array from lowest to highest.
    The end of the input array is marked by a value
    of 0.
    The values are sorted "in-place" (i.e. upon returning
    to the caller, the first element of the sorted array 
    is located at the original startAddr)
    The function returns the total number of swaps that were
    required to put the array in order in r0. 
    
         
Inputs: r0: startAddr: address of first value in array.
		      Next element will be located at:
                          inpAddr + M4 word size
	r1: signed: 1 indicates values are signed, 
	            0 indicates values are unsigned
	r2: elementSize: number of bytes for each input value.
                          Valid values: 1, 2, 4
Outputs: r0: number of swaps required to sort the array
         Memory: The original input values will be
                 sorted and stored in memory starting
		 at mem location startAddr
NOTE: definitions: "greater than" means most positive number    
********************************************************************/     
.global asmSort
.type asmSort,%function
asmSort:   

    /* Note to Profs: 
     */

    /* YOUR asmSort CODE BELOW THIS LINE! VVVVVVVVVVVVVVVVVVVVV  */

 /* Saves the function inputs to local registers for clarity and reuse */
    MOV     r3, r0          /* r3 = base pointer to array */
    MOV     r4, r1          /* r4 = signed flag (1 = signed comparison) */
    MOV     r5, r2          /* r5 = element size (1, 2, or 4 bytes) */
    MOV     r6, #0          /* r6 = swap counter, used to detect if another pass is needed */

outer_loop:
    /* Starts a new pass through the array from the beginning */
    MOV     r7, r3          /* r7 = pointer to current element (v1) */
    ADD     r8, r7, #4      /* r8 = pointer to next element (v2), assuming max size step of 4 bytes */

inner_loop:
    /* Loads the next value (v2) to determine if we've reached a sentinel 0 indicating end of data */
    CMP     r5, #1
    BEQ     iload_byte      /* Handles 1-byte elements */
    CMP     r5, #2
    BEQ     iload_half      /* Handles 2-byte elements */

    /* Default case: 4-byte word elements */
    LDR     r9, [r8]        /* Loads the next element (v2) */
    CMP     r9, #0
    BEQ     done_sorting    /* Stops if v2 is zero (end of array reached) */
    B       call_swap       /* Otherwise, compare and maybe swap */

iload_byte:
    LDRB    r9, [r8]        /* Loads the next element as unsigned byte */
    CMP     r9, #0
    BEQ     done_sorting    /* End of list reached */
    B       call_swap

iload_half:
    LDRH    r9, [r8]        /* Loads the next element as unsigned halfword */
    CMP     r9, #0
    BEQ     done_sorting    /* End of list reached */

call_swap:
    /* Call asmSwap to conditionally swap values if out of order */
    MOV     r0, r7      /* Passes address of current element (v1) */
    MOV     r1, r4      /* Passes signed flag */
    MOV     r2, r5      /* Passes element size */
    BL      asmSwap     /* If swap is performed, asmSwap returns 1 */

    /* Tracks the number of swaps to know whether another pass is needed */
    CMP     r0, #1
    ADD     r6, r6, r0  /* Only increment r6 if swap occurred */

    /* Moves both pointers forward to check the next pair */
    ADD     r7, r7, #4  /* Moves to next element (v1) */
    ADD     r8, r8, #4  /* Moves to its neighbor (v2) */
    B       inner_loop  /* Continue inner loop */

done_sorting:
    /* One full pass is complete ? check if any swaps were made */
    CMP     r6, #0
    BEQ     finish_sort     /* If there are no swaps, array is sorted */

    /* If swaps occurred, we must check again (Bubble Sort behavior) */
    B       asmSort         /* Recurse into asmSort with original args (tail-recursive style) */

finish_sort:
    /* Returns the total number of swaps performed */
    MOV     r0, r6
    BX      lr

    /* YOUR asmSort CODE ABOVE THIS LINE! ^^^^^^^^^^^^^^^^^^^^^  */

   

/**********************************************************************/   
.end  /* The assembler will not process anything after this directive!!! */
           




