module utils

import db.sqlite

[table: 'account']
pub struct Account {
	id int [primary; sql: serial]
	pseudo string [nonnull]
	password string [nonnull]
}

pub fn init_database() sqlite.DB {
	db := sqlite.connect("accounts.db") or {
		panic(err)
	}

	sql db {
		create table Account
	}

	return db
}

pub fn delete_account(db sqlite.DB, account Account) {
	sql db {
		delete from Account where pseudo == account.pseudo
	}
}

pub fn get_number_of_accounts(db sqlite.DB) int {
	return sql db {
		select count from Account
	}
}

pub fn get_account_by_pseudo(db sqlite.DB, pseudo string) Account {
	return sql db {
		select from Account where pseudo == pseudo limit 1
	}
}

pub fn insert_account(db sqlite.DB, account Account) {
	if account_exists(db, account.pseudo) {
		println("ALREADY EXISTS")
		return
	}
	sql db {
		insert account into Account
	}
}

pub fn get_all_accounts(db sqlite.DB) []Account {
	accounts := sql db {
		select from Account
	}
	return accounts
}

pub fn account_exists(db sqlite.DB, pseudo string) bool {
	account := get_account_by_pseudo(db, pseudo)
	if account.id == 0 {
		return false
	}
	return true
}
