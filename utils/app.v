module utils

import net
import db.sqlite

pub struct App {
	pub mut:
	users []User
	accounts_db sqlite.DB
	messages_db sqlite.DB
	port string
	server &net.TcpListener
}