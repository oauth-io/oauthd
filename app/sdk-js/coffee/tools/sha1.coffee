
#
# * A JavaScript implementation of the Secure Hash Algorithm, SHA-1, as defined
# * in FIPS 180-1
# * Version 2.2 Copyright Paul Johnston 2000 - 2009.
# * Other contributors: Greg Holt, Andrew Kepert, Ydnar, Lostinet
# * Distributed under the BSD License
# * See http://pajhome.org.uk/crypt/md5 for details.
# 

#
# * Configurable variables. You may need to tweak these to be compatible with
# * the server-side, but the defaults work in most cases.
# 
hexcase = 0 # hex output format. 0 - lowercase; 1 - uppercase
b64pad = "" # base-64 pad character. "=" for strict RFC compliance

#
# * These are the functions you'll usually want to call
# * They take string arguments and return either hex or base-64 encoded strings
# 
### istanbul ignore next ###
module.exports =
	hex_sha1: (s) ->
		@rstr2hex @rstr_sha1(@str2rstr_utf8(s))

	b64_sha1: (s) ->
		@rstr2b64 @rstr_sha1(@str2rstr_utf8(s))

	any_sha1: (s, e) ->
		@rstr2any @rstr_sha1(@str2rstr_utf8(s)), e

	hex_hmac_sha1: (k, d) ->
		@rstr2hex @rstr_hmac_sha1(@str2rstr_utf8(k), @str2rstr_utf8(d))

	b64_hmac_sha1: (k, d) ->
		@rstr2b64 @rstr_hmac_sha1(@str2rstr_utf8(k), @str2rstr_utf8(d))

	any_hmac_sha1: (k, d, e) ->
		@rstr2any @rstr_hmac_sha1(@str2rstr_utf8(k), @str2rstr_utf8(d)), e

	
	#
	#     * Perform a simple self-test to see if the VM is working
	#     
	sha1_vm_test: ->
		thishex_sha1("abc").toLowerCase() is "a9993e364706816aba3e25717850c26c9cd0d89d"

	
	#
	#     * Calculate the SHA1 of a raw string
	#     
	rstr_sha1: (s) ->
		@binb2rstr @binb_sha1(@rstr2binb(s), s.length * 8)

	
	#
	#     * Calculate the HMAC-SHA1 of a key and some data (raw strings)
	#     
	rstr_hmac_sha1: (key, data) ->
		bkey = @rstr2binb(key)
		bkey = @binb_sha1(bkey, key.length * 8)  if bkey.length > 16
		ipad = Array(16)
		opad = Array(16)
		i = 0

		while i < 16
			ipad[i] = bkey[i] ^ 0x36363636
			opad[i] = bkey[i] ^ 0x5C5C5C5C
			i++
		hash = @binb_sha1(ipad.concat(@rstr2binb(data)), 512 + data.length * 8)
		@binb2rstr @binb_sha1(opad.concat(hash), 512 + 160)

	
	#
	#     * Convert a raw string to a hex string
	#     
	rstr2hex: (input) ->
		try
			hexcase
		catch e
			hexcase = 0
		hex_tab = (if hexcase then "0123456789ABCDEF" else "0123456789abcdef")
		output = ""
		x = undefined
		i = 0

		while i < input.length
			x = input.charCodeAt(i)
			output += hex_tab.charAt((x >>> 4) & 0x0F) + hex_tab.charAt(x & 0x0F)
			i++
		output

	
	#
	#     * Convert a raw string to a base-64 string
	#     
	rstr2b64: (input) ->
		try
			b64pad
		catch e
			b64pad = ""
		tab = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
		output = ""
		len = input.length
		i = 0

		while i < len
			triplet = (input.charCodeAt(i) << 16) | ((if i + 1 < len then input.charCodeAt(i + 1) << 8 else 0)) | ((if i + 2 < len then input.charCodeAt(i + 2) else 0))
			j = 0

			while j < 4
				if i * 8 + j * 6 > input.length * 8
					output += b64pad
				else
					output += tab.charAt((triplet >>> 6 * (3 - j)) & 0x3F)
				j++
			i += 3
		output

	
	#
	#     * Convert a raw string to an arbitrary string encoding
	#     
	rstr2any: (input, encoding) ->
		divisor = encoding.length
		remainders = Array()
		i = undefined
		q = undefined
		x = undefined
		quotient = undefined
		
		# Convert to an array of 16-bit big-endian values, forming the dividend 
		dividend = Array(Math.ceil(input.length / 2))
		i = 0
		while i < dividend.length
			dividend[i] = (input.charCodeAt(i * 2) << 8) | input.charCodeAt(i * 2 + 1)
			i++
		
		#
		#         * Repeatedly perform a long division. The binary array forms the dividend,
		#         * the length of the encoding is the divisor. Once computed, the quotient
		#         * forms the dividend for the next step. We stop when the dividend is zero.
		#         * All remainders are stored for later use.
		#         
		while dividend.length > 0
			quotient = Array()
			x = 0
			i = 0
			while i < dividend.length
				x = (x << 16) + dividend[i]
				q = Math.floor(x / divisor)
				x -= q * divisor
				quotient[quotient.length] = q  if quotient.length > 0 or q > 0
				i++
			remainders[remainders.length] = x
			dividend = quotient
		
		# Convert the remainders to the output string 
		output = ""
		i = remainders.length - 1
		while i >= 0
			output += encoding.charAt(remainders[i])
			i--
		
		# Append leading zero equivalents 
		full_length = Math.ceil(input.length * 8 / (Math.log(encoding.length) / Math.log(2)))
		i = output.length
		while i < full_length
			output = encoding[0] + output
			i++
		output

	
	#
	#     * Encode a string as utf-8.
	#     * For efficiency, this assumes the input is valid utf-16.
	#     
	str2rstr_utf8: (input) ->
		output = ""
		i = -1
		x = undefined
		y = undefined
		while ++i < input.length
			
			# Decode utf-16 surrogate pairs 
			x = input.charCodeAt(i)
			y = (if i + 1 < input.length then input.charCodeAt(i + 1) else 0)
			if 0xD800 <= x and x <= 0xDBFF and 0xDC00 <= y and y <= 0xDFFF
				x = 0x10000 + ((x & 0x03FF) << 10) + (y & 0x03FF)
				i++
			
			# Encode output as utf-8 
			if x <= 0x7F
				output += String.fromCharCode(x)
			else if x <= 0x7FF
				output += String.fromCharCode(0xC0 | ((x >>> 6) & 0x1F), 0x80 | (x & 0x3F))
			else if x <= 0xFFFF
				output += String.fromCharCode(0xE0 | ((x >>> 12) & 0x0F), 0x80 | ((x >>> 6) & 0x3F), 0x80 | (x & 0x3F))
			else output += String.fromCharCode(0xF0 | ((x >>> 18) & 0x07), 0x80 | ((x >>> 12) & 0x3F), 0x80 | ((x >>> 6) & 0x3F), 0x80 | (x & 0x3F))  if x <= 0x1FFFFF
		output

	
	#
	#     * Encode a string as utf-16
	#     
	str2rstr_utf16le: (input) ->
		output = ""
		i = 0

		while i < input.length
			output += String.fromCharCode(input.charCodeAt(i) & 0xFF, (input.charCodeAt(i) >>> 8) & 0xFF)
			i++
		output

	str2rstr_utf16be: (input) ->
		output = ""
		i = 0

		while i < input.length
			output += String.fromCharCode((input.charCodeAt(i) >>> 8) & 0xFF, input.charCodeAt(i) & 0xFF)
			i++
		output

	
	#
	#     * Convert a raw string to an array of big-endian words
	#     * Characters >255 have their high-byte silently ignored.
	#     
	rstr2binb: (input) ->
		output = Array(input.length >> 2)
		i = 0

		while i < output.length
			output[i] = 0
			i++
		i = 0

		while i < input.length * 8
			output[i >> 5] |= (input.charCodeAt(i / 8) & 0xFF) << (24 - i % 32)
			i += 8
		output

	
	#
	#     * Convert an array of big-endian words to a string
	#     
	binb2rstr: (input) ->
		output = ""
		i = 0

		while i < input.length * 32
			output += String.fromCharCode((input[i >> 5] >>> (24 - i % 32)) & 0xFF)
			i += 8
		output

	
	#
	#     * Calculate the SHA-1 of an array of big-endian words, and a bit length
	#     
	binb_sha1: (x, len) ->
		
		# append padding 
		x[len >> 5] |= 0x80 << (24 - len % 32)
		x[((len + 64 >> 9) << 4) + 15] = len
		w = Array(80)
		a = 1732584193
		b = -271733879
		c = -1732584194
		d = 271733878
		e = -1009589776
		i = 0

		while i < x.length
			olda = a
			oldb = b
			oldc = c
			oldd = d
			olde = e
			j = 0

			while j < 80
				if j < 16
					w[j] = x[i + j]
				else
					w[j] = @bit_rol(w[j - 3] ^ w[j - 8] ^ w[j - 14] ^ w[j - 16], 1)
				t = @safe_add(@safe_add(@bit_rol(a, 5), @sha1_ft(j, b, c, d)), @safe_add(@safe_add(e, w[j]), @sha1_kt(j)))
				e = d
				d = c
				c = @bit_rol(b, 30)
				b = a
				a = t
				j++
			a = @safe_add(a, olda)
			b = @safe_add(b, oldb)
			c = @safe_add(c, oldc)
			d = @safe_add(d, oldd)
			e = @safe_add(e, olde)
			i += 16
		Array a, b, c, d, e

	
	#
	#     * Perform the appropriate triplet combination function for the current
	#     * iteration
	#     
	sha1_ft: (t, b, c, d) ->
		return (b & c) | ((~b) & d)  if t < 20
		return b ^ c ^ d  if t < 40
		return (b & c) | (b & d) | (c & d)  if t < 60
		b ^ c ^ d

	
	#
	#     * Determine the appropriate additive constant for the current iteration
	#     
	sha1_kt: (t) ->
		(if (t < 20) then 1518500249 else (if (t < 40) then 1859775393 else (if (t < 60) then -1894007588 else -899497514)))

	
	#
	#     * Add integers, wrapping at 2^32. This uses 16-bit operations internally
	#     * to work around bugs in some JS interpreters.
	#     
	safe_add: (x, y) ->
		lsw = (x & 0xFFFF) + (y & 0xFFFF)
		msw = (x >> 16) + (y >> 16) + (lsw >> 16)
		(msw << 16) | (lsw & 0xFFFF)

	
	#
	#     * Bitwise rotate a 32-bit number to the left.
	#     
	bit_rol: (num, cnt) ->
		(num << cnt) | (num >>> (32 - cnt))

	create_hash: ->
		hash = @b64_sha1((new Date()).getTime() + ":" + Math.floor(Math.random() * 9999999))
		hash.replace(/\+/g, "-").replace(/\//g, "_").replace /\=+$/, ""
