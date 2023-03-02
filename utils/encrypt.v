module utils

pub fn (mut user User) encrypt_string(text string) []u8 {
	return user.box.encrypt_string(text)
}

pub fn (mut user User) decrypt_string(data []u8) !string {
	decrypted := user.box.decrypt_string(data)
	if decrypted.is_blank() {
		return error('Failed to decrypt data')
	}
	return decrypted
}
