-- minimal SQLite version 3.24

CREATE TABLE IF NOT EXISTS package_repository (
    repo_id INTEGER PRIMARY KEY
,   repo_url TEXT NOT NULL
,   elm_ver TEXT NOT NULL
,   last_update TEXT
);


CREATE TABLE IF NOT EXISTS package (
    pub_name TEXT NOT NULL
,   repo_id INTEGER NOT NULL REFERENCES package_repository(repo_id) ON DELETE CASCADE ON UPDATE CASCADE
,   publisher TEXT
,   pkg_name TEXT
,   license TEXT
,   summary TEXT
,   PRIMARY KEY (pub_name, repo_id)
);


CREATE TABLE IF NOT EXISTS package_release (
    pub_name TEXT NOT NULL
,   pkg_ver TEXT NOT NULL
,   released INTEGER
,   repo_id INTEGER NOT NULL REFERENCES package_repository(repo_id) ON DELETE CASCADE ON UPDATE CASCADE
,   PRIMARY KEY (pub_name, pkg_ver)
);
