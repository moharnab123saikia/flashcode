# Technical Context - LeetCode Flashcards App

## Technology Stack

### Frontend Framework
- **Flutter 3.x**: Cross-platform mobile development
- **Dart**: Programming language for Flutter
- **Provider**: State management pattern
- **Material Design**: UI component library

### Backend & Database
- **Supabase**: Backend-as-a-Service platform
  - PostgreSQL database with real-time subscriptions
  - Authentication and user management
  - Row Level Security (RLS)
  - API auto-generation from database schema
- **SQLite**: Local offline storage
  - Device-local database for offline-first functionality
  - Sync with Supabase when online

### Development Tools & Setup
- **VS Code**: Primary IDE with Flutter extensions
- **Android Studio**: Android emulator and debugging
- **Xcode**: iOS simulation and deployment
- **Git**: Version control with MCP server integration
- **GitHub**: Repository hosting (https://github.com/moharnab123saikia/flashcode)
- **Git MCP Server**: Automated workflow tools for git operations
- **MCP Installation**: Located at `/Users/moharnab/.local/bin/mcp-server-git`

## Architecture Patterns

### Data Architecture
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Flutter App   │    │   Local SQLite   │    │    Supabase     │
│                 │◄──►│                  │◄──►│   PostgreSQL    │
│ Provider State  │    │ Offline Storage  │    │  Cloud Database │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

### Offline-First Strategy
1. **Write Local**: All user actions saved to SQLite immediately
2. **Background Sync**: Sync to Supabase when connectivity available
3. **Conflict Resolution**: Last-write-wins for user data
4. **Read Local**: Always read from local database for speed

### State Management Pattern
- **Provider**: Centralized state management
- **Repository Pattern**: Data layer abstraction
- **Service Layer**: Business logic separation

## Database Schema

### Core Tables

#### flashcards
```sql
CREATE TABLE flashcards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  leetcode_number TEXT,
  question TEXT NOT NULL,
  hint TEXT,
  solutions JSONB, -- Multi-language solutions
  data_structure_category TEXT NOT NULL,
  algorithm_pattern TEXT,
  difficulty TEXT NOT NULL, -- Easy/Medium/Hard
  tags TEXT[] DEFAULT '{}',
  companies TEXT[] DEFAULT '{}',
  grind75_order INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### user_flashcard_progress
```sql
CREATE TABLE user_flashcard_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  flashcard_id UUID REFERENCES flashcards(id),
  personal_difficulty INTEGER DEFAULT 2, -- 1-4 scale
  ease_factor DECIMAL DEFAULT 2.5,
  interval_days INTEGER DEFAULT 1,
  next_review_date DATE,
  review_count INTEGER DEFAULT 0,
  last_reviewed_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, flashcard_id)
);
```

#### study_sessions
```sql
CREATE TABLE study_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  flashcard_id UUID REFERENCES flashcards(id),
  difficulty_rating INTEGER NOT NULL, -- 1-4 user rating
  time_spent_seconds INTEGER,
  session_date DATE DEFAULT CURRENT_DATE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## Key Dependencies

### Flutter Packages
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  provider: ^6.1.1
  
  # Database & Storage
  supabase_flutter: ^2.3.4
  sqflite: ^2.3.0
  path: ^1.8.3
  
  # JSON Serialization
  json_annotation: ^4.8.1
  
  # UI Components
  cupertino_icons: ^1.0.6

dev_dependencies:
  flutter_test:
    sdk: flutter
  
  # Code Generation
  build_runner: ^2.4.7
  json_serializable: ^6.7.1
  
  # Linting
  flutter_lints: ^3.0.1
```

### Configuration Files

#### pubspec.yaml Key Sections
- Platform support: iOS, Android, Web, macOS
- Asset management: fonts, images, data files
- Dependency version pinning for stability

#### Environment Configuration
- Development: Local Supabase instance
- Production: Hosted Supabase project
- API keys managed through environment variables

## Development Constraints

### Platform Limitations

#### iOS Specific
- Requires Apple Developer account for device testing
- App Store review process for distribution
- iOS-specific privacy requirements
- Simulator limitations for certain device features

#### Android Specific
- Multiple device form factors and screen sizes
- Android version compatibility (API 21+)
- Google Play Store policies
- Permission model differences

#### Web Specific
- SQLite limitations (using SQL.js or Hive alternative)
- CORS restrictions for Supabase connections
- Performance considerations for large datasets

### Supabase Constraints

#### Free Tier Limitations
- 2 projects maximum
- 500MB database storage
- 50MB file storage
- 2GB bandwidth per month
- 50,000 monthly active users

#### Technical Constraints
- Row Level Security must be configured properly
- Real-time subscriptions limited by plan
- API rate limiting in place
- PostgreSQL function limitations

## Security Considerations

### Data Protection
- **Row Level Security**: User data isolation in Supabase
- **Local Encryption**: SQLite database encryption for sensitive data
- **API Security**: Supabase anonymous key with RLS enforcement
- **Authentication**: Supabase Auth integration

### Privacy Requirements
- **Data Minimization**: Only collect necessary user data
- **Local Storage**: Keep study data local when possible
- **Anonymization**: No personally identifiable information in analytics
- **User Control**: Easy data export and deletion

## Performance Optimizations

### Database Performance
- **Indexes**: On frequently queried columns (user_id, flashcard_id, next_review_date)
- **Query Optimization**: Efficient joins and filtering
- **Pagination**: Large result sets handled with pagination
- **Caching**: Local SQLite as primary cache layer

### Mobile Performance
- **Lazy Loading**: Load flashcard content on demand
- **Image Optimization**: Compress and cache images locally
- **Memory Management**: Dispose of controllers and subscriptions
- **Battery Optimization**: Minimize background processing

### Network Optimization
- **Offline First**: Minimize network dependency
- **Batch Sync**: Group multiple changes into single requests
- **Compression**: Use gzip for API responses
- **Delta Sync**: Only sync changed data

## Testing Strategy

### Unit Testing
- Model serialization/deserialization
- Spaced repetition algorithm logic
- Database query functions
- Business logic validation

### Integration Testing
- Supabase connection and authentication
- Local SQLite operations
- Sync mechanisms between local and cloud
- Provider state management

### Widget Testing
- UI component behavior
- Navigation flow testing
- Form validation
- Responsive design

### End-to-End Testing
- Complete user study session flow
- Offline/online mode transitions
- Cross-platform consistency
- Performance under load

## Deployment Pipeline

### Development Workflow
1. **Local Development**: Flutter hot reload for rapid iteration
2. **Testing**: Automated test suite on every commit
3. **Code Review**: GitHub pull request workflow
4. **Staging**: Deploy to test devices for manual QA
5. **Production**: App store deployment process

### CI/CD Considerations
- **Automated Testing**: Run test suite on multiple Flutter versions
- **Build Artifacts**: Generate APK/IPA files for distribution
- **Code Quality**: Linting and static analysis
- **Dependency Security**: Automated security vulnerability scanning

## Known Technical Debt

### Current Limitations
- **Authentication**: Not yet implemented, using anonymous access
- **Error Handling**: Basic error handling needs enhancement
- **Logging**: Limited logging and analytics implementation
- **Performance Monitoring**: No crash reporting or performance metrics

### Future Technical Improvements
- **Code Generation**: More extensive use of build_runner for boilerplate
- **Architecture**: Consider Clean Architecture or BLoC pattern
- **Testing**: Increase test coverage and add visual regression tests
- **Documentation**: API documentation and architectural decision records
