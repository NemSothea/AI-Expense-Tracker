# AI Assistant Expense Tracker SwiftUI App - README

## Project Overview
AI Expense Tracker is an intelligent expense management application that uses artificial intelligence to simplify financial tracking. The application features a Spring Boot backend with a PostgreSQL database and a native iOS mobile application with AI capabilities for receipt scanning, voice input, and intelligent categorization.

### Features
#### Core Features

- **Multi-input Expense Logging**: Manual entry and AI-powered OCR receipt scanning
- **AI-Powered Categorization**: Automatic categorization of expenses using machine learning
- **Voice Input**: Create expenses through natural language voice commands
- **Expense Management**: Full CRUD operations (Create, Read, Update, Delete)
- **Advanced Filtering & Sorting**: Filter by categories and sort by date, amount, or name
- **Data Visualization**: Interactive dashboard with spending charts and insights
- **User Authentication**: Secure login with email/password and Google OAuth
- **Cross-Platform Sync**: Cloud synchronization between iOS app and web dashboard

#### Technical Features
- Spring Boot backend with JWT authentication
- PostgreSQL database with optimized queries
- RESTful API design
- iOS app built with SwiftUI
- Vision framework for receipt scanning
- Voice recognition for hands-free expense creation
- Charts and data visualization
- Secure credential storage using Keychain

#### Team Members & Responsibilities
- **Sothea:** Project Lead, iOS Developer & Backend Developer

    - iOS app architecture and development
    - Spring Boot REST API development
    - Camera/OCR integration
    - API communication and team coordination

- **Pisey:** Database Architect

    - PostgreSQL database design and management
    - Data integrity and query optimization
    - Database performance tuning

- **Seyha:** UI/UX Designer & Frontend Developer

    - Application UI/UX design
    - Web dashboard development
    - Frontend implementation

- **Srey Nich:** Documentation Lead

    - Documentation coordination
    - Presentation slide creation
    - Demo preparation
    - Coordinating documentation efforts

#### Project Process flow

#### Installation & Setup
##### Prerequisites
- Java 17 or later
- PostgreSQL 12 or later
- Xcode 13 or later
- iOS 16 or later
- Maven

### Backend Setup
- Clone the repository
- Navigate to the backend directory: cd backend
- Configure database connection in application.properties
- Run the application: mvn spring-boot:run

### Database Setup
- Create a PostgreSQL database named expense_tracker


### iOS App Setup

#### Prerequisites
- Xcode 15.0 or later
- iOS 16.0 or later / macOS 13.0 or later
- Swift 5.9 or later
- Apple Developer Account (for device testing)

### API Documentation

#### Authentication Endpoints
- POST /api/auth/login - User login
- POST /api/auth/google - Google OAuth authentication
- POST /api/auth/logout - User logout

#### Expense Endpoints
- GET /api/expenses - Get all expenses (with filtering and sorting)
- POST /api/expenses - Create a new expense
- GET /api/expenses/{id} - Get a specific expense
- PUT /api/expenses/{id} - Update an expense
- DELETE /api/expenses/{id} - Delete an expense
- GET /api/expenses/analytics - Get expense analytics
#### Category Endpoints
- GET /api/categories - Get all categories
- POST /api/categories - Create a new category

### Usage
#### Adding Expenses
- Manual Entry: Tap the "+" button and fill in the expense details
- Receipt Scanning: Use the camera to scan a receipt (AI will extract details)
- Voice Input: Use the AI Assistant to create expenses through voice commands
#### Viewing Expenses
- View all expenses in a sortable and filterable list
- See spending analytics on the dashboard
- Check recent expenses and top categories
#### Managing Expenses
- Swipe left on any expense to edit or delete
- Use filter options to view specific categories or date ranges

### Development Roadmap
#### Phase 1: MVP (Requesting)
- Basic expense entry (manual and OCR)
- AI categorization of expenses
- Simple dashboard with spending breakdown
- User authentication
- iOS app and Spring Boot backend foundation

#### 🚀 Phase 1: MVP (In Progress)
- ✅ Basic expense entry (manual and OCR)
- ✅ AI categorization of expenses
- ✅ Simple dashboard with spending breakdown
- ✅ User authentication system
- ✅ iOS app and Spring Boot backend foundation

#### 🎯 Phase 2: Advanced Features (Future)
- 🎯 Financial goals setting and tracking
- 🏦 Bank synchronization API
- 🤖 Advanced predictive analytics



### To Start OPEN AI Platform:
1) https://platform.openai.com/settings/organization/api-keys


### git Tip 
1.  git status : See the Changes not staged for commit.
    ex :     modified:   AIExapenseTracker.xcodeproj/project.xcworkspace/xcuserdata/sothea007.xcuserdatad/UserInterfaceState.xcuserstate
2. remove unwanted :
    git rm --cached AIExapenseTracker.xcodeproj/project.xcworkspace/xcuserdata/sothea007.xcuserdatad/UserInterfaceState.xcuserstate\
3. git commit -m "Removed file that shouldn't be tracked"
4. recheck git status :  git status 
    



