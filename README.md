# Easy Internship App

This project consists of two main parts:
1. **Frontend**: A Flutter application that helps you automatically scrape job (or internship) offers from multiple sources, review the listings in one place, and submit applications with minimal manual work. It supports iOS, Android, and Windows platforms.
2. **Backend**: A server-side component for handling data storage, user authentication, and APIs for scraping and managing job postings.

## Features
- **Scraping Job Offers**: Gathers and displays job postings from various websites.
- **Auto-Fill Application**: Fills out application forms automatically once the user accepts a listing.
- **Backend API**: Performs tasks such as database interactions and job scraping.
- **Multi-Platform**: The Flutter frontend runs on iOS, Android, and Windows using a single codebase.

## Project Structure
```
Easy_Internship_App/
├── backend/
│   ├── ... (Backend source files)
│   ├── package.json
│   └── ...
└── frontend/
    ├── pubspec.yaml
    ├── lib/
    └── ...
```

---

## Frontend

### Requirements
- **Flutter SDK** (>= 3.0.0)
- **Dart** (>= 2.17.0)
- **Android Studio/Xcode** for respective platform builds
- **Windows SDK** (for Windows builds)

### Getting Started (Frontend)
1. **Clone the repository**:
   ```bash
   git clone https://github.com/germanProgq/Easy_Internship_App.git
   ```
2. **Install dependencies** (in the `frontend` directory):
   ```bash
   cd Resume_App/Resume_App__Frontend
   flutter pub get
   ```
3. **Run the app**:
   - For Android or iOS:
     ```bash
     flutter run
     ```
   - For Windows:
     ```bash
     flutter run -d windows
     ```

### Usage (Frontend)
1. **Scrape Job Offers**: Tap the "Scrape Jobs" button to aggregate open positions.
2. **Review Listings**: Filter or sort job offers by role, location, or source.
3. **Apply**: Select a job listing, review the auto-filled information, and submit.

---

## Backend

### Requirements
Depending on your choice of backend technology (Node.js, Python, etc.), you will have different requirements, for example:
- **Node.js & npm** (If using Express or a similar Node framework), or

### Getting Started (Backend)

1. **Navigate to the backend folder**:
   ```bash
   cd Resume_App/Resume_App__Backend
   ```

2. **Install dependencies**:
   - If Node.js:
     ```bash
     npm install
     ```

3. **Configure environment variables** (if needed). For example, create a `.env` file or set variables for:
   - Database connection
   - API keys for scraping job sites
   - Any other necessary credentials

4. **Run the server**:
   - If Node.js:
     ```bash
     npm start
     ```

5. **Verify the API** is working by visiting the appropriate URL (e.g., `http://localhost:3000` or `http://localhost:8000`) or by using an API client (e.g., Postman).

---

## Contributing

1. **Fork** the project.
2. **Create a new branch** for your feature or fix.
3. **Commit** your changes.
4. **Open a Pull Request** to merge back into the main repository.


## License
This project is licensed under the [MIT License](LICENSE).