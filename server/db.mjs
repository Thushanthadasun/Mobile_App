import pg from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const pool = new pg.Pool({ 
    user: 'postgres',
    host: 'localhost',
    database: 'service-center',
    password: '1111111111',
    port: 5432,
});

export default pool;