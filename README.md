# Basys-3-board-timer

> Developed for Basys 3 board
> in xlinx vivado

This VHDL component that provides 
basic stop watch functionality. The design will start at 20 and end the
count down at the right-most 7 seg display. When the center button is
pressed it will cause the count to start and stop. The down button will
reset the counter to 20. If the count reaches 00, the segs of the two-
left most 7 segs will create a victory pattern.
