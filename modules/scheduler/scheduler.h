/*This file has been prepared for Doxygen automatic documentation generation.*/
//! \file *********************************************************************
//!
//! \brief This file is the definition of the scheduler
//!
//!  This file contains the scheduler definition and the task function to be
//!  executed by the scheduler
//!  NOTE:
//!    SCHEDULER_TICK & FPER are defined in config.h
//!
//! - Compiler:           IAR EWAVR and GNU GCC for AVR
//! - Supported devices:  ATmega32U4
//!
//! \author               Atmel Corporation: http://www.atmel.com \n
//!                       Support and FAQ: http://support.atmel.no/
//!
//! ***************************************************************************

#ifndef _SCHEDULER_H_
#define _SCHEDULER_H_

//!_____ I N C L U D E S ____________________________________________________
#ifdef KEIL
#include <intrins.h>
#define Wait_semaphore(a) while(!_testbit_(a))
#else
#define Wait_semaphore(a) while(!(a)) (a) = FALSE
#endif

//!_____ M A C R O S ________________________________________________________
//! Definition of Task ID. This ID is used to properly send the event to a
//! specific task.
//! Mind, it will be possible to send an event to many task by TASK_1 | TASK_0.
//! The name of the define can be changed by another define. That customization
//! should be done in the file mail_evt.h
#define TASK_DUMMY   0x00           // This define is mandatory
#define TASK_0       0x01
#define TASK_1       0x02
#define TASK_2       0x04
#define TASK_3       0x08
#define TASK_4       0x10
#define TASK_5       0x20
#define TASK_6       0x40
#define TASK_7       0x80

// This define is mandatory
#define ALL_TASK     (TASK_0|TASK_1|TASK_2|TASK_3|TASK_4|TASK_5|TASK_6|TASK_7)
//! End Task ID

//!----- Scheduler Types -----
#define SCHEDULER_CUSTOM      0
#define SCHEDULER_TIMED       1
#define SCHEDULER_TASK        2
#define SCHEDULER_FREE        3



  extern  void cdc_task(void);


#endif //! _SCHEDULER_H_

