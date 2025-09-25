-- Create the database
CREATE DATABASE IF NOT EXISTS ClinicBookingSystem;
USE ClinicBookingSystem;

-- Drop tables if they exist (for clean recreation)
DROP TABLE IF EXISTS Prescriptions;
DROP TABLE IF EXISTS MedicalRecords;
DROP TABLE IF EXISTS Appointments;
DROP TABLE IF EXISTS DoctorSchedules;
DROP TABLE IF EXISTS Doctors;
DROP TABLE IF EXISTS Patients;
DROP TABLE IF EXISTS Departments;
DROP TABLE IF EXISTS Medications;

-- =====================================================
-- REFERENCE TABLES
-- =====================================================

-- Departments table for medical specializations
CREATE TABLE Departments (
    department_id INT PRIMARY KEY AUTO_INCREMENT,
    department_name VARCHAR(100) NOT NULL UNIQUE,
    department_head VARCHAR(100),
    location VARCHAR(100),
    phone VARCHAR(20),
    description TEXT,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Medications table for prescription management
CREATE TABLE Medications (
    medication_id INT PRIMARY KEY AUTO_INCREMENT,
    medication_name VARCHAR(150) NOT NULL UNIQUE,
    generic_name VARCHAR(150),
    manufacturer VARCHAR(100),
    dosage_form ENUM('Tablet', 'Capsule', 'Liquid', 'Injection', 'Cream', 'Drops') NOT NULL,
    strength VARCHAR(50),
    unit_price DECIMAL(8,2),
    description TEXT,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Check constraints
    CONSTRAINT chk_medication_price CHECK (unit_price >= 0),
    CONSTRAINT chk_medication_name CHECK (LENGTH(TRIM(medication_name)) > 0)
);

-- =====================================================
-- PEOPLE TABLES
-- =====================================================

-- Patients table
CREATE TABLE Patients (
    patient_id INT PRIMARY KEY AUTO_INCREMENT,
    patient_number VARCHAR(20) NOT NULL UNIQUE,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender ENUM('Male', 'Female', 'Other') NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100),
    address TEXT NOT NULL,
    emergency_contact_name VARCHAR(100),
    emergency_contact_phone VARCHAR(20),
    blood_type ENUM('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'),
    allergies TEXT,
    medical_history TEXT,
    insurance_provider VARCHAR(100),
    insurance_policy_number VARCHAR(50),
    registration_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    is_active BOOLEAN DEFAULT TRUE,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Check constraints
    CONSTRAINT chk_patient_names CHECK (
        LENGTH(TRIM(first_name)) > 0 AND 
        LENGTH(TRIM(last_name)) > 0
    ),
    CONSTRAINT chk_patient_email CHECK (email IS NULL OR email LIKE '%@%.%'),
    CONSTRAINT chk_patient_dob CHECK (date_of_birth < CURRENT_DATE)
);

-- Doctors table
CREATE TABLE Doctors (
    doctor_id INT PRIMARY KEY AUTO_INCREMENT,
    doctor_number VARCHAR(20) NOT NULL UNIQUE,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    specialization VARCHAR(100) NOT NULL,
    department_id INT NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    license_number VARCHAR(50) NOT NULL UNIQUE,
    qualification VARCHAR(200),
    experience_years INT,
    consultation_fee DECIMAL(8,2) NOT NULL,
    address TEXT,
    hire_date DATE NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Foreign key constraint
    CONSTRAINT fk_doctors_department 
        FOREIGN KEY (department_id) REFERENCES Departments(department_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    
    -- Check constraints
    CONSTRAINT chk_doctor_names CHECK (
        LENGTH(TRIM(first_name)) > 0 AND 
        LENGTH(TRIM(last_name)) > 0
    ),
    CONSTRAINT chk_doctor_email CHECK (email LIKE '%@%.%'),
    CONSTRAINT chk_doctor_fee CHECK (consultation_fee > 0),
    CONSTRAINT chk_doctor_experience CHECK (experience_years >= 0)
);

-- =====================================================
-- SCHEDULING TABLES
-- =====================================================

-- Doctor Schedules table
CREATE TABLE DoctorSchedules (
    schedule_id INT PRIMARY KEY AUTO_INCREMENT,
    doctor_id INT NOT NULL,
    day_of_week ENUM('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday') NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    max_patients_per_hour INT DEFAULT 4,
    is_available BOOLEAN DEFAULT TRUE,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Foreign key constraint
    CONSTRAINT fk_schedules_doctor 
        FOREIGN KEY (doctor_id) REFERENCES Doctors(doctor_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    
    -- Unique constraint to prevent overlapping schedules
    CONSTRAINT uk_doctor_schedule UNIQUE (doctor_id, day_of_week, start_time),
    
    -- Check constraints
    CONSTRAINT chk_schedule_times CHECK (end_time > start_time),
    CONSTRAINT chk_max_patients CHECK (max_patients_per_hour > 0)
);

-- Appointments table
CREATE TABLE Appointments (
    appointment_id INT PRIMARY KEY AUTO_INCREMENT,
    appointment_number VARCHAR(20) NOT NULL UNIQUE,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    appointment_date DATE NOT NULL,
    appointment_time TIME NOT NULL,
    duration_minutes INT DEFAULT 30,
    appointment_type ENUM('Consultation', 'Follow-up', 'Emergency', 'Routine Check', 'Vaccination') NOT NULL,
    status ENUM('Scheduled', 'Confirmed', 'In Progress', 'Completed', 'Cancelled', 'No Show') DEFAULT 'Scheduled',
    reason_for_visit TEXT,
    notes TEXT,
    consultation_fee DECIMAL(8,2),
    booking_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Foreign key constraints
    CONSTRAINT fk_appointments_patient 
        FOREIGN KEY (patient_id) REFERENCES Patients(patient_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_appointments_doctor 
        FOREIGN KEY (doctor_id) REFERENCES Doctors(doctor_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    
    -- Check constraints
    CONSTRAINT chk_appointment_date CHECK (appointment_date >= booking_date),
    CONSTRAINT chk_appointment_duration CHECK (duration_minutes > 0),
    CONSTRAINT chk_appointment_fee CHECK (consultation_fee >= 0)
);

-- =====================================================
-- MEDICAL RECORDS TABLES
-- =====================================================

-- Medical Records table
CREATE TABLE MedicalRecords (
    record_id INT PRIMARY KEY AUTO_INCREMENT,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    appointment_id INT,
    record_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    chief_complaint TEXT,
    diagnosis TEXT,
    treatment_plan TEXT,
    vital_signs JSON, -- Store structured vital signs data
    symptoms TEXT,
    examination_notes TEXT,
    lab_results TEXT,
    follow_up_instructions TEXT,
    next_appointment_recommended BOOLEAN DEFAULT FALSE,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    -- Foreign key constraints
    CONSTRAINT fk_records_patient 
        FOREIGN KEY (patient_id) REFERENCES Patients(patient_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_records_doctor 
        FOREIGN KEY (doctor_id) REFERENCES Doctors(doctor_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_records_appointment 
        FOREIGN KEY (appointment_id) REFERENCES Appointments(appointment_id)
        ON DELETE SET NULL ON UPDATE CASCADE
);

-- Prescriptions table (Many-to-Many: MedicalRecords ↔ Medications)
CREATE TABLE Prescriptions (
    prescription_id INT PRIMARY KEY AUTO_INCREMENT,
    record_id INT NOT NULL,
    medication_id INT NOT NULL,
    dosage VARCHAR(100) NOT NULL,
    frequency VARCHAR(100) NOT NULL,
    duration_days INT NOT NULL,
    quantity INT NOT NULL,
    instructions TEXT,
    start_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    end_date DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign key constraints
    CONSTRAINT fk_prescriptions_record 
        FOREIGN KEY (record_id) REFERENCES MedicalRecords(record_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_prescriptions_medication 
        FOREIGN KEY (medication_id) REFERENCES Medications(medication_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    
    -- Check constraints
    CONSTRAINT chk_prescription_duration CHECK (duration_days > 0),
    CONSTRAINT chk_prescription_quantity CHECK (quantity > 0),
    CONSTRAINT chk_prescription_dates CHECK (end_date IS NULL OR end_date >= start_date)
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Indexes on frequently queried columns
CREATE INDEX idx_patients_number ON Patients(patient_number);
CREATE INDEX idx_patients_name ON Patients(last_name, first_name);
CREATE INDEX idx_patients_phone ON Patients(phone);
CREATE INDEX idx_patients_email ON Patients(email);

CREATE INDEX idx_doctors_number ON Doctors(doctor_number);
CREATE INDEX idx_doctors_name ON Doctors(last_name, first_name);
CREATE INDEX idx_doctors_specialization ON Doctors(specialization);
CREATE INDEX idx_doctors_department ON Doctors(department_id);

CREATE INDEX idx_appointments_number ON Appointments(appointment_number);
CREATE INDEX idx_appointments_patient ON Appointments(patient_id);
CREATE INDEX idx_appointments_doctor ON Appointments(doctor_id);
CREATE INDEX idx_appointments_date ON Appointments(appointment_date);
CREATE INDEX idx_appointments_status ON Appointments(status);
CREATE INDEX idx_appointments_datetime ON Appointments(appointment_date, appointment_time);

CREATE INDEX idx_schedules_doctor ON DoctorSchedules(doctor_id);
CREATE INDEX idx_schedules_day ON DoctorSchedules(day_of_week);

CREATE INDEX idx_records_patient ON MedicalRecords(patient_id);
CREATE INDEX idx_records_doctor ON MedicalRecords(doctor_id);
CREATE INDEX idx_records_date ON MedicalRecords(record_date);

CREATE INDEX idx_prescriptions_record ON Prescriptions(record_id);
CREATE INDEX idx_prescriptions_medication ON Prescriptions(medication_id);

-- =====================================================
-- SAMPLE DATA INSERTION
-- =====================================================

-- Insert Departments
INSERT INTO Departments (department_name, department_head, location, phone, description) VALUES
('Cardiology', 'Dr. Sarah Johnson', 'Building A - Floor 2', '555-0101', 'Heart and cardiovascular system treatment'),
('Pediatrics', 'Dr. Michael Chen', 'Building B - Floor 1', '555-0102', 'Medical care for infants, children, and adolescents'),
('Orthopedics', 'Dr. Emily Rodriguez', 'Building A - Floor 3', '555-0103', 'Musculoskeletal system disorders and injuries'),
('General Medicine', 'Dr. David Wilson', 'Building B - Floor 2', '555-0104', 'Primary healthcare and general medical conditions'),
('Dermatology', 'Dr. Lisa Anderson', 'Building C - Floor 1', '555-0105', 'Skin, hair, and nail conditions');

-- Insert Medications
INSERT INTO Medications (medication_name, generic_name, manufacturer, dosage_form, strength, unit_price, description) VALUES
('Lisinopril', 'Lisinopril', 'Generic Pharma', 'Tablet', '10mg', 0.25, 'ACE inhibitor for blood pressure'),
('Amoxicillin', 'Amoxicillin', 'Antibiotics Inc', 'Capsule', '500mg', 0.50, 'Penicillin antibiotic'),
('Ibuprofen', 'Ibuprofen', 'Pain Relief Co', 'Tablet', '200mg', 0.15, 'Non-steroidal anti-inflammatory drug'),
('Metformin', 'Metformin HCl', 'Diabetes Care', 'Tablet', '500mg', 0.30, 'Type 2 diabetes medication'),
('Aspirin', 'Acetylsalicylic Acid', 'Heart Health', 'Tablet', '81mg', 0.10, 'Low-dose aspirin for heart protection');

-- Insert Patients
INSERT INTO Patients (patient_number, first_name, last_name, date_of_birth, gender, phone, email, address, emergency_contact_name, emergency_contact_phone, blood_type) VALUES
('PT001', 'John', 'Smith', '1985-03-15', 'Male', '555-1001', 'john.smith@email.com', '123 Main St, City, State', 'Jane Smith', '555-1002', 'A+'),
('PT002', 'Mary', 'Johnson', '1992-07-22', 'Female', '555-1003', 'mary.johnson@email.com', '456 Oak Ave, City, State', 'Robert Johnson', '555-1004', 'O-'),
('PT003', 'Robert', 'Davis', '1978-11-08', 'Male', '555-1005', 'robert.davis@email.com', '789 Pine St, City, State', 'Susan Davis', '555-1006', 'B+'),
('PT004', 'Sarah', 'Wilson', '1995-01-30', 'Female', '555-1007', 'sarah.wilson@email.com', '321 Elm Dr, City, State', 'Mike Wilson', '555-1008', 'AB+'),
('PT005', 'Emily', 'Brown', '2010-05-12', 'Female', '555-1009', 'emily.parent@email.com', '654 Maple Ln, City, State', 'Lisa Brown', '555-1010', 'A-');

-- Insert Doctors
INSERT INTO Doctors (doctor_number, first_name, last_name, specialization, department_id, phone, email, license_number, qualification, experience_years, consultation_fee, hire_date) VALUES
('DR001', 'Sarah', 'Johnson', 'Cardiologist', 1, '555-2001', 'sarah.johnson@clinic.com', 'LIC001', 'MD Cardiology, Board Certified', 15, 200.00, '2010-01-15'),
('DR002', 'Michael', 'Chen', 'Pediatrician', 2, '555-2002', 'michael.chen@clinic.com', 'LIC002', 'MD Pediatrics, FAAP', 12, 150.00, '2012-03-20'),
('DR003', 'Emily', 'Rodriguez', 'Orthopedic Surgeon', 3, '555-2003', 'emily.rodriguez@clinic.com', 'LIC003', 'MD Orthopedic Surgery', 18, 300.00, '2008-06-10'),
('DR004', 'David', 'Wilson', 'General Practitioner', 4, '555-2004', 'david.wilson@clinic.com', 'LIC004', 'MD Family Medicine', 10, 120.00, '2014-09-05'),
('DR005', 'Lisa', 'Anderson', 'Dermatologist', 5, '555-2005', 'lisa.anderson@clinic.com', 'LIC005', 'MD Dermatology', 8, 180.00, '2016-11-12');

-- Insert Doctor Schedules
INSERT INTO DoctorSchedules (doctor_id, day_of_week, start_time, end_time, max_patients_per_hour) VALUES
(1, 'Monday', '09:00:00', '17:00:00', 3),
(1, 'Wednesday', '09:00:00', '17:00:00', 3),
(1, 'Friday', '09:00:00', '17:00:00', 3),
(2, 'Monday', '08:00:00', '16:00:00', 4),
(2, 'Tuesday', '08:00:00', '16:00:00', 4),
(2, 'Thursday', '08:00:00', '16:00:00', 4),
(3, 'Tuesday', '10:00:00', '18:00:00', 2),
(3, 'Thursday', '10:00:00', '18:00:00', 2),
(4, 'Monday', '08:00:00', '17:00:00', 5),
(4, 'Tuesday', '08:00:00', '17:00:00', 5),
(4, 'Wednesday', '08:00:00', '17:00:00', 5),
(4, 'Thursday', '08:00:00', '17:00:00', 5),
(4, 'Friday', '08:00:00', '17:00:00', 5);

-- Insert Appointments
INSERT INTO Appointments (appointment_number, patient_id, doctor_id, appointment_date, appointment_time, appointment_type, status, reason_for_visit, consultation_fee) VALUES
('APT001', 1, 1, '2024-09-25', '10:00:00', 'Consultation', 'Scheduled', 'Chest pain and shortness of breath', 200.00),
('APT002', 5, 2, '2024-09-23', '14:30:00', 'Routine Check', 'Confirmed', 'Annual pediatric checkup', 150.00),
('APT003', 3, 4, '2024-09-24', '11:00:00', 'Follow-up', 'Scheduled', 'Follow-up for diabetes management', 120.00),
('APT004', 2, 5, '2024-09-26', '15:00:00', 'Consultation', 'Scheduled', 'Skin rash and irritation', 180.00);

-- Insert Medical Records
INSERT INTO MedicalRecords (patient_id, doctor_id, appointment_id, chief_complaint, diagnosis, treatment_plan, vital_signs, symptoms) VALUES
(3, 4, 3, 'Fatigue and increased thirst', 'Type 2 Diabetes Mellitus', 'Lifestyle modification and medication', 
 '{"blood_pressure": "140/90", "heart_rate": "78", "temperature": "98.6", "weight": "180", "height": "70"}',
 'Polyuria, polydipsia, fatigue');

-- Insert Prescriptions
INSERT INTO Prescriptions (record_id, medication_id, dosage, frequency, duration_days, quantity, instructions) VALUES
(1, 4, '500mg', 'Twice daily', 30, 60, 'Take with meals to reduce stomach upset');