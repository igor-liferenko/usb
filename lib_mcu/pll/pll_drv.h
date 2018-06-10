/*This file has been prepared for Doxygen automatic documentation generation.*/
//! \file *********************************************************************
//!
//! \brief @brief This file contains the low level macros and definition for the USB PLL
//!
//! - Compiler:           IAR EWAVR and GNU GCC for AVR
//! - Supported devices:  ATmega32U4
//!
//! \author               Atmel Corporation: http://www.atmel.com \n
//!                       Support and FAQ: http://support.atmel.no/
//!
//! ***************************************************************************

#ifndef PLL_DRV_H
#define PLL_DRV_H

//_____ I N C L U D E S ____________________________________________________

//! @defgroup PLL PLL driver
//! PLL Module
//! @{
//_____ M A C R O S ________________________________________________________

   //! @defgroup PLL_macros PLL Macros
   //! These functions allow to control the PLL
   //! @{

#define PLL_IN_PRESCAL_DISABLE         ( 0<<PINDIV )
#define PLL_IN_PRESCAL_ENABLE          ( 1<<PINDIV )

#define PLL_OUT_48MHZ     ( (0<<PDIV3)| (1<<PDIV2) | (0<<PDIV1)| (0<<PDIV0))
#define PLL_OUT_MSK       ( (1<<PDIV3)| (1<<PDIV2) | (1<<PDIV1)| (1<<PDIV0))

#define PLL_HS_TMR_PSCAL_NULL          ( (0<<PLLTM1) | (0<<PLLTM0) )
#define PLL_HS_TMR_PSCAL_1             ( (0<<PLLTM1) | (1<<PLLTM0) )
#define PLL_HS_TMR_PSCAL_1DOT5         ( (1<<PLLTM1) | (0<<PLLTM0) )
#define PLL_HS_TMR_PSCAL_2             ( (1<<PLLTM1) | (1<<PLLTM0) )

#define PLL_HS_TMR_PSCAL_MSK           ( (1<<PLLTM1) | (1<<PLLTM0) )

#define Pll_set_hs_tmr_pscal_null()    (PLLFRQ&=~PLL_HS_TMR_PSCAL_MSK,PLLFRQ|=PLL_HS_TMR_PSCAL_NULL)      
#define Pll_set_hs_tmr_pscal_1()       (PLLFRQ&=~PLL_HS_TMR_PSCAL_MSK,PLLFRQ|=PLL_HS_TMR_PSCAL_1)      
#define Pll_set_hs_tmr_pscal_1dot5()   (PLLFRQ&=~PLL_HS_TMR_PSCAL_MSK,PLLFRQ|=PLL_HS_TMR_PSCAL_1DOT5)
#define Pll_set_hs_tmr_pscal_2()       (PLLFRQ&=~PLL_HS_TMR_PSCAL_MSK,PLLFRQ|=PLL_HS_TMR_PSCAL_2)

#define Start_pll(in_prescal)       \
  (PLLFRQ &= ~PLL_OUT_MSK,PLLFRQ|= PLL_OUT_FRQ, PLLCSR = (in_prescal | (1<<PLLE)))

      //! return 1 when PLL locked
#define Is_pll_ready()       (PLLCSR & (1<<PLOCK) )

      //! Test PLL lock bit and wait until lock is set
#define Wait_pll_ready()     while (!(PLLCSR & (1<<PLOCK)))

      //! Stop the PLL
#define Stop_pll()           (PLLCSR  &= (~(1<<PLLE)),PLLCSR=0 ) 
      
      //! Select the internal RC as clock source for PLL
#define Set_RC_pll_clock()    (PLLFRQ |= (1<<PINMUX))      
      
      //! Select XTAL as clock source for PLL
#define Set_XTAL_pll_clock()    (PLLFRQ &= ~(1<<PINMUX))        

   //! @}

#define Pll_start_auto()   Start_pll(PLL_IN_PRESCAL_ENABLE)

//! @}
#endif  // PLL_DRV_H


