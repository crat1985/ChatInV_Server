module utils

fn (mut app App) is_pseudo_connected(username string) bool {
	for user in app.users {
		if user.pseudo == username {
			return true
		}
	}
	return false
}