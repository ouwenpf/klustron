import psycopg2
import mysql.connector

def compare_tables(source_conn, target_conn, source_schema="public", target_schema="public"):
    source_cur = source_conn.cursor()
    target_cur = target_conn.cursor()

    # 获取源库中所有表
    source_cur.execute(f"SELECT table_name FROM information_schema.tables WHERE table_schema = '{source_schema}'")
    source_tables = source_cur.fetchall()

    # 获取目标库中所有表
    target_cur.execute(f"SELECT table_name FROM information_schema.tables WHERE table_schema = '{target_schema}'")
    target_tables = target_cur.fetchall()

    # 检查源库中有的目标库不存在的表
    source_table_names = {table[0] for table in source_tables}
    target_table_names = {table[0] for table in target_tables}

    different_tables_in_source = source_table_names - target_table_names

    if different_tables_in_source:
        print("\nTables present in source but not in target:")
        for table in different_tables_in_source:
            print(table)
    else:
        print("No tables present in source but not in target.")

    # 对比表数据行数
    for table_name in source_table_names.intersection(target_table_names):
        source_cur.execute(f"SELECT COUNT(*) FROM {source_schema}.{table_name}")
        source_row_count = source_cur.fetchone()[0]

        target_cur.execute(f"SELECT COUNT(*) FROM {target_schema}.{table_name}")
        target_row_count = target_cur.fetchone()[0]

        if source_row_count != target_row_count:
            print(f"\nTable: {table_name} - Rows in source: {source_row_count}, Rows in target: {target_row_count}")
            # 如果行数不匹配，你可以在这里添加更多的信息，例如输出具体的行数差异
            # 比如，你可以执行查询获取前几条不匹配的行，并输出

    # 关闭连接
    source_cur.close()
    target_cur.close()

def create_connection(db_type, host, user, password, database, port):
    if db_type == "mysql":
        return mysql.connector.connect(host=host, user=user, password=password, database=database, port=port)
    elif db_type == "postgresql":
        return psycopg2.connect(dbname=database, user=user, password=password, host=host, port=port)
    else:
        raise ValueError("Unsupported database type")

if __name__ == "__main__":
    # 源端连接配置
    source_config = {
        "db_type": "mysql",
        "host": "192.168.0.128",
        "user": "root",
        "password": "123456",
        "database": "arch_basex",
        "port": 63306
    }

    # 目标端连接配置
    target_config = {
        "db_type": "postgresql",
        "host": "192.168.0.176",
        "user": "abc",
        "password": "abc",
        "database": "postgres",
        "port": 47001
    }

    source_schema = "arch_basex"
    target_schema = "arch_basex"

    # 连接到源端和目标端
    source_conn = create_connection(source_config["db_type"], source_config["host"], source_config["user"], source_config["password"], source_config["database"], source_config["port"])
    target_conn = create_connection(target_config["db_type"], target_config["host"], target_config["user"], target_config["password"], target_config["database"], target_config["port"])

    # 比较表的行数
    compare_tables(source_conn, target_conn, source_schema, target_schema)

    # 关闭连接
    source_conn.close()
    target_conn.close()

