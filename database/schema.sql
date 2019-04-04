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


-- Count only packages with valid releases for given repositories
CREATE VIEW IF NOT EXISTS repository_summary_view (repo_id, elm_ver, core_pub, pkg_count, last_update) AS
SELECT
    r.repo_id
,   r.elm_ver
,   r.core_pub
,   count(r.elm_ver) AS pkg_count
,   r.last_update
FROM (
    SELECT
        repo_id
    ,   pub_name
    FROM package_release
    GROUP BY
        repo_id
    ,   pub_name
    ,   pkg_ver
    ,   released
    ORDER BY
        repo_id ASC
    ,   pub_name ASC
    ,   pkg_ver DESC
    ,   released DESC
) AS pr
LEFT JOIN repository r ON pr.repo_id = r.repo_id
LEFT JOIN package p ON pr.repo_id = p.repo_id AND pr.pub_name = p.pub_name
GROUP BY
    r.elm_ver
ORDER BY
    r.elm_ver
;


-- All repostiory packages, except repository core publisher packages e.g. elm-lang, elm
-- Core publisher packages have special treatment as 'standard library'
CREATE VIEW IF NOT EXISTS repository_package_summary_view
(elm_ver, pub_name, publisher, pkg_name, pkg_ver, released, license, summary) AS
SELECT
    r.elm_ver
,   p.pub_name
,   p.publisher
,   p.pkg_name
,   pr.pkg_ver
,   pr.released
,   p.license
,   p.summary
FROM (
    SELECT
        repo_id
    ,   pub_name
    ,   pkg_ver
    ,   released
    FROM package_release
    GROUP BY
        repo_id
    ,   pub_name
    ,   pkg_ver
    ,   released
    ORDER BY
        repo_id ASC
    ,   pub_name ASC
    ,   pkg_ver DESC
    ,   released DESC
) AS pr
LEFT JOIN repository r ON pr.repo_id = r.repo_id
LEFT JOIN package p ON pr.repo_id = p.repo_id AND pr.pub_name = p.pub_name
WHERE
    p.publisher NOT IN (SELECT core_pub FROM repository)
;


-- Get core publisher packages with package modules, per repository
CREATE VIEW IF NOT EXISTS elm_package_module_summary_view
(elm_ver, core_pub, pkg_name, latest_version, modules) AS
SELECT
    pkg.elm_ver
,   pkg.core_pub
,   pkg.pkg_name
,   pkg.latest_version
,   group_concat(rdoc.item_name, ",") as modules
FROM (
    SELECT
        p.repo_id
    ,   r.elm_ver
    ,   r.core_pub
    ,   p.pub_name
    ,   p.pkg_name
    ,   p.latest_version
    FROM (
        SELECT
            repo_id, elm_ver, core_pub
        FROM repository
        ORDER BY elm_ver
    ) AS r
    LEFT JOIN package p ON r.repo_id = p.repo_id AND r.core_pub = p.publisher
) AS pkg
LEFT JOIN release_doc rdoc ON pkg.repo_id = rdoc.repo_id AND pkg.pub_name = rdoc.pub_name AND pkg.latest_version = rdoc.pkg_ver
WHERE rdoc.item_path = "/" || rdoc.item_name
GROUP BY pkg.elm_ver, pkg.pkg_name, pkg.latest_version
;
