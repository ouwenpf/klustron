import psycopg2

def compare_tables(source_conn, target_conn, schema="public"):
    source_cur = source_conn.cursor()
    target_cur = target_conn.cursor()

    # 获取源库中所有表
    source_cur.execute(f"SELECT table_name FROM information_schema.tables WHERE table_schema = '{schema}'")
    source_tables = source_cur.fetchall()

    # 获取目标库中所有表
    target_cur.execute(f"SELECT table_name FROM information_schema.tables WHERE table_schema = '{schema}'")
    target_tables = target_cur.fetchall()

    # 检查源库中有的目标库不存在的表
    source_table_names = {table[0] for table in source_tables}
    target_table_names = {table[0] for table in target_tables}

    different_tables_in_source = source_table_names - target_table_names

    if different_tables_in_source:
        print("\nTables present in source but not in target:")
        for table in different_tables_in_source:
            print(table)

    # 对比表数据行数
    for table_name in source_table_names.intersection(target_table_names):
        source_cur.execute(f"SELECT COUNT(*) FROM {schema}.{table_name}")
        source_row_count = source_cur.fetchone()[0]

        target_cur.execute(f"SELECT COUNT(*) FROM {schema}.{table_name}")
        target_row_count = target_cur.fetchone()[0]

        if source_row_count != target_row_count:
            print(f"\nTable: {table_name} - Rows in source: {source_row_count}, Rows in target: {target_row_count}")

    # 关闭连接
    source_cur.close()
    target_cur.close()

if __name__ == "__main__":
    source_db = "testdb"
    source_user = "postgres"
    source_password = "postgres"
    source_host = "172.16.128.115"
    source_port = "5432"
    
    target_db = "kaishi"
    target_user = "abc"
    target_password = "abc"
    target_host = "192.168.0.176"
    target_port = "47001"

    source_schema = "public"
    target_schema = "public"

    # 连接到第一个数据库-源端
    source_conn = psycopg2.connect(dbname=source_db, user=source_user, password=source_password, host=source_host, port=source_port, options=f"-c search_path={source_schema}")
    
    # 连接到第二个数据库-目标端
    target_conn = psycopg2.connect(dbname=target_db, user=target_user, password=target_password, host=target_host, port=target_port, options=f"-c search_path={target_schema}")

    # 比较表的行数
    compare_tables(source_conn, target_conn, source_schema)

    # 关闭连接
    source_conn.close()
    target_conn.close()
