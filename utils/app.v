module utils

import net
import db.sqlite

pub struct App {
	pub mut:
	users []User
	db sqlite.DB
	port string
	server &net.TcpListener
}