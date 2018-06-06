/*This file has been prepared for Doxygen automatic documentation generation.*/
/*! \file *********************************************************************
 *
 * \brief Driver routines to read (no write) datas stored in AVRMega flash
 * These routines can be stored and executed in all flash space.
 *
 * - Compiler:           GNU GCC for AVR
 * - Supported devices:  All AVRMega devices
 *
 * \author               Atmel Corporation: http://www.atmel.com \n
 *                       Support and FAQ: http://support.atmel.no/
 *
 *****************************************************************************/

#ifndef __GNUC__
#error Assembler file supported only by GNU GCC
#endif

//_____ I N C L U D E S ______________________________________________________


#include <avr/io.h>     // Registers declarations
  
//_____ M A C R O S ________________________________________________________

//! Macro for I/O Location used in following instructions :
//! "IN - Load an I/O Location to Register", "OUT - Store Register to I/O Location", ...
#define _ASM_SFR_IO_( sfr ) (sfr-0x20)


//_____ D E C L A R A T I O N S ______________________________________________

   .global  flash_read_sig
   .global  flash_read_fuse
   

//! @{
//! \verbatim

//! @brief This macro function allows to read device IDs of the product.
//!
//! @param  add   Address of device ID to read.
//!
//! @return byte  Read value (R24)
//!
flash_read_sig:
   RCALL    WAIT_SPMEN                       // Wait for SPMEN flag cleared
   MOV      R31,R23
   MOV      R30,R22                          // move adress to z pointer (R31=ZH R30=ZL)
   LDI      R20, ((1<<SPMEN) | (1<<SIGRD))  
   OUT      _ASM_SFR_IO_(SPMCSR), R20        // argument 2 decides function (r18)
   LPM                                       // Store program memory
   MOV      R24, R0                          // Store return value
   RJMP     WAIT_SPMEN                       // Wait for SPMEN flag cleared


//! @brief This macro function allows to read a fuse byte of the product.
//!
//! @param  add   Address of fuse to read.
//! 
//! @return byte  Read value (R24)
//!
flash_read_fuse:
   RCALL    WAIT_SPMEN                       // Wait for SPMEN flag cleared
   MOV      R31,R23
   MOV      R30,R22                          // move adress to z pointer (R31=ZH R30=ZL)
   LDI      R20,((1<<SPMEN) | (1<<BLBSET))  
   OUT      _ASM_SFR_IO_(SPMCSR), R20        // argument 2 decides function (r18)
   LPM                                       // Store program memory
   MOV      R24, R0                          // Store return value
   RJMP     WAIT_SPMEN                       // Wait for SPMEN flag cleared

//! @brief Performs an active wait on SPME flag
//!
WAIT_SPMEN:
   MOV      R0, R18
   IN       R18,_ASM_SFR_IO_(SPMCSR)         // get SPMCR into r18
   SBRC     R18,SPMEN
   RJMP     WAIT_SPMEN                       // Wait for SPMEN flag cleared
   MOV      R18, R0
   RET

//! \endverbatim
//! @}

