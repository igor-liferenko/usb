This is how it must be used: in kbd.ch temporarily change this

---------------------------------
  @<Initialize input pins@>@;

  while (1) {
    @<Get button@>@;
    if (btn != 0) {
      @<Send button@>@;
      uint16_t prev_button = btn|mod<<8;
      int timeout = 2000;
      while (--timeout) {
        @<Get button@>@;
        if ((btn|mod<<8) != prev_button) break;
        _delay_ms(1);
      }
      while (1) {
        @<Get button@>@;
        if ((btn|mod<<8) != prev_button) break;
        @<Send button@>@;
        _delay_ms(50);
      }
    }
  }
-----------------------------------

into this

-----------------------------------
  PORTD |= 1 << PD0;
  PORTD |= 1 << PD1;
  while (1) {
    if (!(PIND & 1 << PD0)) {
      btn = 0x04; /* a */
      @<Send button@>@;
      _delay_ms(1000);
    }
    if (!(PIND & 1 << PD1)) {
      btn = 0x29; /* ESC */
      @<Send button@>@;
      _delay_ms(1000);
    }
  }
------------------------------------

and then run

    ctangle ../avrtel/avrtel kbd kbd
    make kbd

(temporarily reset avrtel/ to commit with comment "out of sync" if you have not yet synced kbd.ch with avrtel.w)
