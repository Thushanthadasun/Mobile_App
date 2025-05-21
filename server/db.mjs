import pg from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const pool = new pg.Pool({ 
    user: 'postgres',
    host: 'localhost',
    database: 'Vehicle_maintance_System',
    password: 'Dh123456#',
    port: 5432,
});

export default pool;