# NeuroLab

A personal cognitive science laboratory app built with Flutter. Track your cognitive performance, discover how lifestyle factors affect your brain, and run self-experiments to optimize your mental performance.

## Features

### Cognitive Tests
- **Reaction Time (PVT)** - Measures alertness and processing speed
- **N-Back** - Tests working memory capacity
- **Stroop Test** - Evaluates cognitive control and inhibition
- **Flanker Test** - Measures selective attention and response inhibition
- **Trail Making** - Assesses executive function and mental flexibility

### Lifestyle Tracking
- Sleep duration and quality
- Caffeine intake
- Exercise minutes and intensity
- Stress, mood, and energy levels
- Meditation tracking

### Insights Engine
- Correlation analysis between lifestyle factors and cognitive performance
- Statistical confidence scoring
- Personalized insights like "Your reaction time is 18% faster on days you sleep 7+ hours"

### Self-Experimentation
- Design custom experiments with baseline and intervention phases
- Pre-built templates (meditation, caffeine, sleep, exercise)
- Statistical analysis of results with effect size calculations

### Brain Visualization
- Interactive brain model showing activated regions after each test
- Educational information about brain function
- Animated highlighting of relevant brain areas

### Data Export
- Export all data as JSON or CSV
- Share via native share sheet
- Full data portability

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.10.0 or higher)
- Xcode (for iOS development)
- Android Studio (for Android development)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/raghavj/neurolab.git
   cd neurolab
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**

   For iOS Simulator:
   ```bash
   open -a Simulator
   flutter run
   ```

   For Android Emulator:
   ```bash
   flutter run
   ```

   For a specific device:
   ```bash
   flutter devices  # List available devices
   flutter run -d <device_id>
   ```

### Building for Release

**iOS:**
```bash
flutter build ios
```

**Android:**
```bash
flutter build apk
# or for app bundle
flutter build appbundle
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   ├── models.dart          # Barrel file
│   ├── user_profile.dart    # User data model
│   ├── test_result.dart     # Test results & cognitive test types
│   ├── lifestyle_log.dart   # Daily lifestyle logging
│   └── experiment.dart      # Self-experimentation models
├── providers/
│   └── app_state.dart       # State management (Provider)
├── services/
│   ├── database_service.dart # SQLite persistence
│   ├── insights_service.dart # Correlation analysis
│   └── export_service.dart   # Data export (CSV/JSON)
├── screens/
│   ├── onboarding/          # Onboarding flow
│   ├── dashboard/           # Main dashboard tabs
│   ├── tests/               # Cognitive test screens
│   ├── experiments/         # Self-experimentation
│   └── settings/            # Settings screens
├── widgets/
│   └── brain_visualization.dart # Brain region visualization
└── utils/
    └── theme.dart           # App theming
```

## Dependencies

- `provider` - State management
- `sqflite` - Local SQLite database
- `shared_preferences` - Key-value storage
- `fl_chart` - Charts and graphs
- `path_provider` - File system access
- `share_plus` - Native sharing
- `uuid` - Unique ID generation
- `intl` - Date formatting

## How It Works

### Cognitive Tests
Each test is based on validated cognitive science research:
- Tests measure different cognitive domains
- Results include primary scores, accuracy, and detailed metrics
- Brain regions activated during each test are visualized

### Insights Engine
The app analyzes correlations between your lifestyle factors and cognitive performance:
- Uses statistical methods to find significant patterns
- Calculates effect sizes (Cohen's d) for confidence scoring
- Generates personalized recommendations

### Self-Experiments
Run n-of-1 experiments on yourself:
1. Choose a hypothesis (e.g., "Meditation improves my focus")
2. Collect baseline data for several days
3. Introduce an intervention
4. Compare baseline vs intervention with statistical analysis

## Privacy

- All data is stored locally on your device
- No data is sent to external servers
- Export your data anytime in standard formats

## License

MIT License
