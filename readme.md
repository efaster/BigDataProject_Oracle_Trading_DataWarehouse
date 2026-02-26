```md
# 🗄️ Oracle Data Warehouse & ETL Pipeline

A full relational database and ETL pipeline implementation using **Oracle SQL & PL/SQL**.  
This project demonstrates schema design, data ingestion, transformation across Bronze–Silver–Gold layers, performance optimization, and analytical views for business querying.

---

## 📌 Overview

This database project is designed to simulate a real-world data workflow:

- Raw data ingestion → **Bronze**
- Data cleaning & transformation → **Silver**
- Business-ready analytical views → **Gold**

The project also includes constraints for data integrity, indexing for performance, stored procedures for business logic, and mock data for testing.

---

## 🧱 Architecture
```

Source → Bronze → Silver → Gold

````

| Layer   | Description |
|---------|------------|
| Bronze  | Raw staging data loaded from source |
| Silver  | Cleaned, transformed, and structured data |
| Gold    | Analytical views for business queries |

---

## 📂 Project Structure

```
.
├── DataBase_Main.sql           # Core schema & table creation
├── Constraints.sql             # Primary key, foreign key, check constraints
├── Indexing.sql                # Performance tuning with indexes
├── Stored_Procedure.sql        # Transaction & business logic
├── Mock_DataAll.sql            # Mock data for testing

├── ETL_Stage(Bronze).sql       # Load raw data into staging
├── Bronze.sql                  # Bronze layer objects

├── ETL_Clean(Silver).sql       # Data cleaning & transformation
├── Silver.sql                  # Structured relational data

├── Gold(View).sql              # Analytical views for reporting

└── Droptable.sql               # Drop all objects (reset database)
````

---

## ⚙️ Installation & Execution

Run the scripts in the following order:

### 1️⃣ Create Core Tables

```sql
@DataBase_Main.sql
```

### 2️⃣ Apply Constraints

```sql
@Constraints.sql
```

### 3️⃣ Create Indexes

```sql
@Indexing.sql
```

### 4️⃣ Insert Mock Data

```sql
@Mock_DataAll.sql
```

### 5️⃣ Run ETL – Bronze Layer

```sql
@ETL_Stage(Bronze).sql
@Bronze.sql
```

### 6️⃣ Run ETL – Silver Layer

```sql
@ETL_Clean(Silver).sql
@Silver.sql
```

### 7️⃣ Create Gold Analytical Views

```sql
@Gold(View).sql
```

---

## 🔄 Reset Database

```sql
@Droptable.sql
```

---

## 🚀 Key Features

- Fully normalized relational schema
- ETL pipeline implementation
- Data cleaning and transformation
- Analytical business views
- Data integrity with constraints
- Query performance optimization using indexes
- Stored procedures for transactional logic
- Mock data for testing and demonstration

---

## 🛠️ Technologies

- Oracle SQL
- PL/SQL

---

## 📊 Use Cases

- Data warehouse practice project
- Database design & normalization study
- ETL pipeline implementation
- SQL performance tuning demonstration
- Portfolio for Data

---
