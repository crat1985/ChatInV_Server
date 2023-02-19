module utils

import libsodium

fn (mut app App) encrypt(data []u8) []u8 {
	return app.secret_box.encrypt(data)
}

fn (mut app App) encrypt_string(text string) []u8 {
	return app.secret_box.encrypt_string(text)
}

fn (mut app App) decrypt(data []u8) ![]u8 {
	decrypted := app.secret_box.decrypt(data)
	if decrypted.hex().is_blank() {
		return error('Failed to decrypt data')
	}
	return decrypted
}

fn (mut app App) decrypt_string(data []u8) !string {
	decrypted := app.secret_box.decrypt_string(data)
	if decrypted.is_blank() {
		return error('Failed to decrypt data')
	}
	return decrypted
}