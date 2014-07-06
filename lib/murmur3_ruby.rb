module Murmur3Ruby
  ## MurmurHash3 was written by Austin Appleby, and is placed in the public
  ## domain. The author hereby disclaims copyright to this source code.

  MASK32 = 0xffffffff

  def murmur3_32_rotl(x, r)
    ((x << r) | (x >> (32 - r))) & MASK32
  end


  def murmur3_32_fmix(h)
    h &= MASK32
    h ^= h >> 16
    h = (h * 0x85ebca6b) & MASK32
    h ^= h >> 13
    h = (h * 0xc2b2ae35) & MASK32
    h ^ (h >> 16)
  end

  def murmur3_32__mmix(k1)
    k1 = (k1 * 0xcc9e2d51) & MASK32
    k1 = murmur3_32_rotl(k1, 15)
    (k1 * 0x1b873593) & MASK32
  end

  def murmur3_32(str, seed=0)
    h1 = seed
    numbers = str.unpack('V*C*')
    tailn = str.length % 4
    tail = numbers.slice!(numbers.size - tailn, tailn)
    for k1 in numbers
      h1 ^= murmur3_32__mmix(k1)
      h1 = murmur3_32_rotl(h1, 13)
      h1 = (h1*5 + 0xe6546b64) & MASK32
    end

    unless tail.empty?
      k1 = 0
      tail.reverse_each do |c1|
        k1 = (k1 << 8) | c1
      end
      h1 ^= murmur3_32__mmix(k1)
    end

    h1 ^= str.length
    murmur3_32_fmix(h1)
  end

end
