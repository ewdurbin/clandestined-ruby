#include "ruby.h"

#include <stdint.h>
#include <string.h>

// MurmurHash3 was written by Austin Appleby, and is placed in the public
// domain. The author hereby disclaims copyright to this source code.

uint32_t murmur3_32(const char *key, uint32_t len, uint32_t seed) {
    static const uint32_t c1 = 0xcc9e2d51;
    static const uint32_t c2 = 0x1b873593;
    static const uint32_t r1 = 15;
    static const uint32_t r2 = 13;
    static const uint32_t m = 5;
    static const uint32_t n = 0xe6546b64;
 
    uint32_t hash = seed;
 
    const int nblocks = len / 4;
    const uint32_t *blocks = (const uint32_t *) key;
    int i;
    for (i = 0; i < nblocks; i++) {
        uint32_t k = blocks[i];
        k *= c1;
        k = (k << r1) | (k >> (32 - r1));
        k *= c2;
 
        hash ^= k;
        hash = ((hash << r2) | (hash >> (32 - r2))) * m + n;
    }
 
    const uint8_t *tail = (const uint8_t *) (key + nblocks * 4);
    uint32_t k1 = 0;
 
    switch (len & 3) {
    case 3:
        k1 ^= tail[2] << 16;
    case 2:
        k1 ^= tail[1] << 8;
    case 1:
        k1 ^= tail[0];
 
        k1 *= c1;
        k1 = (k1 << r1) | (k1 >> (32 - r1));
        k1 *= c2;
        hash ^= k1;
    }
 
    hash ^= len;
    hash ^= (hash >> 16);
    hash *= 0x85ebca6b;
    hash ^= (hash >> 13);
    hash *= 0xc2b2ae35;
    hash ^= (hash >> 16);
 
    return hash;
}

static VALUE rb_mumur3_32(int argc, VALUE* argv, VALUE self) {
    VALUE rstr;
    if (argc == 0 || argc > 2) {
	rb_raise(rb_eArgError, "accept 1 or 2 arguments: (string[, seed])");
    }
    rstr = argv[0];
    StringValue(rstr);
    uint32_t value = murmur3_32(RSTRING_PTR(rstr), RSTRING_LEN(rstr), argc == 1 ? 0 : NUM2UINT(argv[1]));
    return UINT2NUM(value);
}

VALUE Murmur3Native = Qnil;

void Init_murmur3_native();

void Init_murmur3_native() {
    VALUE Murmur3Native = rb_define_module("Murmur3Native");
    rb_define_module_function(Murmur3Native, "murmur3_32", rb_mumur3_32, -1);
}
