@ @c
//!_____ I N C L U D E S ____________________________________________________
#define _SCHEDULER_C_
#include "config.h"                         // system definition 
#include "scheduler.h"                      // scheduler definition 


//!_____ M A C R O S ________________________________________________________
//!_____ D E F I N I T I O N ________________________________________________

#ifdef TOKEN_MODE
//! Can be used to avoid that some tasks executes at same time. 
//! The tasks check if the token is free before executing. 
//! If the token is free, the tasks reserve it at the begin of the execution 
//! and release it at the end of the execution to enable next waiting tasks to 
//! run.   
Uchar token;
#endif

//!_____ D E C L A R A T I O N ______________________________________________
//! Scheduler initialization
//!
//! Task_x_init() and Task_x_fct() are defined in config.h
//!
//! @warning Code:XX bytes (function code length)
//!
//! @param  :none
//! @return :none
void scheduler_init (void)
{
   #ifdef Scheduler_time_init
      Scheduler_time_init();
   #endif
   #ifdef TOKEN_MODE
      token =  TOKEN_FREE;
   #endif
      usb_task_init();  
   Scheduler_reset_tick_flag();
}

//! Task execution scheduler
//!
//! @warning Code:XX bytes (function code length)
//!
//! @param  :none
//! @return :none
void scheduler_tasks (void)
{
   // To avoid uncalled segment warning if the empty function is not used
   scheduler_empty_fct();

   for(;;)
   {
      Scheduler_new_schedule();

         usb_task();
         cdc_task();
   }
}

//! Init & run the scheduler
//!
//! @warning Code:XX bytes (function code length)
//!
//! @param  :none
//! @return :none
void scheduler (void)
{
   scheduler_init();
   scheduler_tasks();
}


//! Do nothing
//! Avoid uncalled segment warning if the empty function is not used
//!
//! @warning Code:XX bytes (function code length)
//!
//! @param  :none
//! @return :none
void scheduler_empty_fct (void)
{
}

