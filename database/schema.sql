-- minimal SQLite version 3.24

CREATE TABLE IF NOT EXISTS repository (
    repo_id INTEGER PRIMARY KEY
,   repo_url TEXT NOT NULL
,   meta_url TEXT NOT NULL
,   elm_ver TEXT NOT NULL
,   core_pub TEXT NOT NULL
,   dep_url TEXT NOT NULL
,   dep_json TEXT NO NULL
,   last_update TEXT
);


CREATE TABLE IF NOT EXISTS package (
    repo_id INTEGER NOT NULL REFERENCES package_repository(repo_id) ON DELETE CASCADE ON UPDATE CASCADE
,   pub_name TEXT NOT NULL
,   publisher TEXT
,   pkg_name TEXT
,   license TEXT
,   summary TEXT
,   latest_version TEXT
,   PRIMARY KEY(repo_id, pub_name)
);


CREATE TABLE IF NOT EXISTS package_release (
    repo_id INTEGER NOT NULL REFERENCES package_repository(repo_id) ON DELETE CASCADE ON UPDATE CASCADE
,   pub_name TEXT NOT NULL
,   pkg_ver TEXT NOT NULL
,   released INTEGER
,   PRIMARY KEY(repo_id, pub_name, pkg_ver)
);


CREATE TABLE IF NOT EXISTS release_readme (
    repo_id INTEGER NOT NULL REFERENCES package_repository(repo_id) ON DELETE CASCADE ON UPDATE CASCADE
,   pub_name TEXT NOT NULL
,   pkg_ver TEXT NOT NULL
,   readme TEXT
,   PRIMARY KEY(repo_id, pub_name, pkg_ver)
);

-- Item Paths
-- /<module>                                        | item_name, item_comment
-- /<module>/aliases/<alias>                        | item_name, item_comment, item_type
-- /<module>/aliases/<alias>/args/<arg>             | item_name
-- /<module>/binops/<name>                          | item_name, item_comment, item_type, item_assoc, item_prec
-- /<module>/unions/<name>                          | item_name, item_comment
-- /<module>/unions/<name>/args/<arg>               | item_name
-- /<module>/unions/<name>/cases/<case>             | item_name
-- /<module>/unions/<name>/cases/<case>/args/<arg>  | item_name
-- /<module>/values/<value>                         | item_name, item_comment, item_type

CREATE TABLE IF NOT EXISTS release_doc (
    repo_id INTEGER NOT NULL REFERENCES package_repository(repo_id) ON DELETE CASCADE ON UPDATE CASCADE
,   pub_name TEXT NOT NULL
,   pkg_ver TEXT NOT NULL
,   item_path TEXT NOT NULL
,   item_index INTEGER DEFAULT 0
,   item_name TEXT NOT NULL
,   item_comment TEXT
,   item_type TEXT
,   item_assoc TEXT
,   item_prec INTEGER
,   PRIMARY KEY(repo_id, pub_name, pkg_ver, item_path)
);


CREATE TABLE IF NOT EXISTS release_dep (
    repo_id INTEGER NOT NULL REFERENCES package_repository(repo_id) ON DELETE CASCADE ON UPDATE CASCADE
,   pub_name TEXT NOT NULL
,   pkg_ver TEXT NOT NULL
,   dep_pub TEXT NOT NULL
,   dep_guard TEXT NOT NULL
,   PRIMARY KEY (repo_id, pub_name, pkg_ver, dep_pub)
);
