import pg from "pg";

const pool = new pg.Pool({
  user: "postgres",
  host: "vscdatabase.cxaogewmsid6.ap-south-1.rds.amazonaws.com",
  database: "service-center",
  password: "Vehicle12345",
  port: 5432,
  ssl: { rejectUnauthorized: false }, // Needed for AWS RDS
});

export default pool;

/*import pg from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const pool = new pg.Pool({ 
    user: 'postgres',
    host: 'localhost',
    database: 'service-center',
    password: 'Dh123456#',
    port: 5432,
});

export default pool;

*/
