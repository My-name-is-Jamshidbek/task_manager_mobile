# 🔄 Task Manager Mobile - Complete Application Flow Diagram

This document provides comprehensive flow diagrams for the entire Task Manager Mobile application, covering all features, functionalities, and user states.

## 📋 Table of Contents

1. [Application Initialization Flow](#1-application-initialization-flow)
2. [Authentication Flow](#2-authentication-flow)
3. [Main Navigation Flow](#3-main-navigation-flow)
4. [Task Management Flow](#4-task-management-flow)
5. [Project Management Flow](#5-project-management-flow)
6. [Profile & Settings Flow](#6-profile--settings-flow)
7. [Firebase & Notifications Flow](#7-firebase--notifications-flow)
8. [Theme & Localization Flow](#8-theme--localization-flow)
9. [Update Management Flow](#9-update-management-flow)
10. [Complete User State Diagram](#10-complete-user-state-diagram)

---

## 1. Application Initialization Flow

The app starts from `main.dart` and goes through several initialization phases before displaying any UI.

```
┌─────────────────────────────────────────────────────────────┐
│                      APP STARTUP (main.dart)                │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ├─► Initialize WidgetsFlutterBinding
                       ├─► Enable Logger
                       ├─► Set Preferred Orientations (Portrait + Landscape)
                       │
                       ├─► Initialize Services:
                       │   ├─► ThemeService.initialize()
                       │   ├─► LocalizationService.initialize()
                       │   └─► FirebaseProvider.initialize()
                       │
                       ├─► Setup Crashlytics Error Handlers
                       │   ├─► FlutterError.onError
                       │   └─► PlatformDispatcher.onError
                       │
                       ├─► Initialize MultiProvider with:
                       │   ├─► ThemeService
                       │   ├─► LocalizationService
                       │   ├─► AuthProvider
                       │   ├─► FirebaseProvider
                       │   ├─► ProjectsProvider
                       │   ├─► TasksApiProvider
                       │   └─► DashboardProvider
                       │
                       └─► Launch MaterialApp
                           └─► Home: AppRoot (with AppRootController.key)
                                   │
                                   v
                        ┌──────────────────────┐
                        │   AppRoot Widget     │
                        │  (_AppRootState)     │
                        └──────────┬───────────┘
                                   │
                                   v
                    [Continue to App Initialization]
```

### AppRoot Initialization Sequence

```
┌──────────────────────────────────────────────────────────────┐
│              AppRoot._initializeApp() [5s minimum]           │
└───────────────────────────┬──────────────────────────────────┘
                            │
                            ├─► AuthDebugHelper.printStoredAuthData()
                            │
                            ├─► Check for Updates (UpdateService)
                            │   ├─► Get current locale
                            │   ├─► UpdateService.getUpdateInfo()
                            │   │
                            │   ├──[Update Required?]
                            │   │   ├─YES─► Show Required Update Dialog
                            │   │   │       └─► HALT initialization
                            │   │   │           └─► Force user to update
                            │   │   │
                            │   │   └─NO──► Continue initialization
                            │   │
                            │   └──[Optional Update?]
                            │       └─► Schedule optional update dialog
                            │
                            ├─► Initialize AuthenticationManager
                            │   └─► Setup 401 auto-logout listener
                            │
                            ├─► AppManager.initialize()
                            │   ├─► _initializeCoreServices()
                            │   │   └─► AuthService.initialize()
                            │   │
                            │   └─► _checkAuthenticationState()
                            │       ├─► Check if token exists
                            │       ├──[No token]─► Return UNAUTHENTICATED
                            │       │
                            │       └──[Has token]
                            │           ├─► Verify token with server
                            │           │   └─► POST /auth/verify
                            │           │
                            │           ├──[Valid token]
                            │           │   └─► Return AUTHENTICATED
                            │           │
                            │           └──[Invalid token]
                            │               ├─► Clear session
                            │               └─► Return UNAUTHENTICATED
                            │
                            ├─► AuthProvider.initialize()
                            │   └─► Sync with AuthService state
                            │
                            ├─► Wait for minimum loading duration (5s)
                            │
                            └─► Set _currentState and rebuild
                                │
                                ├──[AUTHENTICATED]─► Show MainScreen
                                │
                                └──[UNAUTHENTICATED]─► Show LoginScreen
```

---

## 2. Authentication Flow

### Login Flow (Phone + Password/SMS)

```
┌──────────────────────────────────────────────────────────────┐
│                      LoginScreen                             │
└───────────────────────┬──────────────────────────────────────┘
                        │
                        ├─► User enters phone (+998 format)
                        ├─► User enters password
                        ├─► Form validation
                        │
                        └─► Submit Login
                            │
                            ├─► AuthProvider.login(phone, password)
                            │   └─► POST /auth/login
                            │       ├─► body: {phone, password}
                            │       │
                            │       ├──[Success - Direct Login]
                            │       │   ├─► Store token
                            │       │   ├─► Store user data
                            │       │   ├─► Set isLoggedIn = true
                            │       │   └─► Call onAuthSuccess()
                            │       │       └─► Navigate to MainScreen
                            │       │
                            │       ├──[Success - SMS Required]
                            │       │   ├─► Store temp data
                            │       │   └─► Navigate to SmsVerificationScreen
                            │       │       │
                            │       │       └─► Enter SMS Code
                            │       │           │
                            │       │           └─► AuthProvider.verifySms(code)
                            │       │               └─► POST /auth/verify-sms
                            │       │                   ├─► body: {phone, code}
                            │       │                   │
                            │       │                   ├──[Valid Code]
                            │       │                   │   ├─► Store token
                            │       │                   │   ├─► Store user
                            │       │                   │   └─► Navigate to MainScreen
                            │       │                   │
                            │       │                   └──[Invalid Code]
                            │       │                       └─► Show error
                            │       │
                            │       └──[Error]
                            │           └─► Show error message
                            │
                            └─► Register Firebase Token
                                └─► POST /firebase/tokens
                                    └─► body: {token, device_info}
```

### Auto-Logout Flow (401 Response)

```
┌──────────────────────────────────────────────────────────────┐
│            Any API Request Returns 401 Unauthorized          │
└───────────────────────┬──────────────────────────────────────┘
                        │
                        └─► AuthenticationManager detects 401
                            │
                            ├─► Log: "Session expired"
                            ├─► AuthService.clearSession()
                            ├─► AppRootController.setUnauthenticated()
                            │
                            └─► Force navigate to LoginScreen
                                └─► Show "Session expired" message
```

### Logout Flow

```
┌──────────────────────────────────────────────────────────────┐
│                    User Clicks Logout                        │
└───────────────────────┬──────────────────────────────────────┘
                        │
                        └─► Show Confirmation Dialog
                            │
                            ├──[Cancel]─► Return to screen
                            │
                            └──[Confirm]
                                │
                                ├─► AuthProvider.logout()
                                │   ├─► Deactivate Firebase token
                                │   │   └─► POST /firebase/tokens/deactivate
                                │   │
                                │   └─► AuthService.logout()
                                │       └─► DELETE /auth/logout
                                │
                                ├─► Clear local storage
                                ├─► Reset all providers
                                │
                                └─► Navigate to LoginScreen
```

---

## 3. Main Navigation Flow

### Main Screen with Bottom Navigation

```
┌──────────────────────────────────────────────────────────────┐
│                     MainScreen                               │
│  ┌────────────────────────────────────────────────────────┐  │
│  │                   App Bar                              │  │
│  │  [Menu] Title [Notifications] [Search]                 │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │              Current Screen Content                    │  │
│  │         (HomeScreen / TasksScreen /                    │  │
│  │          ProjectsScreen / ProfileScreen)               │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │           Bottom Navigation Bar (Curved)               │  │
│  │   [Home] [Tasks] [Projects] [Profile]                  │  │
│  └────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘

Navigation Flow:
┌──────────────┐
│  Home (0)    │◄─── Dashboard with stats, quick actions
│              │     Recent items, Welcome card
└──────┬───────┘
       │
┌──────▼───────┐
│  Tasks (1)   │◄─── Task list with filters
│              │     Create, view, edit, delete tasks
└──────┬───────┘     Task detail screen
       │
┌──────▼───────┐
│ Projects (2) │◄─── Project list with filters
│              │     Create, view, edit projects
└──────┬───────┘     Project detail screen
       │
┌──────▼───────┐
│ Profile (3)  │◄─── User profile info
│              │     Edit profile, Change password
└──────────────┘     Settings, Logout
```

### Navigation Drawer Flow

```
┌──────────────────────────────────────────────────────────────┐
│                   Navigation Drawer                          │
└───────────────────────┬──────────────────────────────────────┘
                        │
                        ├─► Header
                        │   ├─► App icon
                        │   ├─► App title
                        │   └─► Version info
                        │
                        ├─► Navigation Items
                        │   ├─► Home (index 0)
                        │   ├─► Tasks (index 1)
                        │   ├─► Projects (index 2)
                        │   └─► Profile (index 3)
                        │
                        ├─► Divider
                        │
                        ├─► Settings & Preferences
                        │   ├─► Theme Settings
                        │   │   └─► Navigate to ThemeSettingsScreen
                        │   │
                        │   ├─► Language Settings
                        │   │   └─► Show LanguageSelector bottom sheet
                        │   │
                        │   └─► Settings
                        │       └─► Navigate to SettingsScreen
                        │
                        ├─► Divider
                        │
                        ├─► Developer Tools (if debug mode)
                        │   ├─► Firebase Test
                        │   │   └─► Navigate to FirebaseTestScreen
                        │   │
                        │   └─► Notification Debug
                        │       └─► Navigate to FirebaseNotificationDebugScreen
                        │
                        ├─► Divider
                        │
                        └─► Logout
                            └─► Show logout confirmation dialog
```

---

## 4. Task Management Flow

### Task List Screen (TasksScreen)

```
┌──────────────────────────────────────────────────────────────┐
│                      TasksScreen                             │
└───────────────────────┬──────────────────────────────────────┘
                        │
                        ├─► TasksApiProvider.fetchTasks()
                        │   └─► GET /tasks
                        │       ├─► Query params:
                        │       │   ├─► perPage (pagination)
                        │       │   ├─► page
                        │       │   ├─► filter (created_by_me/assigned_to_me)
                        │       │   ├─► name (search)
                        │       │   ├─► status (status filter)
                        │       │   └─► projectId (project filter)
                        │       │
                        │       └─► Display task list with:
                        │           ├─► Task cards
                        │           ├─► Infinite scroll (pagination)
                        │           └─► Pull to refresh
                        │
                        ├─► Filter Options
                        │   ├─► By Status
                        │   ├─► By Project
                        │   ├─► Created by me
                        │   ├─► Assigned to me
                        │   └─► Search by name
                        │
                        ├─► Actions
                        │   ├─► Tap Task Card
                        │   │   └─► Navigate to TaskDetailScreen
                        │   │
                        │   └─► FAB: Create Task
                        │       ├─► Navigate to CreateTaskScreen
                        │       └─► Or CreateTaskWithFilesScreen
                        │
                        └─► Load More
                            └─► TasksApiProvider.loadMore()
```

### Task Detail Screen

```
┌──────────────────────────────────────────────────────────────┐
│                   TaskDetailScreen                           │
└───────────────────────┬──────────────────────────────────────┘
                        │
                        ├─► TaskDetailProvider.fetchTask(taskId)
                        │   └─► GET /tasks/{id}
                        │       │
                        │       └─► Display:
                        │           ├─► Task title
                        │           ├─► Description
                        │           ├─► Status
                        │           ├─► Priority
                        │           ├─► Due date
                        │           ├─► Assigned workers
                        │           ├─► Project (if any)
                        │           ├─► Created by
                        │           ├─► Created at / Updated at
                        │           └─► Attached files
                        │
                        ├─► Actions
                        │   ├─► Edit Task
                        │   │   └─► Navigate to CreateTaskScreen (edit mode)
                        │   │       └─► PUT /tasks/{id}
                        │   │
                        │   ├─► Delete Task
                        │   │   └─► Show confirmation
                        │   │       └─► DELETE /tasks/{id}
                        │   │           └─► Navigate back to TasksScreen
                        │   │
                        │   ├─► Change Status
                        │   │   └─► Show status picker
                        │   │       └─► PUT /tasks/{id}
                        │   │
                        │   ├─► Add/Remove Workers
                        │   │   └─► Navigate to SelectTaskWorkersScreen
                        │   │       └─► PUT /tasks/{id}/workers
                        │   │
                        │   └─► View/Download Files
                        │       └─► FileGroupProvider
                        │
                        └─► Comments Section (Future)
                            ├─► View comments
                            └─► Add comment
```

### Create/Edit Task Flow

```
┌──────────────────────────────────────────────────────────────┐
│        CreateTaskScreen / CreateTaskWithFilesScreen          │
└───────────────────────────┬──────────────────────────────────┘
                            │
                            ├─► Form Fields:
                            │   ├─► Task Title* (required)
                            │   ├─► Description
                            │   ├─► Status (dropdown)
                            │   ├─► Priority (dropdown)
                            │   ├─► Due Date (date picker)
                            │   ├─► Project (dropdown - optional)
                            │   ├─► Assigned Workers (multi-select)
                            │   └─► File Attachments (if using WithFiles version)
                            │
                            ├─► Load Required Data:
                            │   ├─► Projects list (ProjectsProvider)
                            │   └─► Workers list (TaskWorkersProvider)
                            │
                            ├─► Validation
                            │   ├─► Title required
                            │   ├─► Valid due date
                            │   └─► At least one worker
                            │
                            └─► Submit
                                ├──[Create Mode]
                                │   └─► POST /tasks
                                │       ├─► body: task data
                                │       ├──[Success]
                                │       │   ├─► Show success message
                                │       │   └─► Navigate back
                                │       │
                                │       └──[Error]
                                │           └─► Show error message
                                │
                                └──[Edit Mode]
                                    └─► PUT /tasks/{id}
                                        ├─► body: updated task data
                                        ├──[Success]
                                        │   ├─► Show success message
                                        │   └─► Navigate back
                                        │
                                        └──[Error]
                                            └─► Show error message
```

### Task Workers Selection Flow

```
┌──────────────────────────────────────────────────────────────┐
│              SelectTaskWorkersScreen                         │
└───────────────────────┬──────────────────────────────────────┘
                        │
                        ├─► TaskWorkersProvider.fetchWorkers()
                        │   └─► GET /users (or workers endpoint)
                        │       │
                        │       └─► Display worker list with:
                        │           ├─► Search/filter
                        │           ├─► Multi-select checkboxes
                        │           └─► Currently selected workers
                        │
                        ├─► Select/Deselect Workers
                        │   └─► Update selection state
                        │
                        └─► Confirm Selection
                            └─► Return selected workers to caller
                                └─► Update task workers
```

---

## 5. Project Management Flow

### Projects List Screen

```
┌──────────────────────────────────────────────────────────────┐
│                    ProjectsScreen                            │
└───────────────────────┬──────────────────────────────────────┘
                        │
                        ├─► ProjectsProvider.fetchProjects()
                        │   └─► GET /projects
                        │       ├─► Query params:
                        │       │   ├─► perPage (pagination)
                        │       │   ├─► page
                        │       │   ├─► filter (my_projects/all)
                        │       │   └─► status (status filter)
                        │       │
                        │       └─► Display project list with:
                        │           ├─► Project cards
                        │           ├─► Project status indicator
                        │           ├─► Task count
                        │           └─► Team members count
                        │
                        ├─► Filter Options
                        │   ├─► By Status
                        │   ├─► My Projects
                        │   └─► All Projects
                        │
                        ├─► Actions
                        │   ├─► Tap Project Card
                        │   │   └─► Navigate to ProjectDetailScreen
                        │   │
                        │   └─► FAB: Create Project
                        │       └─► Navigate to CreateProjectScreen
                        │
                        └─► Refresh
                            └─► Pull to refresh
```

### Project Detail Screen

```
┌──────────────────────────────────────────────────────────────┐
│                  ProjectDetailScreen                         │
└───────────────────────┬──────────────────────────────────────┘
                        │
                        ├─► ProjectDetailProvider.fetchProject(projectId)
                        │   └─► GET /projects/{id}
                        │       │
                        │       └─► Display:
                        │           ├─► Project name
                        │           ├─► Description
                        │           ├─► Status
                        │           ├─► Start date / End date
                        │           ├─► Team members
                        │           ├─► Project manager
                        │           ├─► Tasks list (belonging to project)
                        │           └─► Progress indicators
                        │
                        ├─► Actions
                        │   ├─► Edit Project
                        │   │   └─► Navigate to CreateProjectScreen (edit mode)
                        │   │       └─► PUT /projects/{id}
                        │   │
                        │   ├─► Delete Project
                        │   │   └─► Show confirmation
                        │   │       └─► DELETE /projects/{id}
                        │   │           └─► Navigate back
                        │   │
                        │   ├─► Change Status
                        │   │   └─► Show status picker
                        │   │       └─► PUT /projects/{id}
                        │   │
                        │   ├─► View Project Tasks
                        │   │   └─► Filter TasksScreen by project
                        │   │
                        │   └─► Manage Team Members
                        │       └─► Add/Remove members
                        │
                        └─► Tabs (Optional)
                            ├─► Overview
                            ├─► Tasks
                            ├─► Team
                            └─► Files
```

### Create/Edit Project Flow

```
┌──────────────────────────────────────────────────────────────┐
│                  CreateProjectScreen                         │
└───────────────────────┬──────────────────────────────────────┘
                        │
                        ├─► Form Fields:
                        │   ├─► Project Name* (required)
                        │   ├─► Description
                        │   ├─► Status (dropdown)
                        │   ├─► Start Date (date picker)
                        │   ├─► End Date (date picker)
                        │   └─► Team Members (multi-select)
                        │
                        ├─► Validation
                        │   ├─► Name required
                        │   └─► Valid date range
                        │
                        └─► Submit
                            ├──[Create Mode]
                            │   └─► POST /projects
                            │       ├─► body: project data
                            │       ├──[Success]
                            │       │   ├─► Show success message
                            │       │   └─► Navigate back
                            │       │
                            │       └──[Error]
                            │           └─► Show error message
                            │
                            └──[Edit Mode]
                                └─► PUT /projects/{id}
                                    ├─► body: updated project data
                                    ├──[Success]
                                    │   ├─► Show success message
                                    │   └─► Navigate back
                                    │
                                    └──[Error]
                                        └─► Show error message
```

---

## 6. Profile & Settings Flow

### Profile Screen

```
┌──────────────────────────────────────────────────────────────┐
│                     ProfileScreen                            │
└───────────────────────┬──────────────────────────────────────┘
                        │
                        ├─► Display User Info:
                        │   ├─► Profile photo (avatar)
                        │   ├─► Full name
                        │   ├─► Email
                        │   ├─► Phone number
                        │   ├─► Role/Position
                        │   └─► Member since date
                        │
                        ├─► Statistics (DashboardProvider)
                        │   ├─► Total tasks
                        │   ├─► Completed tasks
                        │   ├─► Pending tasks
                        │   └─► Projects count
                        │
                        └─► Actions
                            ├─► Edit Profile
                            │   └─► Navigate to EditProfileScreen
                            │       ├─► Form with user data
                            │       └─► PUT /users/profile
                            │           ├─► Update name, email, photo
                            │           └─► Show success/error
                            │
                            ├─► Change Password
                            │   └─► Navigate to ChangePasswordScreen
                            │       ├─► Form:
                            │       │   ├─► Current password
                            │       │   ├─► New password
                            │       │   └─► Confirm new password
                            │       │
                            │       └─► POST /auth/change-password
                            │           ├─► Validate passwords
                            │           └─► Show success/error
                            │
                            ├─► View Statistics
                            │   └─► Detailed analytics view
                            │
                            └─► Logout
                                └─► [See Logout Flow above]
```

### Settings Screen

```
┌──────────────────────────────────────────────────────────────┐
│                     SettingsScreen                           │
└───────────────────────┬──────────────────────────────────────┘
                        │
                        ├─► App Preferences
                        │   ├─► Theme Settings
                        │   │   └─► Navigate to ThemeSettingsScreen
                        │   │
                        │   └─► Language Settings
                        │       └─► Show LanguageSelector
                        │
                        ├─► Notifications
                        │   ├─► Enable/Disable notifications
                        │   ├─► Notification sound
                        │   └─► Notification categories
                        │
                        ├─► Data & Privacy
                        │   ├─► Clear cache
                        │   ├─► Data usage
                        │   └─► Privacy policy
                        │
                        ├─► About
                        │   ├─► App version
                        │   ├─► Build number
                        │   ├─► Platform info
                        │   └─► Licenses
                        │
                        └─► Advanced
                            ├─► Developer mode (if debug)
                            ├─► Export data
                            └─► Reset app
```

---

## 7. Firebase & Notifications Flow

### Firebase Initialization

```
┌──────────────────────────────────────────────────────────────┐
│               FirebaseService.initialize()                   │
└───────────────────────┬──────────────────────────────────────┘
                        │
                        ├─► Initialize Firebase Core
                        │   └─► Firebase.initializeApp()
                        │       └─► with DefaultFirebaseOptions
                        │
                        ├─► Initialize Firebase Messaging
                        │   └─► FirebaseMessaging.instance
                        │
                        ├─► Request Notification Permissions
                        │   └─► requestPermission()
                        │       ├─► alert: true
                        │       ├─► badge: true
                        │       └─► sound: true
                        │
                        ├─► Get FCM Token
                        │   └─► getToken()
                        │       ├─► iOS: Use APNs
                        │       ├─► Android: Use FCM
                        │       └─► Store token locally
                        │
                        ├─► Register Token with Backend
                        │   └─► POST /firebase/tokens
                        │       ├─► body:
                        │       │   ├─► token (FCM token)
                        │       │   ├─► platform (ios/android)
                        │       │   ├─► device_name
                        │       │   ├─► device_model
                        │       │   └─► os_version
                        │       │
                        │       └─► Backend stores token for user
                        │
                        ├─► Subscribe to Topics
                        │   ├─► subscribeToTopic('all_users')
                        │   ├─► subscribeToTopic('announcements')
                        │   └─► subscribeToTopic('{user_id}')
                        │
                        └─► Setup Message Handlers
                            ├─► Foreground messages
                            ├─► Background messages
                            └─► Terminated messages
```

### Notification Handling Flow

```
┌──────────────────────────────────────────────────────────────┐
│              Notification Received (Any State)               │
└───────────────────────┬──────────────────────────────────────┘
                        │
                        ├──[App State: FOREGROUND]
                        │   │
                        │   ├─► FirebaseMessaging.onMessage
                        │   │   └─► NotificationService.handleForeground()
                        │   │       ├─► Parse notification data
                        │   │       ├─► Validate template & variables
                        │   │       ├─► Show in-app notification
                        │   │       │   └─► Custom overlay/banner
                        │   │       │
                        │   │       └─► User taps notification
                        │   │           └─► Navigate to target screen
                        │   │
                        │   └─► Show custom in-app notification UI
                        │
                        ├──[App State: BACKGROUND]
                        │   │
                        │   └─► FirebaseMessaging.onBackgroundMessage
                        │       └─► System shows notification
                        │           └─► User taps notification
                        │               ├─► App opens
                        │               └─► Navigate to target screen
                        │
                        └──[App State: TERMINATED]
                            │
                            └─► User taps notification
                                ├─► App launches
                                ├─► FirebaseMessaging.getInitialMessage()
                                │
                                └─► After initialization complete
                                    └─► Navigate to target screen
```

### Notification Types & Navigation

```
┌──────────────────────────────────────────────────────────────┐
│               Notification Type Resolution                   │
└───────────────────────┬──────────────────────────────────────┘
                        │
                        ├─► task_assigned
                        │   └─► Navigate to TaskDetailScreen(taskId)
                        │
                        ├─► task_updated
                        │   └─► Navigate to TaskDetailScreen(taskId)
                        │
                        ├─► task_comment_added
                        │   └─► Navigate to TaskDetailScreen(taskId)
                        │       └─► Scroll to comments
                        │
                        ├─► task_completed
                        │   └─► Navigate to TaskDetailScreen(taskId)
                        │
                        ├─► task_due_soon
                        │   └─► Navigate to TaskDetailScreen(taskId)
                        │
                        ├─► task_overdue
                        │   └─► Navigate to TaskDetailScreen(taskId)
                        │
                        ├─► project_created
                        │   └─► Navigate to ProjectDetailScreen(projectId)
                        │
                        ├─► project_status_changed
                        │   └─► Navigate to ProjectDetailScreen(projectId)
                        │
                        ├─► announcement
                        │   └─► Show announcement dialog/screen
                        │
                        ├─► app_update_android
                        │   └─► Show update dialog
                        │       └─► Navigate to Play Store
                        │
                        └─► app_update_ios
                            └─► Show update dialog
                                └─► Navigate to App Store
```

### Firebase Token Management

```
┌──────────────────────────────────────────────────────────────┐
│                 Token Lifecycle Management                   │
└───────────────────────┬──────────────────────────────────────┘
                        │
                        ├─► On Login
                        │   └─► Register new token
                        │       └─► POST /firebase/tokens
                        │
                        ├─► On Token Refresh
                        │   └─► FirebaseMessaging.onTokenRefresh
                        │       └─► Update token on backend
                        │           └─► PUT /firebase/tokens
                        │
                        └─► On Logout
                            └─► Deactivate token
                                └─► POST /firebase/tokens/deactivate
                                    └─► Backend stops sending to this token
```

---

## 8. Theme & Localization Flow

### Theme Management

```
┌──────────────────────────────────────────────────────────────┐
│                     ThemeService                             │
└───────────────────────┬──────────────────────────────────────┘
                        │
                        ├─► Initialize
                        │   └─► Load saved theme from SharedPreferences
                        │       ├─► Key: 'app_theme'
                        │       └─► Default: AppTheme.system
                        │
                        ├─► Available Themes:
                        │   ├─► Light Themes:
                        │   │   ├─► lightBlue
                        │   │   ├─► lightGreen
                        │   │   ├─► lightPurple
                        │   │   └─► lightOrange
                        │   │
                        │   ├─► Dark Themes:
                        │   │   ├─► darkBlue
                        │   │   ├─► darkGreen
                        │   │   ├─► darkPurple
                        │   │   └─► darkOrange
                        │   │
                        │   └─► System:
                        │       └─► Follows device theme
                        │
                        └─► Change Theme Flow:
                            │
                            └─► User selects theme
                                ├─► ThemeService.setTheme(newTheme)
                                ├─► Save to SharedPreferences
                                ├─► notifyListeners()
                                └─► MaterialApp rebuilds with new theme
```

### Theme Settings Screen

```
┌──────────────────────────────────────────────────────────────┐
│                  ThemeSettingsScreen                         │
└───────────────────────┬──────────────────────────────────────┘
                        │
                        ├─► Display Theme Options:
                        │   │
                        │   ├─► System Default
                        │   │   └─► Radio: Follow device
                        │   │
                        │   ├─► Light Themes
                        │   │   ├─► Blue Theme (preview card)
                        │   │   ├─► Green Theme (preview card)
                        │   │   ├─► Purple Theme (preview card)
                        │   │   └─► Orange Theme (preview card)
                        │   │
                        │   └─► Dark Themes
                        │       ├─► Dark Blue (preview card)
                        │       ├─► Dark Green (preview card)
                        │       ├─► Dark Purple (preview card)
                        │       └─► Dark Dark Orange (preview card)
                        │
                        └─► Select Theme
                            ├─► User taps theme card
                            ├─► ThemeService.setTheme()
                            ├─► Show checkmark on selected
                            └─► Live preview throughout app
```

### Localization Flow

```
┌──────────────────────────────────────────────────────────────┐
│                  LocalizationService                         │
└───────────────────────┬──────────────────────────────────────┘
                        │
                        ├─► Initialize
                        │   └─► Load saved locale from SharedPreferences
                        │       ├─► Key: 'app_locale'
                        │       └─► Default: 'en' (English)
                        │
                        ├─► Supported Locales:
                        │   ├─► en (English) 🇺🇸
                        │   ├─► uz (O'zbekcha) 🇺🇿
                        │   └─► ru (Русский) 🇷🇺
                        │
                        ├─► Translation Loading:
                        │   └─► Load JSON from assets/translations/
                        │       ├─► en.json
                        │       ├─► uz.json
                        │       └─► ru.json
                        │
                        └─► Change Language Flow:
                            │
                            └─► User selects language
                                ├─► LocalizationService.changeLanguage(code)
                                ├─► Save to SharedPreferences
                                ├─► notifyListeners()
                                ├─► MaterialApp rebuilds with new locale
                                └─► All UI text updates instantly
```

### Language Selector

```
┌──────────────────────────────────────────────────────────────┐
│          LanguageSelector (Bottom Sheet)                     │
└───────────────────────┬──────────────────────────────────────┘
                        │
                        └─► Show Language Options:
                            ├─► English 🇺🇸
                            │   └─► [Radio] English
                            │
                            ├─► O'zbekcha 🇺🇿
                            │   └─► [Radio] O'zbekcha
                            │
                            └─► Русский 🇷🇺
                                └─► [Radio] Русский
                                │
                                └─► User selects language
                                    ├─► LocalizationService.changeLanguage()
                                    ├─► Close bottom sheet
                                    └─► UI updates with new language
```

---

## 9. Update Management Flow

### Update Check Flow

```
┌──────────────────────────────────────────────────────────────┐
│                  UpdateService.getUpdateInfo()               │
└───────────────────────┬──────────────────────────────────────┘
                        │
                        ├─► Check Platform Support
                        │   ├──[Web/Desktop]─► Return null (not supported)
                        │   └──[iOS/Android]─► Continue
                        │
                        ├─► Get Current Version
                        │   └─► VersionService.getVersionInfo()
                        │       ├─► version_name (e.g., "1.2.3")
                        │       ├─► version_code (Android)
                        │       └─► build_number (iOS)
                        │
                        ├─► Get Update Info from Backend
                        │   └─► GET /app/version
                        │       ├─► Query param: locale={locale}
                        │       │
                        │       └─► Response:
                        │           ├─► latest_version
                        │           ├─► minimum_version
                        │           ├─► update_title (localized)
                        │           ├─► update_description (localized)
                        │           ├─► download_url
                        │           └─► release_notes
                        │
                        ├─► Compare Versions
                        │   ├─► current_version < minimum_version
                        │   │   └─► isRequired = true (Force update)
                        │   │
                        │   ├─► current_version < latest_version
                        │   │   └─► hasUpdate = true (Optional update)
                        │   │
                        │   └─► current_version >= latest_version
                        │       └─► hasUpdate = false (Up to date)
                        │
                        └─► Return Update Info Map:
                            ├─► hasUpdate: bool
                            ├─► isRequired: bool
                            ├─► currentVersion: string
                            ├─► latestVersion: string
                            ├─► updateTitle: string (localized)
                            ├─► updateDescription: string (localized)
                            └─► downloadUrl: string
```

### Required Update Flow

```
┌──────────────────────────────────────────────────────────────┐
│            Required Update Detected (BLOCKING)               │
└───────────────────────┬──────────────────────────────────────┘
                        │
                        ├─► Show Required Update Dialog
                        │   ├─► Title: "Update Required"
                        │   ├─► Message: (localized description)
                        │   ├─► Current version info
                        │   ├─► New version info
                        │   │
                        │   └─► Single Action: "Update Now"
                        │       └─► No dismiss/cancel option
                        │
                        ├─► User taps "Update Now"
                        │   │
                        │   ├──[Android]
                        │   │   └─► Launch Play Store
                        │   │       └─► url_launcher: play store URL
                        │   │
                        │   └──[iOS]
                        │       └─► Launch App Store
                        │           └─► url_launcher: app store URL
                        │
                        ├─► App remains in LoadingScreen
                        │   └─► Prevents access until updated
                        │
                        └─► After Update
                            ├─► User updates app
                            ├─► User reopens app
                            └─► Initialization continues normally
```

### Optional Update Flow

```
┌──────────────────────────────────────────────────────────────┐
│           Optional Update Available (NON-BLOCKING)           │
└───────────────────────┬──────────────────────────────────────┘
                        │
                        ├─► Show Optional Update Dialog
                        │   ├─► Title: "Update Available"
                        │   ├─► Message: (localized description)
                        │   ├─► Release notes
                        │   ├─► Version info
                        │   │
                        │   └─► Actions:
                        │       ├─► "Update Now"
                        │       │   └─► Launch store
                        │       │
                        │       └─► "Later" (dismissible)
                        │           └─► Continue to app
                        │
                        ├─► Dialog shown after 3 seconds
                        │   └─► Allows app to load first
                        │
                        └─► User can access app normally
                            └─► Update can be done later
```

### Manual Update Check

```
┌──────────────────────────────────────────────────────────────┐
│          User Triggers Manual Update Check                   │
│             (From Settings or Dev Tools)                     │
└───────────────────────┬──────────────────────────────────────┘
                        │
                        └─► AppRootController.recheckUpdates()
                            ├─► Call UpdateService.getUpdateInfo()
                            │
                            ├──[Update Available]
                            │   └─► Show appropriate dialog
                            │       (required or optional)
                            │
                            └──[No Update]
                                └─► Show "App is up to date" message
```

---

## 10. Complete User State Diagram

### Comprehensive User Journey

```
┌──────────────────────────────────────────────────────────────┐
│                     APP LAUNCH                               │
└───────────────────────┬──────────────────────────────────────┘
                        │
                        ├─► [LOADING STATE]
                        │   │
                        │   └─► LoadingScreen (minimum 5s)
                        │       ├─► Initialize services
                        │       ├─► Check for updates
                        │       ├─► Verify authentication
                        │       └─► Setup Firebase
                        │
                        ├──[Required Update]
                        │   └─► [BLOCKED STATE]
                        │       └─► Required Update Dialog
                        │           └─► Must update to continue
                        │
                        ├──[No Token / Invalid Token]
                        │   │
                        │   └─► [UNAUTHENTICATED STATE]
                        │       │
                        │       ├─► LoginScreen
                        │       │   ├─► Enter phone + password
                        │       │   │
                        │       │   ├──[Direct Login Success]
                        │       │   │   └─► Go to AUTHENTICATED STATE
                        │       │   │
                        │       │   └──[SMS Required]
                        │       │       └─► SmsVerificationScreen
                        │       │           ├─► Enter SMS code
                        │       │           │
                        │       │           ├──[Valid Code]
                        │       │           │   └─► Go to AUTHENTICATED STATE
                        │       │           │
                        │       │           └──[Invalid Code]
                        │       │               └─► Show error, retry
                        │       │
                        │       └─► Optional: Register/Forgot Password
                        │
                        └──[Valid Token]
                            │
                            └─► [AUTHENTICATED STATE]
                                │
                                └─► MainScreen with Bottom Navigation
                                    │
                                    ├─► [HOME TAB]
                                    │   ├─► Welcome card
                                    │   ├─► Dashboard stats
                                    │   ├─► Quick actions
                                    │   └─► Recent items
                                    │
                                    ├─► [TASKS TAB]
                                    │   ├─► Task list
                                    │   ├─► Filter & search
                                    │   ├─► Create task (FAB)
                                    │   ├─► View task details
                                    │   ├─► Edit task
                                    │   ├─► Delete task
                                    │   └─► Manage workers
                                    │
                                    ├─► [PROJECTS TAB]
                                    │   ├─► Project list
                                    │   ├─► Filter by status
                                    │   ├─► Create project (FAB)
                                    │   ├─► View project details
                                    │   ├─► Edit project
                                    │   ├─► Delete project
                                    │   └─► View project tasks
                                    │
                                    └─► [PROFILE TAB]
                                        ├─► User info display
                                        ├─► Statistics
                                        ├─► Edit profile
                                        ├─► Change password
                                        ├─► Settings access
                                        └─► Logout
                                            └─► Go to UNAUTHENTICATED STATE
```

### Cross-Cutting Features (Available in Multiple States)

```
┌──────────────────────────────────────────────────────────────┐
│              ALWAYS AVAILABLE FEATURES                       │
└───────────────────────┬──────────────────────────────────────┘
                        │
                        ├─► Navigation Drawer (when authenticated)
                        │   ├─► Quick navigation
                        │   ├─► Theme settings
                        │   ├─► Language settings
                        │   ├─► Settings screen
                        │   ├─► Developer tools (debug only)
                        │   └─► Logout
                        │
                        ├─► Notifications (when authenticated)
                        │   ├─► Foreground notifications
                        │   ├─► Background notifications
                        │   ├─► Terminated state notifications
                        │   └─► Navigation from notifications
                        │
                        ├─► Theme System
                        │   ├─► Switch between light themes
                        │   ├─► Switch between dark themes
                        │   ├─► System theme (auto)
                        │   └─► Live theme updates
                        │
                        ├─► Localization
                        │   ├─► Switch language (EN/UZ/RU)
                        │   ├─► Instant UI updates
                        │   └─► Localized content
                        │
                        ├─► Error Handling
                        │   ├─► API errors
                        │   ├─► Network errors
                        │   ├─► Validation errors
                        │   └─► User-friendly messages
                        │
                        └─► Auto-Logout on 401
                            └─► Any API returns 401
                                └─► Force navigate to LoginScreen
```

### App State Transitions Summary

```
┌───────────────────────────────────────────────────────────────┐
│                  STATE TRANSITION MAP                         │
└────────────────────────┬──────────────────────────────────────┘
                         │
                         v
              ┌──────────────────┐
              │     LOADING      │◄────────────────┐
              └────────┬─────────┘                 │
                       │                           │
         ┌─────────────┼─────────────┐            │
         │             │             │            │
         v             v             v            │
    ┌────────┐   ┌──────────┐  ┌────────┐       │
    │BLOCKED │   │UNAUTHENT │  │AUTHENT │       │
    │(Update)│   │  ICATED  │  │ ICATED │       │
    └────────┘   └─────┬────┘  └────┬───┘       │
         │             │             │           │
         │             │    ┌────────┘           │
         │             │    │                    │
         │             v    v                    │
         │        ┌─────────────┐                │
         │        │ LOGIN/SMS   │                │
         │        └──────┬──────┘                │
         │               │                       │
         │               └──────►[Success]───────┤
         │                                       │
         └──►[Update App]───────────────────────┘
                [Reopen App]

Transitions:
• LOADING → AUTHENTICATED: Valid token found
• LOADING → UNAUTHENTICATED: No/invalid token
• LOADING → BLOCKED: Required update detected
• UNAUTHENTICATED → AUTHENTICATED: Successful login/SMS
• AUTHENTICATED → UNAUTHENTICATED: Logout or 401 error
• AUTHENTICATED → LOADING: Restart initialization (rare)
• BLOCKED → LOADING: App updated and reopened
```

---

## 📊 Feature Matrix

### Available Features by User State

| Feature | Loading | Blocked | Unauthenticated | Authenticated |
|---------|---------|---------|-----------------|---------------|
| View Loading Screen | ✅ | ❌ | ❌ | ❌ |
| Update Dialog | ❌ | ✅ | ❌ | ❌ |
| Login | ❌ | ❌ | ✅ | ❌ |
| SMS Verification | ❌ | ❌ | ✅ | ❌ |
| Main Navigation | ❌ | ❌ | ❌ | ✅ |
| Home Dashboard | ❌ | ❌ | ❌ | ✅ |
| Tasks Management | ❌ | ❌ | ❌ | ✅ |
| Projects Management | ❌ | ❌ | ❌ | ✅ |
| Profile Management | ❌ | ❌ | ❌ | ✅ |
| Settings | ❌ | ❌ | ❌ | ✅ |
| Notifications | ❌ | ❌ | ❌ | ✅ |
| Theme Switching | ❌ | ❌ | ✅ | ✅ |
| Language Switching | ❌ | ❌ | ✅ | ✅ |
| Firebase Integration | ✅ | ❌ | ✅ | ✅ |
| Crashlytics | ✅ | ✅ | ✅ | ✅ |
| Logger | ✅ | ✅ | ✅ | ✅ |

---

## 🔄 Data Flow Architecture

### Provider Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                        UI LAYER                              │
│   ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│   │  Screens │  │  Widgets │  │  Dialogs │  │  Sheets  │   │
│   └─────┬────┘  └─────┬────┘  └─────┬────┘  └─────┬────┘   │
│         │             │             │             │         │
│         └─────────────┴─────────────┴─────────────┘         │
└────────────────────────┬────────────────────────────────────┘
                         │ Consumer / Provider.of()
                         │
┌────────────────────────▼────────────────────────────────────┐
│                    PROVIDER LAYER                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ AuthProvider │  │TasksProvider │  │ProjectsProvi │     │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘     │
│         │                 │                 │              │
│  ┌──────▼───────┐  ┌──────▼───────┐  ┌──────▼───────┐     │
│  │DashboardProv │  │FirebaseProvi │  │ ThemeService │     │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘     │
│         │                 │                 │              │
│         └─────────────────┴─────────────────┘              │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│                    SERVICE LAYER                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ AuthService  │  │ ApiClient    │  │FirebaseSvc   │     │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘     │
│         │                 │                 │              │
│  ┌──────▼───────┐  ┌──────▼───────┐  ┌──────▼───────┐     │
│  │UpdateService │  │NotificationS │  │VersionServic │     │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘     │
│         │                 │                 │              │
│         └─────────────────┴─────────────────┘              │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│                     DATA LAYER                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   Models     │  │  DataSources │  │ Repositories │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                         │
                         v
              ┌──────────────────────┐
              │  BACKEND API/FIREBASE │
              └──────────────────────┘
```

---

## 🎯 Key Integration Points

### 1. Authentication Integration
- **Trigger**: User login, token verification, auto-logout
- **Components**: AuthProvider, AuthService, AppManager, ApiClient
- **Flow**: Login → Store Token → Register Firebase Token → Navigate to Main

### 2. Firebase Integration
- **Trigger**: App initialization, user login
- **Components**: FirebaseService, FirebaseProvider, NotificationService
- **Flow**: Initialize → Get Token → Register with Backend → Subscribe to Topics

### 3. Update Management Integration
- **Trigger**: App launch, manual check, notification
- **Components**: UpdateService, VersionService, AppRoot
- **Flow**: Check Version → Compare → Show Dialog → Navigate to Store

### 4. State Management Integration
- **Trigger**: User actions, API responses, system events
- **Components**: All Providers, ChangeNotifier pattern
- **Flow**: User Action → Provider Method → API Call → Update State → Notify Listeners → UI Rebuild

### 5. Navigation Integration
- **Trigger**: User taps, notifications, system events
- **Components**: NavigationService, navigatorKey, Routes
- **Flow**: Trigger → Validate State → Navigate → Update Stack

---

## 📝 Notes

### Design Principles
1. **Clean Architecture**: Clear separation between UI, Business Logic, and Data layers
2. **Provider Pattern**: Reactive state management with ChangeNotifier
3. **Single Responsibility**: Each component has a focused purpose
4. **Error Handling**: Comprehensive error handling at every layer
5. **Logging**: Detailed logging for debugging and monitoring

### Security Considerations
1. **Token Management**: Secure storage of auth tokens
2. **Auto-Logout**: Automatic logout on 401 responses
3. **SSL/TLS**: All API calls over HTTPS
4. **Input Validation**: Client and server-side validation
5. **Crashlytics**: Error tracking without exposing sensitive data

### Performance Optimizations
1. **Lazy Loading**: Pagination for large lists
2. **Caching**: Image and data caching
3. **Minimal Rebuilds**: Efficient state management
4. **Background Processing**: Firebase messaging in background
5. **Asset Optimization**: Compressed images and assets

---

**Document Version**: 1.0  
**Last Updated**: 2025-10-12  
**Author**: Jamshidbek  
**Repository**: task_manager_mobile
