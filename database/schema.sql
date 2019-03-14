CREATE TABLE IF NOT EXISTS package_repository (
    repo_id INTEGER PRIMARY KEY
,   repo_url TEXT NOT NULL
,   elm_ver TEXT NOT NULL
,   last_update TEXT
);


CREATE TABLE IF NOT EXISTS package (
    pub_name TEXT PRIMARY KEY
,   repo_id INTEGER NOT NULL REFERENCES package_repository(repo_id) ON DELETE CASCADE ON UPDATE CASCADE
,   publisher TEXT
,   pkg_name TEXT
,   license TEXT
,   summary TEXT
);

CREATE TRIGGER IF NOT EXISTS package_insert
AFTER INSERT ON package FOR EACH ROW
BEGIN
    UPDATE package SET
        publisher = substr(NEW.pub_name, 0, instr(NEW.pub_name, "/")),
        pkg_name = substr(NEW.pub_name, instr(NEW.pub_name, "/") + 1)
    WHERE pub_name = NEW.pub_name;
END;

CREATE TRIGGER IF NOT EXISTS package_update
AFTER UPDATE ON package FOR EACH ROW
BEGIN
    UPDATE package SET
        publisher = substr(NEW.pub_name, 0, instr(NEW.pub_name, "/")),
        pkg_name = substr(NEW.pub_name, instr(NEW.pub_name, "/") + 1)
    WHERE pub_name = NEW.pub_name;
END;


CREATE TABLE IF NOT EXISTS package_release (
    pkg_ver TEXT PRIMARY KEY
,   repo_id INTEGER NOT NULL REFERENCES package_repository(repo_id) ON DELETE CASCADE ON UPDATE CASCADE
,   released INTEGER
);
