text_to_numbers
===============

Converts string text into Numbers (Fixnum/Bignum)

```Ruby

require 'text_to_numbers'

"four hundred million".to_numbers => 400000000
"sixty-eight".to_numbers => 68
"sixty-eight point 5".to_numbers => 68.5
"four hundred and eight".to_numbers => 408
"9.5 Million".to_numbers => 9500000.0

```
