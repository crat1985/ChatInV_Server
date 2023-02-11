module utils

import db.sqlite
import net

pub struct App {
	pub mut:
	users []User
	db sqlite.DB
	port string
	server &net.TcpListener
}