module utils

import net
import db.sqlite
import libsodium

pub struct App {
pub mut:
	users       []User
	private_key libsodium.PrivateKey
	accounts_db sqlite.DB
	messages_db sqlite.DB
	port        string
	server      &net.TcpListener
}
