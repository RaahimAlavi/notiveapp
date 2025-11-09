<h1 align="center">Notive</h1>
<p align="center">
<strong>Your daily task manager.</strong>
</p>

<p align="center">
A clean, modern, and offline-first task management application built with Flutter.
</p>

<p align="center">
<img src="https://www.google.com/search?q=https://img.shields.io/badge/Platform-Android_%257C_iOS-blue.svg" alt="Platform">
<img src="https://www.google.com/search?q=https://img.shields.io/badge/Built%2520with-Flutter-02569B%3Flogo%3Dflutter" alt="Built with Flutter">
<img src="https://www.google.com/search?q=https://img.shields.io/badge/License-MIT-green.svg" alt="License">
</p>

📱 About The Project

Notive is a feature-rich to-do list application designed for simplicity and power. It is built to be fast, responsive, and completely offline-first using a local Hive database. It features Material 3 design, dynamic theming (light/dark mode), and user-selectable color palettes.

From custom categories and task priorities to local notifications and drag-and-drop reordering, Notive is a complete solution for managing your daily tasks.

✨ Key Features

Full Task CRUD: Create, read, edit, and delete tasks with ease.

Offline-First: All tasks are stored locally in a high-performance Hive database.

Category Management: Create and delete custom categories to organize your tasks.

Advanced Filtering: Filter tasks by category or search by title.

Multiple Sort Options: Sort by creation date, due date, priority, title, or your own custom drag-and-drop order.

Due Date Reminders: Set due dates and receive local notifications so you never miss a deadline.

Task Priorities: Assign Low, Medium, or High priority to your tasks.

Material 3 Theming:

Beautiful, modern UI.

Light & Dark mode support.

Dynamic Color: Uses your phone's wallpaper for a custom theme (on supported Android versions).

Color Seed Selector: Manually pick your favorite theme color.

Backup & Restore: Easily export all your tasks to a JSON file and import them back at any time.

📸 Screenshots

Splash Screen

<p align="center">
<img src="https://github.com/user-attachments/assets/b0220bda-676c-4e83-8ecc-a56a52a78679" alt="Splash Screen Light" width="300">
<img src="https://github.com/user-attachments/assets/417155c9-ae74-4854-a144-bdbb72b43cbb" alt="Splash Screen Dark" width="300">
</p>

Main Task List

<p align="center">
<img src="https://github.com/user-attachments/assets/e8f774aa-04ad-41a5-9a12-ec0c5d5d2123" alt="Main Task List Light" width="300">
<img src="https://github.com/user-attachments/assets/bafbb376-bda8-426e-844d-e8983a3b2778" alt="Main Task List Dark" width="300">
</p>

Add Task

<p align="center">
<img src="https://github.com/user-attachments/assets/aa31cfce-890e-4b66-ad9c-f56668f41286" alt="Add Task Light" width="300">
<img src="https://github.com/user-attachments/assets/b8640725-fe9d-43e3-bfea-175663042feb" alt="Add Task Dark" width="300">
</p>

Settings

<p align="center">
<img src="https://github.com/user-attachments/assets/f1ebfc4a-c43f-4558-ac03-1f0ab0d9df0d" alt="Settings Light" width="300">
<img src="https://github.com/user-attachments/assets/fb2ee878-67f2-420a-a738-2d2da04d9115" alt="Settings Dark" width="300">
</p>

Completed Tasks

<p align="center">
<img src="https://github.com/user-attachments/assets/8df05d50-5af0-46d7-bb47-81add3e172b1" alt="Completed Tasks Light" width="300">
<img src="https://github.com/user-attachments/assets/d47ff072-b39e-4cf9-8051-f5c24ba4ce20" alt="Completed Tasks Dark" width="300">
</p>

Category Management

<p align="center">
<img src="https://github.com/user-attachments/assets/4a618677-2d8b-4a89-8b96-5a905a0d7a85" alt="Category Management Light" width="300">
<img src="https://github.com/user-attachments/assets/8a814f89-f9c7-432b-9825-01af5ede6459" alt="Category Management Dark" width="300">
</p>

Sorting

<p align="center">
<img src="https://github.com/user-attachments/assets/131e641e-a6c9-444f-85a3-dfef4564cb22" alt="Sorting Options" width="300">
</p>

🛠 Tech Stack & Architecture

This project uses a clean architecture, separating UI, business logic, and data.

State Management: provider (for ThemeProvider) & StatefulWidget (for local page state)

Database: hive_flutter for fast, local, offline-first storage.

Notifications: flutter_local_notifications

Theming: dynamic_color (Material 3) & shared_preferences (to save user's theme choice)

Backup/Restore: file_picker & permission_handler

Fonts: google_fonts (Inter)

📁 Project Structure
<p align="center">
<img src="https://github.com/user-attachments/assets/426522de-6b9e-428b-b890-2f2dfebb8daf" alt="Project Structure" width="300"/>
</p>



🚀 Getting Started

To get a local copy up and running, follow these simple steps.

Prerequisites

You must have the Flutter SDK installed on your machine.

Installation

Clone the repository:

git clone [https://github.com/RaahimAlavi/notiveapp.git](https://github.com/RaahimAlavi/notiveapp.git)


Navigate to the project directory:

cd notiveapp


Install dependencies:

flutter pub get


Run the app:

flutter run


📄 License

Distributed under the MIT License. See LICENSE for more information.

<p align="center">
Built with ❤️ and Flutter by [Raahim Alavi]
</p>
