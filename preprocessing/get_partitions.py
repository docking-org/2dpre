import os
import sys
import psycopg2

database = "postgresql://zincuser@10.20.1.17:5534/zinc22_common"
digits="0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
mp_range = ["M500", "M400", "M300", "M200", "M100", "M000", "P000", "P010", "P020", "P030", "P040", "P050", "P060", "P070", "P080", "P090", "P100", "P110", "P120", "P130", "P140", "P150", "P160", "P170", "P180", "P190", "P200", "P210", "P220", "P230", "P240", "P250", "P260", "P270", "P280", "P290", "P300", "P310", "P320", "P330", "P340", "P350", "P360", "P370", "P380", "P390", "P400", "P410", "P420", "P430", "P440", "P450", "P460", "P470", "P480", "P490", "P500", "P600", "P700", "P800", "P900"]
digits_map = { digit : i for i, digit in enumerate(digits) }
b62_table = [62**i for i in range(12)]


if __name__ == '__main__':
    connection = psycopg2.connect(database)
    cursor = connection.cursor()
    cursor.execute("SELECT partition_id from database_partitions;")
    rows = cursor.fetchall()
    partitions = [row[0] for row in rows]
    print(partitions)