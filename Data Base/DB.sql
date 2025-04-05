CREATE DATABASE VehicleMaintenanceSystem;

\c VehicleMaintenanceSystem;

-- Customers Table
CREATE TABLE Customers (
    customer_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    phone_number VARCHAR(15) NOT NULL
);

-- Vehicles Table
CREATE TABLE Vehicles (
    vehicle_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL,
    vehicle_type VARCHAR(50) NOT NULL,
    license_plate VARCHAR(20) UNIQUE NOT NULL,
    model VARCHAR(50) NOT NULL,
    make_year INTEGER NOT NULL,  -- Changed from YEAR to INTEGER for compatibility
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id) ON DELETE CASCADE
);

-- Services Table
CREATE TABLE Services (
    service_id SERIAL PRIMARY KEY,
    service_name VARCHAR(100) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    description TEXT,
    duration INT NOT NULL -- Duration of the service in minutes
);

-- Schedules Table
CREATE TABLE Schedules (
    schedule_id SERIAL PRIMARY KEY,
    vehicle_id INT NOT NULL,
    service_id INT NOT NULL,
    date DATE NOT NULL,
    start_time TIME NOT NULL, -- Starting time of the schedule
    end_time TIME NOT NULL,   -- Ending time of the schedule
    status VARCHAR(20) DEFAULT 'Pending', -- Replace ENUM with VARCHAR for portability
    FOREIGN KEY (vehicle_id) REFERENCES Vehicles(vehicle_id) ON DELETE CASCADE,
    FOREIGN KEY (service_id) REFERENCES Services(service_id) ON DELETE CASCADE
);

-- Invoices Table (1:1 with Schedules)
CREATE TABLE Invoices (
    invoice_id SERIAL PRIMARY KEY,
    schedule_id INT NOT NULL UNIQUE, -- Ensuring 1:1 relationship with Schedules
    payment_status VARCHAR(10) DEFAULT 'Unpaid',
    amount_paid DECIMAL(10, 2) DEFAULT 0.00,
    date_paid DATE,
    FOREIGN KEY (schedule_id) REFERENCES Schedules(schedule_id) ON DELETE CASCADE
);

-- Payments Table (1:1 with Invoices)
CREATE TABLE Payments (
    payment_id SERIAL PRIMARY KEY,
    invoice_id INT NOT NULL UNIQUE, -- Ensuring 1:1 relationship with Invoices
    payment_method VARCHAR(10) NOT NULL CHECK (payment_method IN ('Card', 'Cash', 'Online')),
    amount DECIMAL(10, 2) NOT NULL,
    transaction_date DATE NOT NULL,
    FOREIGN KEY (invoice_id) REFERENCES Invoices(invoice_id) ON DELETE CASCADE
);

-- Admins Table
CREATE TABLE Admins (
    admin_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL
);