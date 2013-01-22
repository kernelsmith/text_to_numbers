module TextToNumbers

  # Count to ten!
  _ones = %w(zero one two three four five six seven eight nine ten)
  # Tens - with placeholders
  _tens = %w(none ten twenty thirty forty fifty sixty seventy eighty ninety)
  # Numbers after 10 are classed as "strange", as their kind are not seen elsewhere.
  _odd_balls = %w(eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen)
  _0_19 = _ones + _odd_balls
  _lots = ['', 'thousand', 'million', 'billion', 'trillion', 'quadrillion', 'quintrillion', 'sextillion',
    'septillion', 'octillion', 'nonillion', 'decillion', 'undecillion', 'duodecillion', 'tredecillion',
    'quattuordecillion', 'quindecillion', 'sexdecillion', 'septendecillion', 'octodecillion', 'novemdecillion',
    'vigintillion', 'unvigintillion', 'duovigintillion', 'trevigintillion', 'quattuortillion', 'quinvigintillion',
    'sexvigintillion', 'septenvigintillion', 'octovigintillion', 'novemvigintillion', 'trigintillion', 'untrigintillion',
    'duotrigintillion', 'trestrigintillion', 'quattuortrigintillion', 'quintrigintillion', 'sextrigintillion',
    'septentrigintillion', 'octotrigintillion', 'novemtrigintillion', 'quadragintillion', 'unquadragintillion',
    'duoquadragintillion', 'trequadragintillion', 'quattuorquadragintillion', 'quinquadragintillion', 'sesquadragintillion',
    'septenquadragintillion', 'octoquadragintillion', 'novenquadragintillion', 'quinquagintillion']

  # first, let's convert the word arrays into hashes to speed up lookups since searching an array is O(n) but
  # searching a hash is O(1).  this will result in e.g. self::ONES = {"nine" => 9, "eight" => 8... etc} but
  # order, of course, is not guaranteed.
  # we add 'self' to avoid any conflicts when this module is included in the String class
  self::ONES = Hash[*_ones.each_with_index.to_a.flatten]
  self::ODD_BALLS = Hash[*_odd_balls.each_with_index.to_a.flatten]
  self::ZERO_TO_NINETEEN = Hash[*_0_19.each_with_index.to_a.flatten]
  self::TENS = Hash[*_tens.each_with_index.to_a.flatten]
  self::LOTS = Hash[*_lots.each_with_index.to_a.flatten]

  #
  # returns an integer-esque or float-esque Number representing the human readable string number
  # @return [Fixnum,Bignum,Float] the number representing self
  #
  def to_numbers
    str = strip
    # handle and cleanup negative indicators
    if str =~ /^negative *|- */i
      str = str.sub($&, '')
      sign = -1
    end
    # cleanup & normalize the remaing text to avoid bad matches
    # remove extra spaces, downcase, replace any '-'s (like twenty-one), replace 'and's and '&'s, and
    # squeeze.  We sqeeze twice to avoid having crazy looking regexp's with *'s all over the place
    str = str.squeeze(' ').downcase.gsub('-',' ').gsub(/ and | & /,' ').squeeze(' ')
    # it's very common to get "fourty" instead of "forty" so we're gonna fix that
    str.gsub!(/fourty/,"forty")
    words = str.split(' ')
    running = ''
    groups = []
    sign = 1

    words.each_with_index do |word, idx|
      # Handle the case where someone gives us "9 million" instead of "nine million"
      f_or_i = differentiate_float_int(word)
      if word =~ /^0+\.*0*$/ # since "a".to_i returns 0, not nil
        # treat "0", "0.0", "0..0", "00.00" etc all as 0 , last one is kind of a bizarre case
        running = 0
        next
      # otherwise we try to determine if float string or integer string
      elsif ( not f_or_i == 0 and not f_or_i == 0.0 )
        # then word is an integer or float disguised as a string
        groups << f_or_i
        next
      end

      # try to lookup the word in 0-19
      if self::ZERO_TO_NINETEEN[word]
        running += self::ZERO_TO_NINETEEN[word].to_s
      elsif self::TENS[word] # if it's a self::TENS word
        if self.ONES[words[idx+1]] # if the next word is a self.ONES word
          running += self::TENS[word].to_s
        else
          running += (self::TENS[word] * 10).to_s
        end
      elsif word == "hundred"
        groups << running.to_i * 100
        running = ''
      elsif self::LOTS[word] # if big word
        if not running == ''
          # this is the case where the input includes something like "four thousand"
          groups << running.to_i * (10**(3*self::LOTS[word])) # e.g. self::LOTS["thousand"] = 1 so 10^(1+2) = 10^3 = 1000
        else
          if not groups.empty?
            # this is the case where input has something like "four hundred thousand"
            groups[groups.length-1] *= (10**(3*self::LOTS[word]))
          else
            # this the case where the input is just "thousand"
            groups << 1 * (10**(3*self::LOTS[word]))
          end
        end
        running = ''
      elsif word =~ /dot|point/ # like forty five point six (don't ask me why you would write like this)
        groups << running.to_i
        groups << "."
        running = ''
      else
        # could not recognize this gibberish, do nothing and hope we can still make out the rest
      end
    end # end words.each
    group_sum = 0
    left_half = 0
    if groups.include?(".")
      # process float
      groups.each do |group|
        if group == "."
          left_half = group_sum
          group_sum = 0
        else
          group_sum += group
        end
      end
      return ("#{left_half.to_s}.#{(group_sum + running.to_i).to_s}".to_f * sign)
    else
      groups.each do |group|
        group_sum += group
      end
      return (group_sum + running.to_i) * sign
    end
  end

  protected
  def differentiate_float_int(str)
    str =~ /^[0-9]*\.[0-9]+$/ ? str.to_f : str.to_i
  end

end # end module

#
# add the module to the String class
#
class String
  include TextToNumbers
end