import sqlite3

db_path = '/home/akash/Desktop/IDP/offline_tutor_app/.dart_tool/sqflite_common_ffi/databases/offline_tutor_stage1.db'
try:
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    cursor.execute('SELECT COUNT(*) FROM material_packs')
    packs_count = cursor.fetchone()[0]

    cursor.execute('SELECT COUNT(*) FROM rag_chunks')
    rag_count = cursor.fetchone()[0]

    cursor.execute('SELECT COUNT(*) FROM rag_chunks_fts')
    fts_count = cursor.fetchone()[0]

    print(f'PACKS_AFTER={packs_count}')
    print(f'RAG_CHUNKS_AFTER={rag_count}')
    print(f'FTS_ROWS_AFTER={fts_count}')
    
    print('\n[RAG_VERIFY] ==== RETRIEVAL VERIFICATION ====')
    queries = [
        'arithmetic progression',
        'quadrilaterals',
        'gravitation',
        'constitutional design',
        'prime numbers'
    ]

    for q in queries:
        print(f'[RAG_VERIFY] QUERY={q}')
        terms = " ".join([t + "*" for t in q.lower().split() if len(t) > 2])
        try:
            cursor.execute('''
                SELECT rc.id, rc.source_title, -1.0 as score
                FROM rag_chunks rc
                INNER JOIN rag_chunks_fts fts ON fts.id = rc.id
                WHERE rag_chunks_fts MATCH ?
                LIMIT 4
            ''', (terms,))
            rows = cursor.fetchall()
            print(f'FTS_MATCHES={len(rows)}')
            if rows:
                print(f"[RAG_VERIFY] TOP_SCORE={rows[0][2]}")
        except Exception as e:
            print(f'[RAG_VERIFY] FTS_ERROR={e}')

    conn.close()
except Exception as e:
    print(f"Error: {e}")
