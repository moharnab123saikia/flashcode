# LeetCode Flashcards App - Project Brief

## Project Overview

A cross-platform mobile application designed to help developers master LeetCode problems through spaced repetition and structured learning. The app focuses on the Grind 75 problem set while supporting efficient study patterns.

## Core Requirements

### Primary Goals
- **Efficient Learning**: Implement spaced repetition algorithm for optimal retention
- **Complete Problem Set**: Access to all 169 Grind75 problems without week-based restrictions
- **Multi-Language Support**: Solutions in Python, Java, JavaScript, and more
- **Cross-Platform**: Support iOS, Android, and Web platforms
- **Offline-First**: Local SQLite database with cloud sync capabilities

### Target Audience
- Software engineers preparing for technical interviews
- Computer science students learning algorithms
- Developers wanting to improve problem-solving skills

## Technical Foundation

### Architecture
- **Frontend**: Flutter/Dart with Provider state management
- **Backend**: Supabase (PostgreSQL database, Auth, Storage)
- **Local Storage**: SQLite with spaced repetition tracking
- **Cloud Sync**: Supabase realtime sync

### Core Features
1. **Flashcard System**: Question, hint, multiple language solutions
2. **Spaced Repetition**: SuperMemo 2 algorithm implementation
3. **Progress Tracking**: Personal difficulty ratings, review history
4. **Study Modes**: Random practice, difficulty-based, category-based
5. **Gamification**: Streaks, achievements, progress visualization

## Project Scope

### MVP Features (Phase 1) ✅
- Core data models and database schema
- Spaced repetition algorithm
- Local SQLite storage
- Basic UI screens (home, study, progress)
- Pre-populated Grind 75 problem set
- Supabase integration and cloud sync

### Enhanced Features (Phase 2)
- User authentication and profiles
- Social features (leaderboards, challenges)
- Custom problem sets
- Advanced analytics
- Mobile notifications

### Advanced Features (Phase 3)
- AI-powered hints
- Interview simulation mode
- Video solution walkthroughs
- Community features

## Success Metrics

- **User Engagement**: Daily/Weekly active users
- **Learning Efficiency**: Problems mastered per week
- **Retention**: 30-day user retention rate
- **Completion Rate**: Grind 75 completion percentage

## Key Constraints

- Mobile-first design optimized for study sessions
- Offline-first architecture for unreliable connections
- Free tier limitations of Supabase (generous for our use case)
- Cross-platform compatibility requirements

## Current Status

The project is in active development with core infrastructure complete:
- ✅ Flutter app structure and navigation
- ✅ Supabase database with 34+ flashcards
- ✅ Local SQLite integration
- ✅ Spaced repetition algorithm
- ✅ Basic UI components
- 🔄 Full Grind 75 dataset upload
- 🔄 Enhanced study interface
- 📋 User authentication system
