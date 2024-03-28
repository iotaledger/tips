
# Parameters constraints

Due to the use of fixed point arithmetics, some contraints on the Mana parameters are needed to prevent overflowing of the variables used for the Mana decay and generation calculations.

In particular, the function `Multiplication And Shift(valueHi, valueLo, multFactor, shiftFactor)` is applied to the following variables:

- `Multiplication And Shift(Upper Bits(value, 32), Lower Bits(value, 32), Decay Factors(m), Decay Factors Exponent)`.
- `Multiplication And Shift(Upper Bits(value, 32), Lower Bits(value, 32), slotIndexDiff * Generation Rate, Generation Rate Exponent)`.
- `Multiplication And Shift(Upper Bits(Amount, 32), Lower Bits(Amount, 32), Decay Factor Epochs Sum * Generation Rate , Decay Factor Epochs Sum Exponent+generationRateExponent-slotsPerEpochExponent)`.
By contruction, `Upper Bits(Amount, 32)` and `Upper Bits(Amount, 32)` will always use at most 32 bits (given that `Amount` uses at most 64 bits).

Since `shiftFactor` must be an integer between 0 and 32, we have:

- 0≤`Decay Factors Exponent`≤32.
- 0≤`Generation Rate Exponent`≤32.
- 0≤`Decay Factor Epochs Sum Exponent+generationRateExponent-slotsPerEpochExponent`≤32.
- 0≤`generationRateExponent-slotsPerEpochExponent`≤32.

The third variable `multFactor` must additionally use at most 32 bits, meaning that we have the following constraints:

- `Decay Factors(m)`< <code>2<sup>32</sup></code> (which is equivalent, by contruction to 0≤`Decay Factors Exponent`≤3),
- `slotIndexDiff * Generation Rate`< <code>2<sup>32</sup></code>,
- `Decay Factor Epochs Sum * Generation Rate`< <code>2<sup>32</sup></code>,


TO DO: Rewards and maximum theoretical Mana in the system is smaller than <code>2<sup>Bits Count</sup> - 1</code>
