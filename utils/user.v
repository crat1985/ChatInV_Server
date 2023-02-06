module utils

import net

pub struct User {
	net.TcpConn
	pub mut:
		pseudo string
}
