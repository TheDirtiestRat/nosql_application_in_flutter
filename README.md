# NoSQL Application

This project is a Flutter application built to demonstrate how a document-based NoSQL database can be used in a real-world CRUD workflow. The system connects to Apache CouchDB, stores person records as JSON documents, and provides a simple user interface for creating, viewing, searching, updating, and deleting entries.

## Overview

The application is designed around the idea of a lightweight database management system for personal records. Instead of using a relational table structure, it stores each person as a separate CouchDB document, making it a good example of NoSQL document storage and document-oriented data modeling.

The core use case is managing a list of people with the following fields:

- first_name
- last_name
- age
- year_born

Each record is stored in a CouchDB database and is retrieved via the CouchDB REST API using HTTP requests from the Flutter app.

## System Functionalities

### 1. Database Configuration
The app starts with a Configuration screen where the user can enter:

- CouchDB base URL
- database name
- username
- password

Once the credentials and database name are validated, the app connects to the database and navigates to the main people list screen.

### 2. View People Records
The People screen loads all documents from the database and displays them in a scrollable list. Each item shows:

- full name
- age
- birth year

This list acts as the main dashboard for the application.

### 3. Search Records
Users can search by first name or last name. The app filters the results locally after fetching documents from the database, making it quick and easy to find a specific person.

### 4. Add New Person
From the floating action button, users can open a form to add a new person entry. The form includes:

- first name
- last name
- age
- year born

The app validates required input and ensures numeric fields are valid integers before saving.

### 5. Edit Existing Records
A record can be opened from the main list and edited. The app preserves the existing CouchDB metadata such as _id and _rev and updates the document with the new values.

### 6. Delete Records
Each person card includes a delete action. Before deletion, the app asks for confirmation and uses the document revision (_rev) to safely remove the item from the database.

### 7. Error Handling and Feedback
The system shows user-friendly snack bars and validation messages for:

- failed database connection
- invalid fields
- unsuccessful save or delete operations
- no records found

## Key Features

- CouchDB connectivity via HTTP
- NoSQL document-based storage
- Automatic CRUD operations for person data
- Search and filtering by name
- Form validation for required and numeric fields
- Material Design UI
- Editable and deletable records
- Safe update and delete logic using CouchDB revision IDs

## Application Flow

1. Open the app.
2. Enter the CouchDB connection details.
3. Connect to the selected database.
4. View all people records.
5. Search, add, edit, or delete a person.
6. The changes are synchronized with the database.

## Tech Stack

### Frontend / Mobile App
- Flutter
- Dart
- Material Design widgets

### Backend / Database
- Apache CouchDB
- REST API over HTTP

### Networking
- http package for making API requests

## Architecture

The project uses a simple layered design:

- UI layer: screens under lib/pages
- Service layer: database communication under lib/services
- HTTP client: uses the CouchDB REST API for CRUD operations

The main files include:

- lib/main.dart — application entry point
- lib/pages/configuration_screen.dart — database connection setup screen
- lib/pages/persons_list_screen.dart — list and search screen
- lib/pages/record_person_screen.dart — add/edit person form
- lib/services/couch_db_services.dart — CouchDB operations and document handling

## Data Model

The application stores each person as a JSON document in CouchDB.

Example document structure:

```json
{
  "_id": "unique-document-id",
  "_rev": "revision-id",
  "first_name": "John",
  "last_name": "Doe",
  "age": 28,
  "year_born": 1996
}
```

This structure reflects the document-oriented nature of CouchDB, where records are stored as self-contained JSON objects rather than rows in a relational table.

## Database Operations Used

The app performs the following CouchDB operations:

- GET: connect to the database and retrieve documents
- POST: add a new document
- PUT: update an existing document
- DELETE: remove a document by its ID and revision
- _all_docs: read all documents in the database

## Prerequisites

Before running the app, make sure you have:

- Flutter SDK installed
- A running CouchDB instance
- A valid database created in CouchDB
- Database credentials with access rights

## Setup and Run

1. Install Flutter dependencies:

```bash
flutter pub get
```

2. Start CouchDB and create a database such as nosql_db.

3. Run the app:

```bash
flutter run
```

4. On the configuration screen, enter your CouchDB connection details and connect.

## Notes

This project is a practical example of how a NoSQL database can be integrated into a mobile or desktop app using Flutter. It highlights the strengths of document-based storage, REST-based communication, and fast prototyping of CRUD systems.

## Project Purpose

The application is useful for learning and demonstration purposes, especially for understanding:

- NoSQL database fundamentals
- CouchDB document structure
- CRUD operations in Flutter
- REST communication between a frontend and a database
- Document-oriented design compared with relational databases
