module encrypt

import crypto.aes
import crypto.cipher

fn encrypt(mut src []u8, key []u8, iv []u8) {
	block := aes.new_cipher(key)
	mut mode := cipher.new_ofb(block, iv)
	mode.xor_key_stream(mut src, src.clone())
}

fn encrypt_string(text string, key []u8, iv []u8) string {
	mut src := text.bytes()
	encrypt(mut src, key, iv)
	return src
}
