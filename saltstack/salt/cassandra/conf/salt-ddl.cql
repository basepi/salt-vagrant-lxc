    CREATE KEYSPACE IF NOT EXISTS salt
        WITH replication = {'class': 'SimpleStrategy', 'replication_factor' : 1};

    CREATE USER IF NOT EXISTS salt WITH PASSWORD 'salt' NOSUPERUSER;

    GRANT ALL ON KEYSPACE salt TO salt;

    USE salt;

    CREATE TABLE IF NOT EXISTS salt.salt_returns (
        customer_id uuid,
        jid text,
        minion_id text,
        fun text,
        alter_time timestamp,
        full_ret text,
        return text,
        success boolean,
        PRIMARY KEY (customer_id, jid, minion_id, fun)
    ) WITH CLUSTERING ORDER BY (jid ASC, minion_id ASC, fun ASC)
        AND comment = 'Salt job results. Required for minimal Salt returner support';
    CREATE INDEX IF NOT EXISTS salt_returns_minion_id ON salt.salt_returns (minion_id);
    CREATE INDEX IF NOT EXISTS salt_returns_fun ON salt.salt_returns (fun);

    CREATE TABLE IF NOT EXISTS salt.jids (
        customer_id uuid,
        jid text,
        load text,
        PRIMARY KEY (customer_id, jid)
    ) WITH CLUSTERING ORDER BY (jid ASC)
        AND comment = 'Salt jobs. Required for Master Job Cache and External Job Cache support';
    CREATE INDEX IF NOT EXISTS jids_jid ON salt.jids (jid);

    CREATE TABLE IF NOT EXISTS salt.minions (
        customer_id uuid,
        minion_id text,
        last_fun text,
        PRIMARY KEY (customer_id, minion_id)
    ) WITH CLUSTERING ORDER BY (minion_id ASC)
        AND comment = 'The last function called by each minion.';
    CREATE INDEX IF NOT EXISTS minions_last_fun ON salt.minions (last_fun);

    CREATE TABLE IF NOT EXISTS salt.salt_events (
        customer_id uuid,
        id timeuuid,
        tag text,
        alter_time timestamp,
        data text,
        master_id text,
        PRIMARY KEY (customer_id, id, tag)
    ) WITH CLUSTERING ORDER BY (id ASC, tag ASC)
        AND comment = 'All Salt events.';
    CREATE INDEX IF NOT EXISTS tag ON salt.salt_events (tag);

    CREATE TABLE IF NOT EXISTS salt.master_config (
        customer_id uuid,
        master text,
        key text,
        val text,
        PRIMARY KEY (customer_id, master)
    ) WITH CLUSTERING ORDER BY (master ASC)
        AND comment = 'Master configuration data.';

    CREATE TABLE IF NOT EXISTS salt.cmd (
        customer_id uuid,
        jid text,
        cmd text,
        masters_to list<text>,
        masters_done list<text>,
        low text,
        PRIMARY KEY (customer_id, jid, cmd)
    ) WITH CLUSTERING ORDER BY (jid ASC, cmd ASC)
        AND comment = 'Command Execution table.';
    CREATE INDEX IF NOT EXISTS cmd ON salt.cmd(cmd);

    CREATE TABLE IF NOT EXISTS salt.minion_key (
        customer_id uuid,
        master text,
        accepted list<text>,
        rejected list<text>,
        pending list<text>,
        denied list<text>,
        PRIMARY KEY (customer_id, master)
    ) WITH CLUSTERING ORDER BY (master ASC)
        AND comment = 'Minion Key tables';

    CREATE TABLE IF NOT EXISTS salt.minions_cache (
        customer_id uuid,
        master text,
        minion text,
        grains text,
        PRIMARY KEY (customer_id, master, minion)
    ) WITH CLUSTERING ORDER BY (master ASC, minion ASC)
        AND comment = 'Minion data cache';
